import 'package:flutter/foundation.dart';

/// Representação imutável do usuário autenticado.
///
/// Não depende de `package:firebase_auth`. O repository traduz
/// `User` (Firebase) → [AuthUser] na borda do data layer.
@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
}
