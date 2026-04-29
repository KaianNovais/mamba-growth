import 'package:flutter/foundation.dart';

import '../../../domain/models/fast.dart';
import '../../../domain/models/fasting_protocol.dart';
import '../../../utils/result.dart';

/// SSOT do estado de jejum.
///
/// Implementações estendem [ChangeNotifier] e disparam
/// `notifyListeners` quando [activeFast] ou [selectedProtocol] mudam.
/// [isInitialized] é `false` até a primeira leitura do banco terminar
/// — UI mostra skeleton até lá.
abstract class FastingRepository extends ChangeNotifier {
  Fast? get activeFast;
  FastingProtocol get selectedProtocol;
  bool get isInitialized;

  Future<Result<Fast>> startFast();
  Future<Result<Fast>> endFast();
  Future<void> setProtocol(FastingProtocol protocol);
}

class FastingException implements Exception {
  const FastingException(this.message);
  final String message;
  @override
  String toString() => 'FastingException: $message';
}
