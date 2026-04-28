import 'package:firebase_auth/firebase_auth.dart';

/// Casca fina sobre [FirebaseAuth.instance].
///
/// Não tem estado, não tem regras. Existe para isolar o
/// `AuthRepository` da API do Firebase.
class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email, password: password);

  Future<UserCredential> signInWithCredential(AuthCredential credential) =>
      _auth.signInWithCredential(credential);

  Future<void> signOut() => _auth.signOut();
}
