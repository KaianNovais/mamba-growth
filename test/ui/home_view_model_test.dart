import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/data/repositories/fasting/fasting_repository.dart';
import 'package:mamba_growth/domain/models/fast.dart';
import 'package:mamba_growth/domain/models/fasting_protocol.dart';
import 'package:mamba_growth/ui/home/view_models/home_view_model.dart';
import 'package:mamba_growth/utils/result.dart';

class _FakeFastingRepository extends ChangeNotifier
    implements FastingRepository {
  Fast? _activeFast;
  FastingProtocol _selectedProtocol = FastingProtocol.defaultProtocol;
  bool _isInitialized = true;

  void setActiveFast(Fast? fast) {
    _activeFast = fast;
    notifyListeners();
  }

  void setSelectedProtocol(FastingProtocol p) {
    _selectedProtocol = p;
    notifyListeners();
  }

  @override
  Fast? get activeFast => _activeFast;

  @override
  FastingProtocol get selectedProtocol => _selectedProtocol;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<Result<Fast>> startFast() async =>
      const Result.error(FastingException('not used'));

  @override
  Future<Result<Fast>> endFast() async =>
      const Result.error(FastingException('not used'));

  @override
  Future<void> setProtocol(FastingProtocol protocol) async {
    setSelectedProtocol(protocol);
  }

  @override
  Stream<List<Fast>> watchCompletedFasts() => const Stream.empty();
}

Fast _activeFastNow() => Fast(
      id: 1,
      startAt: DateTime.now(),
      endAt: null,
      targetHours: 16,
      eatingHours: 8,
      completed: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeViewModel — exposição de estado', () {
    test('expõe isInitialized, selectedProtocol e activeFast do repo', () {
      final repo = _FakeFastingRepository();
      final vm = HomeViewModel(repository: repo);
      addTearDown(vm.dispose);

      expect(vm.isInitialized, true);
      expect(vm.selectedProtocol, FastingProtocol.defaultProtocol);
      expect(vm.activeFast, isNull);

      final fast = _activeFastNow();
      repo.setActiveFast(fast);
      expect(vm.activeFast, fast);
    });

    test('notifica listeners quando o repo muda', () {
      final repo = _FakeFastingRepository();
      final vm = HomeViewModel(repository: repo);
      addTearDown(vm.dispose);

      var notifies = 0;
      vm.addListener(() => notifies++);

      repo.setSelectedProtocol(FastingProtocol.parseId('18:6'));
      expect(notifies, 1);
      expect(vm.selectedProtocol.id, '18:6');
    });
  });

  group('HomeViewModel — ticker e activeFast', () {
    test('não liga ticker quando não há jejum ativo', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository();
        final vm = HomeViewModel(repository: repo);

        expect(async.pendingTimers, isEmpty);

        vm.dispose();
      });
    });

    test('liga ticker quando há jejum ativo na inicialização', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository()..setActiveFast(_activeFastNow());
        final vm = HomeViewModel(repository: repo);

        expect(async.pendingTimers, isNotEmpty);

        vm.dispose();
      });
    });

    test('liga ticker quando activeFast passa de null para não-nulo', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository();
        final vm = HomeViewModel(repository: repo);
        expect(async.pendingTimers, isEmpty);

        repo.setActiveFast(_activeFastNow());
        expect(async.pendingTimers, isNotEmpty);

        vm.dispose();
      });
    });

    test('para ticker quando activeFast volta a null', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository()..setActiveFast(_activeFastNow());
        final vm = HomeViewModel(repository: repo);
        expect(async.pendingTimers, isNotEmpty);

        repo.setActiveFast(null);
        expect(async.pendingTimers, isEmpty);

        vm.dispose();
      });
    });
  });

  group('HomeViewModel — separação de canais', () {
    // Garante que o tick 1Hz não causa rebuilds da árvore consumidora
    // de ChangeNotifier — só widgets que escutam nowListenable
    // reconstroem (esse é o ganho de performance da feature jejum).
    test('tick NÃO dispara ChangeNotifier do VM', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository();
        final vm = HomeViewModel(repository: repo);
        repo.setActiveFast(_activeFastNow());

        var vmNotifies = 0;
        vm.addListener(() => vmNotifies++);

        async.elapse(const Duration(seconds: 3));

        expect(vmNotifies, 0);

        vm.dispose();
      });
    });
  });

  group('HomeViewModel — lifecycle', () {
    test('paused para o ticker; resumed religa quando há jejum ativo', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository()..setActiveFast(_activeFastNow());
        final vm = HomeViewModel(repository: repo);
        expect(async.pendingTimers, isNotEmpty);

        vm.didChangeAppLifecycleState(AppLifecycleState.paused);
        expect(async.pendingTimers, isEmpty);

        vm.didChangeAppLifecycleState(AppLifecycleState.resumed);
        expect(async.pendingTimers, isNotEmpty);

        vm.dispose();
      });
    });

    test('resumed NÃO liga ticker se não há jejum ativo', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository();
        final vm = HomeViewModel(repository: repo);

        vm.didChangeAppLifecycleState(AppLifecycleState.paused);
        vm.didChangeAppLifecycleState(AppLifecycleState.resumed);

        expect(async.pendingTimers, isEmpty);

        vm.dispose();
      });
    });
  });

  group('HomeViewModel — dispose', () {
    test('cancela ticker pendente', () {
      FakeAsync().run((async) {
        final repo = _FakeFastingRepository()..setActiveFast(_activeFastNow());
        final vm = HomeViewModel(repository: repo);
        expect(async.pendingTimers, isNotEmpty);

        vm.dispose();
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
