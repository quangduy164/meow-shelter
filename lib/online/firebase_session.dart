import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Authenticated is an identity state, not proof of an active connection.
/// World presence will use RTDB .info/connected when world sync is added.
enum FirebaseSessionStatus { unavailable, connecting, authenticated }

/// Android guest login, independent of game rules and local save data.
/// Starts at app launch. Entering/resuming fishing retries failures;
/// no network work blocks play.
class FirebaseSession {
  FirebaseSession._();
  static final instance = FirebaseSession._();
  static const databaseUrl =
      'https://meow-shelter-428db-default-rtdb.asia-southeast1.firebasedatabase.app';

  final status = ValueNotifier(FirebaseSessionStatus.unavailable);
  String? get uid => _auth?.currentUser?.uid;
  FirebaseAuth? _auth;
  FirebaseDatabase? _database;
  FirebaseDatabase? get database => _database;
  Future<bool>? _pending;

  Future<bool> connect() => _pending ??= _connect().whenComplete(() {
        _pending = null;
      });

  Future<bool> _connect() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    status.value = FirebaseSessionStatus.connecting;
    try {
      // Android options come from google-services.json via the Gradle plugin.
      final app = Firebase.apps.isEmpty
          ? await Firebase.initializeApp()
          : Firebase.app();
      _auth = FirebaseAuth.instanceFor(app: app);
      _database =
          FirebaseDatabase.instanceFor(app: app, databaseURL: databaseUrl);
      if (_auth!.currentUser == null) await _auth!.signInAnonymously();
      final authenticated = _auth!.currentUser != null;
      status.value = authenticated
          ? FirebaseSessionStatus.authenticated
          : FirebaseSessionStatus.unavailable;
      return authenticated;
    } catch (error) {
      status.value = FirebaseSessionStatus.unavailable;
      debugPrint('FirebaseSession: guest login unavailable ($error)');
      return false;
    }
  }
}
