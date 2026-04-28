import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../domain/models/auth_exception.dart';
import '../../../domain/models/auth_user.dart';
import '../../../utils/result.dart';
import '../../services/auth/firebase_auth_service.dart';
import '../../services/auth/google_sign_in_service.dart';
import 'auth_repository.dart';

class AuthRepositoryFirebase extends AuthRepository {
  AuthRepositoryFirebase({
    required FirebaseAuthService firebaseAuthService,
    required GoogleSignInService googleSignInService,
  })  : _firebase = firebaseAuthService,
        _google = googleSignInService {
    _subscription = _firebase.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuthService _firebase;
  final GoogleSignInService _google;
  late final StreamSubscription<User?> _subscription;

  AuthUser? _currentUser;
  bool _isInitialized = false;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isInitialized => _isInitialized;

  void _onAuthStateChanged(User? user) {
    _currentUser = user == null ? null : _toAuthUser(user);
    _isInitialized = true;
    notifyListeners();
  }

  @override
  Future<Result<void>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebase.signInWithEmailAndPassword(email: email, password: password);
      return const Result.ok(null);
    } on FirebaseAuthException catch (e) {
      return Result.error(AuthException.fromFirebase(e));
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  Future<Result<void>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebase.createUserWithEmailAndPassword(email: email, password: password);
      return const Result.ok(null);
    } on FirebaseAuthException catch (e) {
      return Result.error(AuthException.fromFirebase(e));
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    try {
      final idToken = await _google.authenticateAndGetIdToken();
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await _firebase.signInWithCredential(credential);
      return const Result.ok(null);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return Result.error(const AuthCancelledException());
      }
      return Result.error(AuthException.googleSignInFailed(e));
    } on FirebaseAuthException catch (e) {
      return Result.error(AuthException.fromFirebase(e));
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _google.signOut();
      await _firebase.signOut();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(AuthException.unknown(e));
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  static AuthUser _toAuthUser(User u) => AuthUser(
        uid: u.uid,
        email: u.email ?? '',
        displayName: u.displayName,
        photoUrl: u.photoURL,
      );
}
