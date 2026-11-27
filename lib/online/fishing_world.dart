import 'visual_state.dart';
import '../fishing/fishing_environment.dart';
import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_session.dart';
import 'fishing_peer.dart';

/// One live visit. Firebase UIDs authorize writes; installation IDs never do.
class FishingWorld extends ChangeNotifier {
  FishingWorld(
      {required this.capture,
      required this.onVisitChanged,
      required this.preferences});
  static const mapVersion = 1;
  static const maxPlayers = 8;
  final FishingPeerSnapshot Function(int stamp) capture;
  final void Function(bool visiting) onVisitChanged;
  final SharedPreferences preferences;
  final Map<String, FishingPeer> peers = {};
  String? homeCode, worldId, visitingCode, error;
  bool connected = false, busy = false;
  bool get online => connected && _presence != null;
  bool get visiting => worldId != null && worldId != _uid;
  String? get currentCode => visiting ? visitingCode : homeCode;
  String? _uid;
  FirebaseDatabase? _db;
  DatabaseReference? _presence, _host;
  StreamSubscription<DatabaseEvent>? _environmentSub;
  FishingEnvironment? _visitorEnvironment;
  Map<String, dynamic> _homeDisplay = {};
  FishingEnvironment get environment => visiting && _visitorEnvironment != null
      ? _visitorEnvironment!
      : FishingEnvironment.local(preferences).toServer(connected ? _offset : 0);
  DateTime environmentTime(DateTime now) => DateTime.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch + (connected ? _offset : 0));
  StreamSubscription<DatabaseEvent>? _connectionSub,
      _offsetSub,
      _playersSub,
      _hostSub;
  Timer? _timer;
  Future<void>? _starting;
  int _epoch = 0, _offset = 0;
  bool _disposed = false,
      _writing = false,
      _switching = false,
      _suspended = false;
  Future<void>? _pausing;
  bool _hostMissing = false;
  Future<void>? _purging;
  int _lastHostSeen = 0;
  int get serverNow => DateTime.now().millisecondsSinceEpoch + _offset;

  static String newCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(7, (_) => letters[rng.nextInt(letters.length)]).join();
  }

  static String normalizeCode(String code) => code.trim().toUpperCase();
  static bool validCode(String code) =>
      RegExp(r'^[A-HJ-NP-Z2-9]{7}$').hasMatch(code);

  Future<void>? _preparing;

  /// Resolve the owner's code in the lobby, without announcing a player/host.
  Future<void> prepare() => _preparing ??= _prepare().whenComplete(() {
        _preparing = null;
      });

  Future<void> _prepare() async {
    if (_disposed || online || _starting != null) return;
    busy = true;
    error = null;
    _notify();
    try {
      if (!await FirebaseSession.instance.connect()) {
        if (!_disposed) {
          error = 'Chơi offline vẫn được. Có mạng để lấy mã và ghé bạn.';
        }
        return;
      }
      if (_disposed) return;
      _uid = FirebaseSession.instance.uid;
      _db = FirebaseSession.instance.database;
      homeCode = preferences.getString('fishing_world_code_$_uid');
      final offset = await _db!
          .ref('.info/serverTimeOffset')
          .get()
          .timeout(const Duration(seconds: 10));
      if (offset.value is num) _offset = (offset.value as num).toInt();
      if (!_disposed) await _ensureHome();
    } catch (e) {
      if (!_disposed) _fail(e);
    } finally {
      if (!_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  Future<bool> waitForOnline() async {
    await _preparing;
    if (_disposed) return false;
    await start();
    if (online && !busy) return true;
    if (_disposed || (!busy && error != null)) return false;
    final ready = Completer<bool>();
    void check() {
      if (ready.isCompleted) return;
      if (online && !busy) {
        ready.complete(true);
      } else if (_disposed || (!busy && error != null)) {
        ready.complete(false);
      }
    }

    addListener(check);
    check();
    try {
      return await ready.future
          .timeout(const Duration(seconds: 15), onTimeout: () => false);
    } finally {
      removeListener(check);
    }
  }

  /// A failed lobby visit must not leave a ghost host/player behind.
  Future<void> leaveGameplay() async {
    if (_disposed) return;
    _suspended = true;
    ++_epoch;
    _timer?.cancel();
    _timer = null;
    await _connectionSub?.cancel();
    await _offsetSub?.cancel();
    _connectionSub = null;
    _offsetSub = null;
    await _removePresence();
    if (_disposed) return;
    _disconnected();
    _suspended = false;
  }

  Future<void> start() => _starting ??= _start().whenComplete(() {
        _starting = null;
      });
  Future<void> _start() async {
    final epoch = _epoch;
    await _preparing;
    if (_disposed || epoch != _epoch || _connectionSub != null) return;
    busy = true;
    error = null;
    _notify();
    if (!await FirebaseSession.instance.connect()) {
      if (_disposed) return;
      busy = false;
      error = 'Đang chơi offline. Có mạng thì bấm Kết nối lại.';
      _notify();
      return;
    }
    if (_disposed || epoch != _epoch) return;
    _uid = FirebaseSession.instance.uid;
    _db = FirebaseSession.instance.database;
    homeCode = preferences.getString('fishing_world_code_$_uid');
    _offsetSub = _db!.ref('.info/serverTimeOffset').onValue.listen((e) {
      if (e.snapshot.value is num) {
        _offset = (e.snapshot.value as num).toInt();
        if (online && !visiting) unawaited(publishEnvironment());
      }
    }, onError: (Object e) {
      debugPrint('FishingWorld clock: $e');
    });
    _connectionSub = _db!.ref('.info/connected').onValue.listen((e) {
      if (_disposed || _suspended) return;
      if (e.snapshot.value == true) {
        connected = true;
        unawaited(_reconnect());
      } else {
        _disconnected();
      }
    }, onError: (Object e) {
      if (!_disposed) {
        _fail(e);
        _disconnected();
      }
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 125), (_) {
      final before = peers.length;
      peers.removeWhere((_, p) => serverNow - p.target.stamp > 15000);
      if (peers.length != before) _notify();
      if (visiting && !busy && serverNow - _lastHostSeen > 15000) {
        unawaited(goHome());
      }
      unawaited(_publish());
    });
  }

  Future<void> _ensureHome() async {
    final ref = _db!.ref('worlds/$_uid');
    final existing = await ref.get().timeout(const Duration(seconds: 10));
    if (existing.exists) {
      final code = existing.child('code').value;
      if (code is! String || !validCode(code)) {
        throw StateError('Invalid world code');
      }
      _homeDisplay = VisualState.decode(existing.child('display').value) ?? {};
      await ref.update({
        'mapVersion': mapVersion,
        'display': _environmentDisplay()
      }).timeout(const Duration(seconds: 10));
      homeCode = code;
      return;
    }
    final cached = preferences.getString('fishing_world_code_$_uid');
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = attempt == 0 && cached != null && validCode(cached)
          ? cached
          : newCode();
      final reserved =
          await _db!.ref('worldCodes/$code').runTransaction((value) {
        if (value == null || value == _uid) return Transaction.success(_uid);
        return Transaction.abort();
      }).timeout(const Duration(seconds: 10));
      if (!reserved.committed) continue;
      // Remember a reservation before creating metadata, so retries reuse it.
      await preferences.setString('fishing_world_code_$_uid', code);
      await ref.update({
        'code': code,
        'mapVersion': mapVersion,
        'createdAt': ServerValue.timestamp,
        'display': _environmentDisplay()
      }).timeout(const Duration(seconds: 10));
      homeCode = code;
      return;
    }
    throw StateError('Could not allocate a world code');
  }

  Future<void> _reconnect() async {
    if (_switching || _disposed || _suspended || !connected) return;
    _switching = true;
    busy = true;
    error = null;
    _notify();
    final epoch = ++_epoch;
    try {
      await _purging;
      if (!_valid(epoch)) return;
      await _ensureHome();
      if (!_valid(epoch)) return;
      await _attach(_uid!, epoch);
    } catch (e) {
      if (_valid(epoch)) {
        await _removePresence();
        _fail(e);
      }
    } finally {
      _switching = false;
      if (!_disposed) {
        busy = false;
        _notify();
        if (connected && !_suspended && epoch != _epoch && _presence == null) {
          unawaited(_reconnect());
        }
      }
    }
  }

  bool _valid(int epoch) =>
      !_disposed && !_suspended && connected && epoch == _epoch;

  Future<void> _attach(String id, int epoch) async {
    final presence = _db!.ref('sessions/$id/players/$_uid').push();
    DatabaseReference? host;
    try {
      // Register disconnect removal BEFORE publishing any live state.
      await presence
          .onDisconnect()
          .remove()
          .timeout(const Duration(seconds: 10));
      if (id == _uid) {
        host = _db!.ref('worlds/$id/hosts/${presence.key}');
        await host.onDisconnect().remove().timeout(const Duration(seconds: 10));
        await host.set(true).timeout(const Duration(seconds: 10));
      }
      if (!_valid(epoch)) {
        await _remove(ref: presence, host: host);
        return;
      }
      _presence = presence;
      _host = host;
      final wasVisiting = visiting;
      worldId = id;
      if (wasVisiting != visiting) onVisitChanged(visiting);
      await presence
          .set(capture(serverNow).toJson())
          .timeout(const Duration(seconds: 10));
      if (!_valid(epoch)) {
        await _remove(ref: presence, host: host);
        return;
      }
      await _playersSub?.cancel();
      await _hostSub?.cancel();
      await _environmentSub?.cancel();
      peers.clear();
      _hostMissing = false;
      _lastHostSeen = serverNow;
      _playersSub = _db!.ref('sessions/$id/players').onValue.listen((event) {
        if (!_valid(epoch)) return;
        final latest = <String, FishingPeerSnapshot>{};
        for (final player in event.snapshot.children) {
          if (player.key == _uid) continue;
          for (final connection in player.children) {
            final value = FishingPeerSnapshot.parse(connection.value);
            if (value == null ||
                serverNow - value.stamp > 15000 ||
                value.stamp > serverNow + 5000) {
              continue;
            }
            final key = player.key!;
            if (latest[key] == null || value.stamp > latest[key]!.stamp) {
              latest[key] = value;
            }
          }
        }
        if (latest.containsKey(id)) _lastHostSeen = latest[id]!.stamp;
        peers.removeWhere((uid, _) => !latest.containsKey(uid));
        for (final entry in latest.entries) {
          if (peers.containsKey(entry.key)) {
            peers[entry.key]!.accept(entry.value);
          } else {
            peers[entry.key] = FishingPeer(entry.key, entry.value);
          }
        }
        _notify();
      }, onError: (Object e) {
        if (_valid(epoch)) {
          _fail(e);
          if (visiting) unawaited(goHome());
        }
      });
      if (id != _uid) {
        _environmentSub = _db!.ref('worlds/$id').onValue.listen((event) {
          if (!_valid(epoch)) return;
          final value = _readEnvironment(event.snapshot.value);
          if (value == null) {
            unawaited(goHome());
            return;
          }
          _visitorEnvironment = value;
          _notify();
        }, onError: (Object e) {
          if (_valid(epoch)) {
            _fail(e);
            unawaited(goHome());
          }
        });
        _hostSub = _db!.ref('worlds/$id/hosts').onValue.listen((event) {
          if (_valid(epoch) && !event.snapshot.exists) {
            error = 'Chủ thế giới đã rời đi. Bạn đã về thế giới riêng.';
            _hostMissing = true;
            unawaited(goHome());
          }
        }, onError: (Object e) {
          if (_valid(epoch)) {
            _fail(e);
            unawaited(goHome());
          }
        });
      }
      error = null;
      _notify();
    } catch (_) {
      await _remove(ref: presence, host: host);
      if (_presence == presence) {
        _presence = null;
        _host = null;
      }
      rethrow;
    }
  }

  Future<bool> visit(String input) async {
    final code = normalizeCode(input);
    if (!validCode(code)) {
      error = 'Nhập mã gồm 7 chữ hoặc số.';
      _notify();
      return false;
    }
    if (!connected || _db == null || busy || _switching) {
      error = 'Cần kết nối mạng trước khi ghé bạn.';
      _notify();
      return false;
    }
    _switching = true;
    busy = true;
    error = null;
    _notify();
    var switchingWorld = false;
    try {
      final found = await _db!
          .ref('worldCodes/$code')
          .get()
          .timeout(const Duration(seconds: 10));
      if (found.value is! String) {
        throw const FormatException('Không tìm thấy mã thế giới này.');
      }
      final id = found.value as String;
      if (id == _uid) {
        throw const FormatException('Đây là mã thế giới của bạn.');
      }
      final world = await _db!
          .ref('worlds/$id')
          .get()
          .timeout(const Duration(seconds: 10));
      if (world.child('mapVersion').value != mapVersion) {
        throw const FormatException('Hai máy cần cùng phiên bản game.');
      }
      if (!world.child('hosts').exists) {
        throw const FormatException(
            'Chủ thế giới chưa online trong mode câu cá.');
      }
      final sharedEnvironment = _readEnvironment(world.value);
      if (sharedEnvironment == null) {
        throw const FormatException(
            'Chủ thế giới cần cập nhật game rồi vào lại mode câu cá.');
      }
      final players = await _db!
          .ref('sessions/$id/players')
          .get()
          .timeout(const Duration(seconds: 10));
      final hostAlive = players.child(id).children.any((connection) {
        final peer = FishingPeerSnapshot.parse(connection.value);
        return peer != null &&
            serverNow - peer.stamp <= 15000 &&
            peer.stamp <= serverNow + 5000;
      });
      if (!hostAlive) {
        throw const FormatException(
            'Chủ thế giới chưa online trong mode câu cá.');
      }
      if (players.children.where((p) => p.key != _uid).length >= maxPlayers) {
        throw const FormatException('Thế giới đã đủ 8 người.');
      }
      if (_disposed || !connected) return false;
      final epoch = ++_epoch;
      switchingWorld = true;
      await _removePresence();
      visitingCode = code;
      _visitorEnvironment = sharedEnvironment;
      await _attach(id, epoch);
      return _valid(epoch) && worldId == id;
    } catch (e) {
      if (!_disposed) {
        _fail(e);
        try {
          if (switchingWorld) await _returnHome();
        } catch (homeError) {
          if (!_disposed) _fail(homeError);
        }
      }
      return false;
    } finally {
      _switching = false;
      if (!_disposed) {
        busy = false;
        _notify();
        if (_hostMissing && visiting) unawaited(goHome());
      }
    }
  }

  Future<void> setActive(bool active) async {
    if (_disposed) return;
    if (!active) {
      if (_suspended) {
        await _pausing;
        return;
      }
      _suspended = true;
      final epoch = ++_epoch;
      _pausing = _removePresence();
      await _pausing;
      if (_disposed || !_suspended || epoch != _epoch) return;
      _disconnected();
      return;
    }
    await _pausing;
    if (_disposed) return;
    _suspended = false;
    await start();
    if (_db == null || _disposed) return;
    try {
      final state = await _db!
          .ref('.info/connected')
          .get()
          .timeout(const Duration(seconds: 5));
      if (!_disposed && !_suspended && state.value == true) {
        connected = true;
        await _reconnect();
      }
    } catch (e) {
      if (!_disposed) _fail(e);
    }
  }

  Future<void> retry() async {
    if (_disposed || busy || _switching) return;
    _timer?.cancel();
    _timer = null;
    ++_epoch;
    await _connectionSub?.cancel();
    await _offsetSub?.cancel();
    _connectionSub = null;
    _offsetSub = null;
    await _removePresence();
    _disconnected();
    await start();
  }

  Future<void> goHome() async {
    if (_disposed || _switching) return;
    _switching = true;
    busy = true;
    _notify();
    try {
      await _returnHome();
    } catch (e) {
      if (!_disposed) _fail(e);
    } finally {
      _switching = false;
      if (!_disposed) {
        busy = false;
        _notify();
      }
    }
  }

  Future<void> _returnHome() async {
    final epoch = ++_epoch;
    await _removePresence();
    final wasVisiting = visiting;
    worldId = _uid;
    visitingCode = null;
    peers.clear();
    if (wasVisiting) onVisitChanged(false);
    if (_valid(epoch)) await _attach(_uid!, epoch);
  }

  String _environmentDisplay() => VisualState.encode({
        ..._homeDisplay,
        'environment':
            FishingEnvironment.local(preferences).toServer(_offset).toJson(),
      });

  // Read previous releases as well; new visual fields need no Rules change.
  static FishingEnvironment? _readEnvironment(Object? value) {
    if (value is! Map) return null;
    final display = VisualState.decode(value['display']);
    return FishingEnvironment.parse(display?['environment']) ??
        FishingEnvironment.parse(value['environment']);
  }

  Future<void> publishEnvironment() async {
    if (_disposed || !online || visiting || _db == null) return;
    try {
      await _db!
          .ref('worlds/$_uid/display')
          .set(_environmentDisplay())
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      if (!_disposed) _fail(e);
    }
  }

  Future<void> _publish() async {
    final ref = _presence;
    if (_disposed || _suspended || !connected || ref == null || _writing) {
      return;
    }
    _writing = true;
    try {
      await ref
          .set(capture(serverNow).toJson())
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      if (!_disposed && ref == _presence) _fail(e);
    } finally {
      _writing = false;
    }
  }

  void update(double dt) {
    for (final peer in peers.values) {
      peer.update(dt);
    }
  }

  void _disconnected() {
    connected = false;
    busy = false;
    ++_epoch;
    _presence = null;
    _host = null;
    // This database is dedicated to transient world state. Cancel unsent
    // packets so reconnect cannot resurrect an old connection's presence.
    _purging = _db?.purgeOutstandingWrites().catchError((Object e) {
      debugPrint('FishingWorld purge: $e');
    });
    unawaited(_playersSub?.cancel());
    unawaited(_hostSub?.cancel());
    unawaited(_environmentSub?.cancel());
    final wasVisiting = visiting;
    worldId = _uid;
    visitingCode = null;
    peers.clear();
    if (wasVisiting) onVisitChanged(false);
    _notify();
  }

  void _fail(Object e) {
    debugPrint('FishingWorld: $e');
    error = e is FormatException
        ? e.message.toString()
        : e is FirebaseException &&
                (e.code == 'permission-denied' || e.code == 'permission_denied')
            ? 'Firebase chưa cho phép truy cập. Cần áp dụng Rules của game.'
            : 'Chưa kết nối được thế giới. Bạn vẫn có thể chơi offline.';
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _remove(
      {DatabaseReference? ref, DatabaseReference? host}) async {
    for (final entry in [ref, host]) {
      if (entry == null) continue;
      try {
        await entry.remove().timeout(const Duration(seconds: 3));
        await entry.onDisconnect().cancel().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('FishingWorld cleanup: $e');
      }
    }
  }

  Future<void> _removePresence() async {
    final playersSub = _playersSub,
        hostSub = _hostSub,
        environmentSub = _environmentSub;
    final ref = _presence, host = _host;
    _playersSub = null;
    _hostSub = null;
    _environmentSub = null;
    _presence = null;
    _host = null;
    await playersSub?.cancel();
    await hostSub?.cancel();
    await environmentSub?.cancel();
    await _remove(ref: ref, host: host);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_epoch;
    _timer?.cancel();
    unawaited(_connectionSub?.cancel());
    unawaited(_offsetSub?.cancel());
    unawaited(_removePresence());
    super.dispose();
  }
}
