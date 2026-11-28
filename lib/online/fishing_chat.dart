import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FishingChatMessage {
  const FishingChatMessage(
      {required this.id,
      required this.uid,
      required this.name,
      required this.text,
      required this.stamp});
  final String id, uid, name, text;
  final int stamp;
  bool get isEmote => FishingChat.emotes.contains(text);
  static String singleLine(String text) =>
      text.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), ' ').trim();
  static FishingChatMessage? parse(String? id, Object? value) {
    if (id == null || value is! Map) return null;
    final uid = value['uid'],
        name = value['name'],
        text = value['text'],
        stamp = value['stamp'];
    if (uid is! String ||
        uid.isEmpty ||
        uid.length > 128 ||
        name is! String ||
        name.length > 80 ||
        singleLine(name).isEmpty ||
        text is! String ||
        text.length > 240 ||
        text.runes.length > 120 ||
        singleLine(text).isEmpty ||
        stamp is! num ||
        !stamp.isFinite ||
        stamp < 0 ||
        stamp != stamp.roundToDouble()) {
      return null;
    }
    return FishingChatMessage(
        id: id,
        uid: uid,
        name: singleLine(name),
        text: singleLine(text),
        stamp: stamp.toInt());
  }
}

/// A bounded room channel, independent of movement/presence publishing.
class FishingChat extends ChangeNotifier {
  FishingChat({required this.now});
  final int Function() now;
  static const emotes = [
    '😺',
    '😹',
    '😻',
    '🙀',
    '😿',
    '😾',
    '❤️',
    '👍',
    '🎣',
    '🐟',
    '💤',
    '👋'
  ];
  static const quickMessages = [
    'Ra đây câu cùng!',
    'Cá to quá!',
    'Đợi tui!',
    'Đi ngủ thôi 💤'
  ];
  List<FishingChatMessage> _messages = [];
  List<FishingChatMessage> get messages => List.unmodifiable(_messages);
  final _bubbles = <String, FishingChatMessage>{};
  final _notices = <FishingChatMessage>[];
  List<FishingChatMessage> get notices => List.unmodifiable(_notices);
  FishingChatMessage? bubble(String uid) => _bubbles[uid];
  String? get uid => _uid;
  String? _uid;
  DatabaseReference? _ref;
  StreamSubscription<DatabaseEvent>? _sub;
  Timer? _expiry;
  int _epoch = 0, _lastSent = 0, unread = 0;
  bool _disposed = false, _reading = false, _primed = false, sending = false;
  bool get ready => _ref != null && _primed;
  bool get connecting => _ref != null && !_primed && error == null;
  bool get hasBubbles => _bubbles.isNotEmpty;
  String? error;

  void setReading(bool value) {
    if (_disposed) return;
    _reading = value;
    if (value && unread != 0) {
      unread = 0;
      notifyListeners();
    }
  }

  void attach(DatabaseReference ref, String uid, {required bool owner}) {
    detach();
    _ref = ref;
    _uid = uid;
    final epoch = _epoch;
    _sub = ref.child('messages').orderByKey().limitToLast(51).onValue.listen(
        (event) {
      if (_disposed || epoch != _epoch) return;
      final previous = {for (final m in _messages) m.id};
      final received = <FishingChatMessage>[];
      for (final child in event.snapshot.children) {
        final m = FishingChatMessage.parse(child.key, child.value);
        if (m != null) received.add(m);
      }
      received.sort((a, b) => a.id.compareTo(b.id));
      for (final m in received) {
        if (!previous.contains(m.id) && _primed) {
          if (m.uid != uid && !_reading) unread = (unread + 1).clamp(0, 99);
          if (now() - m.stamp < 4000 && m.stamp <= now() + 5000) {
            if (m.isEmote) {
              _bubbles[m.uid] = m;
            } else {
              _notices.add(m);
              if (_notices.length > 3) _notices.removeAt(0);
            }
          }
        }
      }
      // The owner's bounded query removes the extra oldest row; no full history read.
      if (owner && received.length > 50) {
        unawaited(ref
            .child('messages/${received.first.id}')
            .remove()
            .catchError((Object e) {
          debugPrint('FishingChat trim: $e');
        }));
      }
      _messages = received
          .skip((received.length - 50).clamp(0, received.length))
          .toList();
      _primed = true;
      error = null;
      _expireBubbles();
      notifyListeners();
    }, onError: (Object e) {
      if (_disposed || epoch != _epoch) return;
      _primed = false;
      debugPrint('FishingChat listen: $e');
      error = e is FirebaseException &&
              (e.code == 'permission-denied' || e.code == 'permission_denied')
          ? 'Phòng chưa cho phép chat. Cần cập nhật quyền Firebase.'
          : 'Chưa kết nối được chat trong phòng.';
      notifyListeners();
    });
    notifyListeners();
  }

  Future<bool> send(String input, {required String name}) async {
    final text = FishingChatMessage.singleLine(input);
    if (_disposed || sending) return false;
    if (!ready) {
      error = 'Kết nối mạng để trò chuyện trong phòng.';
      notifyListeners();
      return false;
    }
    if (text.isEmpty || text.runes.length > 120 || text.length > 240) {
      error = 'Nhập từ 1 đến 120 ký tự.';
      notifyListeners();
      return false;
    }
    if (now() - _lastSent < 1000) {
      error = 'Đợi một chút rồi gửi tiếp nhé.';
      notifyListeners();
      return false;
    }
    final ref = _ref!, epoch = _epoch;
    final id = ref.child('messages').push().key!;
    final display = String.fromCharCodes(
        FishingChatMessage.singleLine(name).runes.take(40));
    sending = true;
    error = null;
    notifyListeners();
    final write = ref.update({
      'messages/$id': {
        'uid': _uid,
        'name': display.isEmpty ? 'Mèo' : display,
        'text': text,
        'stamp': ServerValue.timestamp
      },
      'lastSent/$_uid': ServerValue.timestamp,
    });
    // A timeout cannot cancel a native RTDB write: keep the send slot occupied.
    unawaited(write.then((_) {
      if (!_disposed && epoch == _epoch) {
        _lastSent = now();
        error = null;
      }
    }, onError: (Object _) {}).whenComplete(() {
      if (!_disposed && epoch == _epoch) {
        sending = false;
        notifyListeners();
      }
    }));
    try {
      await write.timeout(const Duration(seconds: 10));
      if (_disposed || epoch != _epoch) return false;
      return true;
    } catch (e) {
      if (!_disposed && epoch == _epoch) {
        error = _errorText(e);
        notifyListeners();
      }
      return false;
    }
  }

  static String _errorText(Object e) => e is FirebaseException &&
          (e.code == 'permission-denied' || e.code == 'permission_denied')
      ? 'Chat chưa sẵn sàng. Đợi một chút rồi thử lại.'
      : 'Chưa gửi được tin. Kiểm tra kết nối rồi thử lại.';

  void _expireBubbles() {
    _expiry?.cancel();
    _bubbles.removeWhere((_, m) => now() - m.stamp >= 4000);
    _notices.removeWhere((m) => now() - m.stamp >= 4000);
    if (_bubbles.isEmpty && _notices.isEmpty) return;
    final next = [..._bubbles.values, ..._notices]
        .map((m) => m.stamp + 4000 - now())
        .reduce((a, b) => a < b ? a : b);
    _expiry = Timer(Duration(milliseconds: next.clamp(1, 9000)), () {
      if (_disposed) return;
      _expireBubbles();
      notifyListeners();
    });
  }

  void detach() {
    ++_epoch;
    _ref = null;
    _uid = null;
    unawaited(_sub?.cancel());
    _sub = null;
    _expiry?.cancel();
    _expiry = null;
    _messages = [];
    _bubbles.clear();
    _notices.clear();
    unread = 0;
    _primed = false;
    sending = false;
    error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    detach();
    super.dispose();
  }
}
