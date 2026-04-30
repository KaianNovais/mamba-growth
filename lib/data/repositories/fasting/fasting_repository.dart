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

  /// Stream dos jejuns concluídos (mais recentes primeiro). Re-emite
  /// o estado atual no momento da assinatura e depois cada vez que um
  /// jejum é encerrado. Tela de histórico consome via `StreamBuilder`.
  Stream<List<Fast>> watchCompletedFasts();

  /// Lê jejuns concluídos com `endAt` em `[start, end)`, ordenados
  /// desc por `endAt`. Janela cobre apenas o intervalo solicitado —
  /// não carrega histórico inteiro em memória.
  Future<List<Fast>> getFastsBetween(DateTime start, DateTime end);
}

class FastingException implements Exception {
  const FastingException(this.message);
  final String message;
  @override
  String toString() => 'FastingException: $message';
}
