import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time_math.dart';
import '../models/activity.dart';
import '../models/routine_blueprint.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class FirebaseSyncService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  FirebaseSyncService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  /// Sign in anonymously for seamless instant sync
  Future<UserCredential?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      debugPrint('🔥 Firebase Signed in anonymously: ${cred.user?.uid}');
      return cred;
    } catch (e) {
      debugPrint('Firebase signInAnonymously error: $e');
      return null;
    }
  }

  /// Sign in with Email & Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Firebase signInWithEmail error: $e');
      rethrow;
    }
  }

  /// Register with Email & Password
  Future<UserCredential?> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint('Firebase registerWithEmail error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase signOut error: $e');
    }
  }

  /// Sync an Activity to Firestore
  Future<void> syncActivity(Activity activity) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .doc('${activity.id}');

      await docRef.set({
        'id': activity.id,
        'title': activity.title,
        'description': activity.description,
        'startMinute': activity.startMinute,
        'endMinute': activity.endMinute,
        'ampmHalf': activity.ampmHalf.index,
        'date': activity.date.toIso8601String(),
        'colorValue': activity.colorValue,
        'iconKey': activity.iconKey,
        'recurrence': activity.recurrence,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firebase syncActivity error: $e');
    }
  }

  /// Sync a RoutineBlueprint to Firestore
  Future<void> syncBlueprint(RoutineBlueprint blueprint) async {
    final user = currentUser;
    if (user == null) return;

    try {
      final docRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('blueprints')
          .doc('${blueprint.id}');

      await docRef.set(blueprint.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firebase syncBlueprint error: $e');
    }
  }

  /// Stream of user activities from Firestore
  Stream<List<Map<String, dynamic>>> streamActivities() {
    final user = currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}

final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  return FirebaseSyncService(
    auth: ref.watch(firebaseAuthProvider),
    db: ref.watch(firestoreProvider),
  );
});
