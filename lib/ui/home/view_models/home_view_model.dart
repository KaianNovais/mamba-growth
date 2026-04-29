import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/fast.dart';
import '../../../domain/models/fasting_protocol.dart';
import '../../../utils/command.dart';

/// View model da tela de jejum.
///
/// Mantém um `Timer.periodic(1s)` que apenas atualiza [now] e notifica
/// listeners, fazendo o ring/labels redesenharem. O cálculo real de
/// elapsed/remaining mora em [Fast] — por isso ao reabrir o app a
/// tela mostra o estado correto: [now] é sempre fresco em
/// `DateTime.now()`.
class HomeViewModel extends ChangeNotifier with WidgetsBindingObserver {
  HomeViewModel({required FastingRepository repository})
      : _repo = repository {
    _repo.addListener(_onRepoChanged);
    startFast = Command0<Fast>(_repo.startFast);
    endFast = Command0<Fast>(_repo.endFast);
    WidgetsBinding.instance.addObserver(this);
    _onRepoChanged();
  }

  final FastingRepository _repo;
  late final Command0<Fast> startFast;
  late final Command0<Fast> endFast;

  Timer? _ticker;
  DateTime _now = DateTime.now();

  Fast? get activeFast => _repo.activeFast;
  FastingProtocol get selectedProtocol => _repo.selectedProtocol;
  bool get isInitialized => _repo.isInitialized;
  DateTime get now => _now;

  void _onRepoChanged() {
    if (_repo.activeFast != null) {
      _ensureTicker();
    } else {
      _stopTicker();
    }
    notifyListeners();
  }

  void _ensureTicker() {
    if (_ticker != null) return;
    _now = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_repo.activeFast != null) _ensureTicker();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopTicker();
        break;
    }
  }

  @override
  void dispose() {
    _stopTicker();
    _repo.removeListener(_onRepoChanged);
    WidgetsBinding.instance.removeObserver(this);
    startFast.dispose();
    endFast.dispose();
    super.dispose();
  }
}
