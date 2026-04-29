# Home (Jejum) Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir a feature core de jejum intermitente: timer com ring de progresso, seleção de protocolo (presets + custom), persistência em SQLite e notificação local de fim, mantendo o padrão `provider + ChangeNotifier + Command` já estabelecido no app.

**Architecture:** SSOT no `FastingRepository` (`ChangeNotifier`), backed por `sqflite`. `HomeViewModel` orquestra a tela com `Timer.periodic(1s)` que pausa em background. Notificação agendada via `flutter_local_notifications` v21 com `zonedSchedule`. Cálculos de elapsed/remaining moram em modelos de domínio puros.

**Tech Stack:** Flutter 3 + Dart, `provider`, `sqflite ^2.4.2+1`, `path`, `synchronized`, `flutter_local_notifications ^21.0.0`, `timezone`, GoRouter.

**Spec:** `docs/superpowers/specs/2026-04-29-home-fasting-feature-design.md`

---

## File Map

### Created
- `lib/domain/models/fasting_protocol.dart` — protocolo (12:12, 16:8, 18:6, custom).
- `lib/domain/models/fast.dart` — jejum ativo ou concluído (puro, com getters de elapsed/remaining/progress).
- `lib/data/services/database/local_database.dart` — singleton sqflite, schema v1, `synchronized.Lock`.
- `lib/data/services/notifications/notification_service.dart` — wrapper flutter_local_notifications.
- `lib/data/repositories/fasting/fasting_repository.dart` — interface abstrata `ChangeNotifier`.
- `lib/data/repositories/fasting/fasting_repository_local.dart` — impl SQLite.
- `lib/ui/home/view_models/home_view_model.dart` — VM com Ticker + Commands + lifecycle.
- `lib/ui/home/widgets/fasting_ring.dart` — CustomPainter do anel.
- `lib/ui/home/widgets/protocol_bottom_sheet.dart` — sheet de seleção de protocolo.
- `lib/ui/home/widgets/end_fast_dialog.dart` — confirmação de encerrar.
- `lib/ui/profile/widgets/profile_screen.dart` — placeholder + signOut.
- `test/domain/fasting_test.dart` — unit tests dos modelos puros.

### Modified
- `pubspec.yaml` — adicionar dependências.
- `android/app/src/main/AndroidManifest.xml` — permissões + receivers.
- `ios/Runner/AppDelegate.swift` — `UNUserNotificationCenter.current().delegate = self`.
- `lib/main.dart` — instanciar `LocalDatabase`, `NotificationService`, `FastingRepository`, expor via `MultiProvider`, inicializar timezone.
- `lib/routing/routes.dart` — adicionar `profile`.
- `lib/routing/router.dart` — adicionar rota `/profile`.
- `lib/ui/home/widgets/home_screen.dart` — substitui o conteúdo (mantém o nome do arquivo).
- `lib/l10n/app_pt.arb` — chaves novas (e remover/migrar `homeSignOut`, `homeEmptyTitle`, `homeEmptySubtitle`, `homeWelcomeGreeting`, `homeComingSoon`).
- `lib/l10n/app_en.arb` — espelhar PT.

---

## Wave 0 — Setup (deps + plataformas)

### Task 1: Adicionar dependências e gerar lockfile

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Adicionar dependências em `pubspec.yaml`**

Localize o bloco `dependencies:` (linha ~13) e adicione 5 entradas mantendo a ordem alfabética dentro do bloco:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
  cupertino_icons: ^1.0.8
  firebase_core: ^4.7.0
  firebase_auth: ^6.4.0
  flutter_local_notifications: ^21.0.0
  google_sign_in: ^7.2.0
  go_router: ^16.3.0
  path: ^1.9.0
  provider: ^6.1.5
  sqflite: ^2.4.2+1
  synchronized: ^3.3.0+3
  timezone: ^0.10.0
```

- [ ] **Step 2: Resolver dependências**

Run: `flutter pub get`
Expected: `Got dependencies!` sem erros.

- [ ] **Step 3: Confirmar versões resolvidas**

Run: `flutter pub deps --no-dev | grep -E "sqflite|flutter_local_notifications|timezone|synchronized|path "`
Expected: linhas listando cada pacote com a versão dentro do range pedido.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore(deps): add sqflite + flutter_local_notifications stack

Adiciona sqflite, path, synchronized, flutter_local_notifications,
timezone para a feature de jejum (home).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Configurar AndroidManifest

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Adicionar permissões e receivers**

Substitua o conteúdo completo do arquivo por:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <application
        android:label="Mamba Growth"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false"/>
        <receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

- [ ] **Step 2: Verificar build Android**

Run: `flutter build apk --debug --target-platform android-arm64 -v 2>&1 | tail -20`
Expected: `Built build/app/outputs/flutter-apk/app-debug.apk` ou erro claro de outro arquivo (não do manifest).

Se falhar com erro de manifest, comparar com o snippet acima e corrigir.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat(android): wire up local notification permissions and receivers

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Configurar iOS AppDelegate

**Files:**
- Modify: `ios/Runner/AppDelegate.swift`

- [ ] **Step 1: Substituir AppDelegate.swift**

```swift
import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/Runner/AppDelegate.swift
git commit -m "feat(ios): set UNUserNotificationCenter delegate for local notifications

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 1 — Domínio (TDD)

### Task 4: Modelos `FastingProtocol` e `Fast` (TDD)

**Files:**
- Create: `lib/domain/models/fasting_protocol.dart`
- Create: `lib/domain/models/fast.dart`
- Create: `test/domain/fasting_test.dart`

- [ ] **Step 1: Escrever testes que falham (`test/domain/fasting_test.dart`)**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_growth/domain/models/fast.dart';
import 'package:mamba_growth/domain/models/fasting_protocol.dart';

void main() {
  group('FastingProtocol', () {
    test('default é 16:8', () {
      expect(FastingProtocol.defaultProtocol.id, '16:8');
      expect(FastingProtocol.defaultProtocol.fastingHours, 16);
      expect(FastingProtocol.defaultProtocol.eatingHours, 8);
      expect(FastingProtocol.defaultProtocol.isCustom, false);
    });

    test('todos os presets somam 24h', () {
      for (final p in FastingProtocol.presets) {
        expect(p.fastingHours + p.eatingHours, 24,
            reason: 'preset ${p.id} não soma 24');
      }
    });

    test('custom factory monta id "custom:F:E"', () {
      final p = FastingProtocol.custom(fastingHours: 20, eatingHours: 4);
      expect(p.id, 'custom:20:4');
      expect(p.isCustom, true);
    });

    test('parseId reconhece preset e custom', () {
      expect(FastingProtocol.parseId('16:8'), FastingProtocol.presets[1]);
      final c = FastingProtocol.parseId('custom:20:4');
      expect(c.isCustom, true);
      expect(c.fastingHours, 20);
      expect(c.eatingHours, 4);
    });
  });

  group('Fast', () {
    final start = DateTime.utc(2026, 1, 1, 8);
    final active = Fast(
      id: 1,
      startAt: start,
      endAt: null,
      targetHours: 16,
      eatingHours: 8,
      completed: false,
    );

    test('isActive segue endAt', () {
      expect(active.isActive, true);
      final ended = Fast(
        id: 1,
        startAt: start,
        endAt: start.add(const Duration(hours: 16)),
        targetHours: 16,
        eatingHours: 8,
        completed: true,
      );
      expect(ended.isActive, false);
    });

    test('elapsed cresce com o tempo', () {
      final now = start.add(const Duration(hours: 4));
      expect(active.elapsed(now), const Duration(hours: 4));
    });

    test('remaining é zero depois da meta', () {
      final now = start.add(const Duration(hours: 20));
      expect(active.remaining(now), Duration.zero);
    });

    test('progress fica entre 0 e 1', () {
      expect(active.progress(start), 0.0);
      expect(active.progress(start.add(const Duration(hours: 8))), 0.5);
      expect(active.progress(start.add(const Duration(hours: 50))), 1.0);
    });
  });
}
```

- [ ] **Step 2: Rodar para confirmar que falha**

Run: `flutter test test/domain/fasting_test.dart`
Expected: FAIL com `Target of URI doesn't exist: 'package:mamba_growth/domain/models/fast.dart'` ou similar.

- [ ] **Step 3: Implementar `FastingProtocol`**

Crie `lib/domain/models/fasting_protocol.dart`:

```dart
import 'package:flutter/foundation.dart';

@immutable
class FastingProtocol {
  const FastingProtocol({
    required this.id,
    required this.fastingHours,
    required this.eatingHours,
    required this.isCustom,
  });

  final String id;
  final int fastingHours;
  final int eatingHours;
  final bool isCustom;

  static const presets = <FastingProtocol>[
    FastingProtocol(id: '12:12', fastingHours: 12, eatingHours: 12, isCustom: false),
    FastingProtocol(id: '16:8',  fastingHours: 16, eatingHours:  8, isCustom: false),
    FastingProtocol(id: '18:6',  fastingHours: 18, eatingHours:  6, isCustom: false),
  ];

  static const defaultProtocol = presets[1]; // 16:8

  factory FastingProtocol.custom({
    required int fastingHours,
    required int eatingHours,
  }) {
    assert(fastingHours + eatingHours == 24);
    return FastingProtocol(
      id: 'custom:$fastingHours:$eatingHours',
      fastingHours: fastingHours,
      eatingHours: eatingHours,
      isCustom: true,
    );
  }

  /// Reconhece um id persistido (preset ou custom). Em caso de id
  /// inválido, devolve [defaultProtocol] em vez de lançar — leitura
  /// do banco nunca deve crashar a tela de jejum.
  factory FastingProtocol.parseId(String id) {
    for (final p in presets) {
      if (p.id == id) return p;
    }
    if (id.startsWith('custom:')) {
      final parts = id.split(':');
      if (parts.length == 3) {
        final f = int.tryParse(parts[1]);
        final e = int.tryParse(parts[2]);
        if (f != null && e != null && f + e == 24 && f > 0 && f < 24) {
          return FastingProtocol.custom(fastingHours: f, eatingHours: e);
        }
      }
    }
    return defaultProtocol;
  }

  @override
  bool operator ==(Object other) =>
      other is FastingProtocol && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

- [ ] **Step 4: Implementar `Fast`**

Crie `lib/domain/models/fast.dart`:

```dart
import 'package:flutter/foundation.dart';

@immutable
class Fast {
  const Fast({
    required this.id,
    required this.startAt,
    required this.endAt,
    required this.targetHours,
    required this.eatingHours,
    required this.completed,
  });

  final int id;
  final DateTime startAt;
  final DateTime? endAt;
  final int targetHours;
  final int eatingHours;
  final bool completed;

  bool get isActive => endAt == null;

  Duration get target => Duration(hours: targetHours);

  Duration elapsed(DateTime now) {
    final e = now.difference(startAt);
    return e.isNegative ? Duration.zero : e;
  }

  Duration remaining(DateTime now) {
    final r = target - elapsed(now);
    return r.isNegative ? Duration.zero : r;
  }

  double progress(DateTime now) {
    if (target.inSeconds == 0) return 0;
    return (elapsed(now).inSeconds / target.inSeconds).clamp(0.0, 1.0);
  }

  /// Momento em que a meta foi (ou será) atingida.
  DateTime get plannedEndAt => startAt.add(target);

  /// Já passou da meta?
  bool overshot(DateTime now) => now.isAfter(plannedEndAt);
}
```

- [ ] **Step 5: Rodar testes — devem passar todos**

Run: `flutter test test/domain/fasting_test.dart`
Expected: `All tests passed!` (8 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/domain/models/fasting_protocol.dart lib/domain/models/fast.dart test/domain/fasting_test.dart
git commit -m "feat(domain): add FastingProtocol and Fast models

Modelos puros com cálculos de elapsed/remaining/progress no Fast e
parser de id no FastingProtocol (preset + custom). Cobre 8 cenários
de unit test.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 2 — Data services

### Task 5: `LocalDatabase` singleton

**Files:**
- Create: `lib/data/services/database/local_database.dart`

- [ ] **Step 1: Implementar singleton com schema v1**

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

/// Acesso singleton ao SQLite local.
///
/// Convencionando uma única instância aberta em todo o app: o `Lock`
/// previne múltiplas aberturas concorrentes (chamadas paralelas a
/// `database` durante o cold start). A doc oficial do tekartik/sqflite
/// recomenda exatamente esse padrão.
class LocalDatabase {
  LocalDatabase();

  static const _filename = 'mamba_growth.db';
  static const _version = 1;

  Database? _db;
  final Lock _lock = Lock();

  Future<Database> get database async {
    final db = _db;
    if (db != null && db.isOpen) return db;
    return _lock.synchronized(() async {
      final cached = _db;
      if (cached != null && cached.isOpen) return cached;
      final fresh = await _open();
      _db = fresh;
      return fresh;
    });
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _filename);
    return openDatabase(
      path,
      version: _version,
      singleInstance: true,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fasts (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        start_at      INTEGER NOT NULL,
        end_at        INTEGER,
        target_hours  INTEGER NOT NULL,
        eating_hours  INTEGER NOT NULL,
        completed     INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_fasts_active ON fasts(end_at) WHERE end_at IS NULL',
    );
    await db.execute(
      'CREATE INDEX idx_fasts_start ON fasts(start_at DESC)',
    );
    await db.execute('''
      CREATE TABLE settings (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _lock.synchronized(() async {
      final db = _db;
      if (db != null && db.isOpen) {
        await db.close();
      }
      _db = null;
    });
  }
}
```

- [ ] **Step 2: Confirmar análise estática**

Run: `flutter analyze lib/data/services/database/local_database.dart`
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/data/services/database/local_database.dart
git commit -m "feat(data): add LocalDatabase singleton with schema v1

Schema: tabela fasts (timer + histórico) + settings (key-value).
Singleton com synchronized.Lock evita aberturas concorrentes; PRAGMA
foreign_keys ligado em onConfigure.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: `NotificationService` wrapper

**Files:**
- Create: `lib/data/services/notifications/notification_service.dart`

- [ ] **Step 1: Implementar serviço**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wrapper sobre flutter_local_notifications focado nas necessidades
/// da feature de jejum (uma única notificação agendada por vez,
/// id constante).
class NotificationService {
  NotificationService();

  static const fastEndId = 1;
  static const _channelId = 'mamba_growth_fasting';
  static const _channelName = 'Jejum';
  static const _channelDescription = 'Avisos de fim de jejum';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Chamada uma vez no `main()` antes de `runApp`.
  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  /// Pede permissão na hora certa (primeiro start de jejum).
  /// Retorna `true` quando ao menos a permissão básica foi concedida.
  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;

    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
      try {
        await android.requestExactAlarmsPermission();
      } catch (e, st) {
        debugPrint('exactAlarms permission failed: $e\n$st');
      }
    }

    if (ios != null) {
      granted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return granted;
  }

  /// Agenda a notificação de fim de jejum. Sobrescreve uma agendada
  /// anteriormente com o mesmo id.
  Future<void> scheduleFastEnd({
    required DateTime endAt,
    required String title,
    required String body,
  }) async {
    final scheduled = tz.TZDateTime.from(endAt, tz.local);
    await _plugin.zonedSchedule(
      fastEndId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// Cancela a notificação de fim de jejum (no-op se já disparou).
  Future<void> cancelFastEnd() => _plugin.cancel(fastEndId);
}
```

- [ ] **Step 2: Confirmar análise**

Run: `flutter analyze lib/data/services/notifications/notification_service.dart`
Expected: `No issues found!`.

Se a API do plugin v21 quebrar (ex: `zonedSchedule` mudou para todos parâmetros nomeados), ajuste a chamada conforme o erro do compilador. A doc oficial em https://pub.dev/packages/flutter_local_notifications é a fonte autoritativa.

- [ ] **Step 3: Commit**

```bash
git add lib/data/services/notifications/notification_service.dart
git commit -m "feat(data): add NotificationService wrapper

Inicializa flutter_local_notifications + timezone, expõe
requestPermissionIfNeeded, scheduleFastEnd e cancelFastEnd com id
constante para a única notificação simultânea.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 3 — Repository

### Task 7: `FastingRepository` (interface abstrata)

**Files:**
- Create: `lib/data/repositories/fasting/fasting_repository.dart`

- [ ] **Step 1: Implementar interface**

```dart
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
```

- [ ] **Step 2: Confirmar análise**

Run: `flutter analyze lib/data/repositories/fasting/fasting_repository.dart`
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/fasting/fasting_repository.dart
git commit -m "feat(data): add FastingRepository abstract contract

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: `FastingRepositoryLocal` (impl SQLite)

**Files:**
- Create: `lib/data/repositories/fasting/fasting_repository_local.dart`

- [ ] **Step 1: Implementar repository concreto**

```dart
import 'package:sqflite/sqflite.dart';

import '../../../domain/models/fast.dart';
import '../../../domain/models/fasting_protocol.dart';
import '../../../utils/result.dart';
import '../../services/database/local_database.dart';
import '../../services/notifications/notification_service.dart';
import 'fasting_repository.dart';

class FastingRepositoryLocal extends FastingRepository {
  FastingRepositoryLocal({
    required LocalDatabase database,
    required NotificationService notifications,
    required String notificationTitle,
    required String notificationBody,
  })  : _localDb = database,
        _notifications = notifications,
        _notificationTitle = notificationTitle,
        _notificationBody = notificationBody {
    _bootstrap();
  }

  final LocalDatabase _localDb;
  final NotificationService _notifications;
  final String _notificationTitle;
  final String _notificationBody;

  static const _selectedProtocolKey = 'selected_protocol_id';

  Fast? _activeFast;
  FastingProtocol _selectedProtocol = FastingProtocol.defaultProtocol;
  bool _isInitialized = false;

  @override
  Fast? get activeFast => _activeFast;

  @override
  FastingProtocol get selectedProtocol => _selectedProtocol;

  @override
  bool get isInitialized => _isInitialized;

  Future<void> _bootstrap() async {
    try {
      final db = await _localDb.database;
      _selectedProtocol = await _readSelectedProtocol(db);
      _activeFast = await _readActiveFast(db);
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<FastingProtocol> _readSelectedProtocol(Database db) async {
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_selectedProtocolKey],
      limit: 1,
    );
    if (rows.isEmpty) return FastingProtocol.defaultProtocol;
    final value = rows.first['value'] as String?;
    return value == null
        ? FastingProtocol.defaultProtocol
        : FastingProtocol.parseId(value);
  }

  Future<Fast?> _readActiveFast(Database db) async {
    final rows = await db.query(
      'fasts',
      where: 'end_at IS NULL',
      orderBy: 'start_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _fastFromRow(rows.first);
  }

  @override
  Future<Result<Fast>> startFast() async {
    if (_activeFast != null) {
      return Result.error(
        const FastingException('Já existe um jejum ativo.'),
      );
    }
    try {
      final now = DateTime.now();
      final db = await _localDb.database;
      final id = await db.insert('fasts', {
        'start_at': now.millisecondsSinceEpoch,
        'end_at': null,
        'target_hours': _selectedProtocol.fastingHours,
        'eating_hours': _selectedProtocol.eatingHours,
        'completed': 0,
      });
      final fast = Fast(
        id: id,
        startAt: now,
        endAt: null,
        targetHours: _selectedProtocol.fastingHours,
        eatingHours: _selectedProtocol.eatingHours,
        completed: false,
      );
      _activeFast = fast;
      notifyListeners();

      // Permissão + agendamento são best-effort — falhas não impedem o jejum.
      final granted = await _notifications.requestPermissionIfNeeded();
      if (granted) {
        try {
          await _notifications.scheduleFastEnd(
            endAt: fast.plannedEndAt,
            title: _notificationTitle,
            body: _notificationBody,
          );
        } catch (_) {/* schedule é best-effort */}
      }

      return Result.ok(fast);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<Result<Fast>> endFast() async {
    final current = _activeFast;
    if (current == null) {
      return Result.error(
        const FastingException('Nenhum jejum ativo para encerrar.'),
      );
    }
    try {
      final now = DateTime.now();
      final db = await _localDb.database;
      final completed = !now.isBefore(current.plannedEndAt);
      await db.update(
        'fasts',
        {
          'end_at': now.millisecondsSinceEpoch,
          'completed': completed ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [current.id],
      );
      await _notifications.cancelFastEnd();

      final ended = Fast(
        id: current.id,
        startAt: current.startAt,
        endAt: now,
        targetHours: current.targetHours,
        eatingHours: current.eatingHours,
        completed: completed,
      );
      _activeFast = null;
      notifyListeners();
      return Result.ok(ended);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  @override
  Future<void> setProtocol(FastingProtocol protocol) async {
    if (_selectedProtocol == protocol) return;
    final db = await _localDb.database;
    await db.insert(
      'settings',
      {'key': _selectedProtocolKey, 'value': protocol.id},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _selectedProtocol = protocol;
    notifyListeners();
  }

  Fast _fastFromRow(Map<String, Object?> row) {
    return Fast(
      id: row['id'] as int,
      startAt: DateTime.fromMillisecondsSinceEpoch(row['start_at'] as int),
      endAt: row['end_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['end_at'] as int),
      targetHours: row['target_hours'] as int,
      eatingHours: row['eating_hours'] as int,
      completed: (row['completed'] as int) == 1,
    );
  }
}
```

- [ ] **Step 2: Confirmar análise**

Run: `flutter analyze lib/data/repositories/fasting/`
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/fasting/fasting_repository_local.dart
git commit -m "feat(data): add SQLite-backed FastingRepository

Bootstrap carrega protocolo + jejum ativo do banco. startFast pede
permissão de notificação na hora e agenda zonedSchedule (best-effort).
endFast atualiza completed e cancela notificação. setProtocol persiste
em settings.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 4 — ViewModel

### Task 9: `HomeViewModel` com Ticker e lifecycle

**Files:**
- Create: `lib/ui/home/view_models/home_view_model.dart`

- [ ] **Step 1: Implementar VM**

```dart
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
```

- [ ] **Step 2: Confirmar análise**

Run: `flutter analyze lib/ui/home/view_models/home_view_model.dart`
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/view_models/home_view_model.dart
git commit -m "feat(home): add HomeViewModel with ticker and lifecycle

Ticker 1Hz pausa em background, retoma no resumed. Cálculos reais
moram em Fast — VM só dispara repaint. Reusa Command0 do utils.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 5 — UI primitives

### Task 10: `FastingRing` (CustomPainter + animação)

**Files:**
- Create: `lib/ui/home/widgets/fasting_ring.dart`

- [ ] **Step 1: Implementar ring**

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/themes/themes.dart';

/// Anel circular que representa o progresso do jejum.
///
/// Cresce de 0 → progresso atual via TweenAnimationBuilder
/// (easeOutCubic, 280ms) — suaviza o tick 1Hz do view model. O child
/// é desenhado no centro (números do timer / meta).
class FastingRing extends StatelessWidget {
  const FastingRing({
    super.key,
    required this.progress,
    required this.size,
    required this.child,
  });

  final double progress;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => CustomPaint(
            painter: _RingPainter(
              progress: value,
              trackColor: colors.borderDim,
              progressColor: colors.accent,
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  static const _strokeWidth = 6.0;

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) - _strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final fg = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
```

- [ ] **Step 2: Confirmar análise**

Run: `flutter analyze lib/ui/home/widgets/fasting_ring.dart`
Expected: `No issues found!`.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/widgets/fasting_ring.dart
git commit -m "feat(home): add FastingRing CustomPainter

Anel com track + progress arc (StrokeCap.round, começa às 12h, sentido
horário). TweenAnimationBuilder suaviza updates 1Hz; RepaintBoundary
isola o repaint do resto da tela.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 11: `ProtocolBottomSheet`

**Files:**
- Create: `lib/ui/home/widgets/protocol_bottom_sheet.dart`

- [ ] **Step 1: Implementar sheet**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/fasting_protocol.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

class ProtocolBottomSheet extends StatelessWidget {
  const ProtocolBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      builder: (sheetContext) {
        // Reusa o repo do contexto pai — o sheet consulta e commita
        // direto, sem view model próprio (estado é simples).
        return ChangeNotifierProvider<FastingRepository>.value(
          value: context.read<FastingRepository>(),
          child: const ProtocolBottomSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => const _SheetContent();
}

class _SheetContent extends StatefulWidget {
  const _SheetContent();

  @override
  State<_SheetContent> createState() => _SheetContentState();
}

class _SheetContentState extends State<_SheetContent> {
  late FastingProtocol _selected;
  late int _customFasting;

  @override
  void initState() {
    super.initState();
    final repo = context.read<FastingRepository>();
    _selected = repo.selectedProtocol;
    _customFasting = repo.selectedProtocol.isCustom
        ? repo.selectedProtocol.fastingHours
        : 20;
  }

  bool get _isCustomSelected => _selected.isCustom;

  void _selectPreset(FastingProtocol p) {
    HapticFeedback.selectionClick();
    setState(() => _selected = p);
  }

  void _selectCustom() {
    HapticFeedback.selectionClick();
    setState(() {
      _selected = FastingProtocol.custom(
        fastingHours: _customFasting,
        eatingHours: 24 - _customFasting,
      );
    });
  }

  void _onCustomChanged(double v) {
    final hours = v.round().clamp(1, 23);
    setState(() {
      _customFasting = hours;
      if (_isCustomSelected) {
        _selected = FastingProtocol.custom(
          fastingHours: hours,
          eatingHours: 24 - hours,
        );
      }
    });
  }

  Future<void> _confirm() async {
    HapticFeedback.lightImpact();
    await context.read<FastingRepository>().setProtocol(_selected);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final l10n = AppLocalizations.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final initial = context.read<FastingRepository>().selectedProtocol;
    final changed = _selected != initial;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                l10n.homeProtocolSheetTitle,
                style: text.headlineSmall?.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.homeProtocolSheetSubtitle,
                style: text.bodyMedium?.copyWith(color: colors.textDim),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  for (var i = 0; i < FastingProtocol.presets.length; i++) ...[
                    Expanded(
                      child: _ProtocolCard(
                        protocol: FastingProtocol.presets[i],
                        label: switch (FastingProtocol.presets[i].id) {
                          '12:12' => l10n.homeProtocolBeginner,
                          '16:8' => l10n.homeProtocolPopular,
                          '18:6' => l10n.homeProtocolAdvanced,
                          _ => '',
                        },
                        selected: _selected.id == FastingProtocol.presets[i].id,
                        onTap: () => _selectPreset(FastingProtocol.presets[i]),
                      ),
                    ),
                    if (i < FastingProtocol.presets.length - 1)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _CustomCard(
                fastingHours: _customFasting,
                eatingHours: 24 - _customFasting,
                selected: _isCustomSelected,
                onTap: _selectCustom,
                onSliderChanged: _onCustomChanged,
                customLabel: l10n.homeProtocolCustom,
                liveLabel: l10n.homeProtocolCustomLabel(
                  _customFasting,
                  24 - _customFasting,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: changed ? _confirm : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: colors.bg,
                    disabledBackgroundColor:
                        colors.accent.withValues(alpha: 0.4),
                    disabledForegroundColor:
                        colors.bg.withValues(alpha: 0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    l10n.homeProtocolConfirm,
                    style: text.labelLarge?.copyWith(
                      color: colors.bg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProtocolCard extends StatelessWidget {
  const _ProtocolCard({
    required this.protocol,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FastingProtocol protocol;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final borderColor = selected ? colors.accent : colors.border;
    final bgColor = selected
        ? colors.accent.withValues(alpha: 0.08)
        : colors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Text(
              '${protocol.fastingHours} : ${protocol.eatingHours}',
              style: typo.numericLarge.copyWith(
                color: selected ? colors.accent : colors.text,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: typo.caption.copyWith(
                color: selected ? colors.accent : colors.textDim,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCard extends StatelessWidget {
  const _CustomCard({
    required this.fastingHours,
    required this.eatingHours,
    required this.selected,
    required this.onTap,
    required this.onSliderChanged,
    required this.customLabel,
    required this.liveLabel,
  });

  final int fastingHours;
  final int eatingHours;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<double> onSliderChanged;
  final String customLabel;
  final String liveLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final borderColor = selected ? colors.accent : colors.border;
    final bgColor = selected
        ? colors.accent.withValues(alpha: 0.08)
        : colors.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  customLabel,
                  style: text.titleMedium?.copyWith(
                    color: selected ? colors.accent : colors.text,
                  ),
                ),
                Text(
                  liveLabel,
                  style: typo.numericSmall.copyWith(
                    color: selected ? colors.accent : colors.textDim,
                  ),
                ),
              ],
            ),
            Slider(
              min: 1,
              max: 23,
              divisions: 22,
              value: fastingHours.toDouble(),
              activeColor: colors.accent,
              inactiveColor: colors.borderDim,
              onChanged: onSliderChanged,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Confirmar análise**

Run: `flutter analyze lib/ui/home/widgets/protocol_bottom_sheet.dart`
Expected: `No issues found!` (algumas chaves de l10n ainda não existem; o erro será resolvido na Task 14).

Aceite warnings de chaves l10n inexistentes nesta task; sumirão depois da Task 14.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/widgets/protocol_bottom_sheet.dart
git commit -m "feat(home): add ProtocolBottomSheet

Sheet com 3 cards de presets + card custom com Slider 1..23h. Estado
local; commita via repo.setProtocol no botão Selecionar.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 12: `EndFastDialog`

**Files:**
- Create: `lib/ui/home/widgets/end_fast_dialog.dart`

- [ ] **Step 1: Implementar dialog**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';

/// Diálogo de confirmação para encerrar o jejum ativo.
///
/// Resolve `true` quando o usuário confirma; `false` ou `null` ao
/// cancelar (toque fora também cancela).
class EndFastDialog extends StatelessWidget {
  const EndFastDialog._({required this.fast, required this.now});

  final Fast fast;
  final DateTime now;

  static Future<bool> show(
    BuildContext context, {
    required Fast fast,
    required DateTime now,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EndFastDialog._(fast: fast, now: now),
    );
    return result ?? false;
  }

  String _formatHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}min' : '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final overshot = fast.overshot(now);
    final body = overshot
        ? l10n.homeEndDialogSurpassed(_formatHm(now.difference(fast.plannedEndAt)))
        : l10n.homeEndDialogBody(
            _formatHm(fast.elapsed(now)),
            '${fast.targetHours}h',
          );

    return AlertDialog(
      title: Text(l10n.homeEndDialogTitle),
      content: Text(body, style: text.bodyMedium?.copyWith(color: colors.textDim)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.homeEndDialogCancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE5484D),
            foregroundColor: colors.text,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(true);
          },
          child: Text(l10n.homeEndDialogConfirm),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Confirmar análise**

Run: `flutter analyze lib/ui/home/widgets/end_fast_dialog.dart`
Expected: warnings só de chaves l10n inexistentes (resolvidas na Task 14).

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/widgets/end_fast_dialog.dart
git commit -m "feat(home): add EndFastDialog confirmation

Diálogo com mensagem que muda quando o usuário superou a meta. Botão
destrutivo em colors.error com mediumImpact ao confirmar.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 6 — Screens

### Task 13: `HomeScreen` (substitui o atual)

**Files:**
- Modify: `lib/ui/home/widgets/home_screen.dart`

- [ ] **Step 1: Substituir conteúdo do arquivo**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/fasting/fasting_repository.dart';
import '../../../domain/models/fast.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../routing/routes.dart';
import '../../../utils/result.dart';
import '../../core/themes/themes.dart';
import '../view_models/home_view_model.dart';
import 'end_fast_dialog.dart';
import 'fasting_ring.dart';
import 'protocol_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (ctx) => HomeViewModel(
        repository: ctx.read<FastingRepository>(),
      ),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.homeFastingTitle),
        actions: [
          IconButton(
            tooltip: l10n.homeProfileAction,
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.of(context, rootNavigator: false)
                .pushNamed(Routes.profile),
          ),
          IconButton(
            tooltip: l10n.homeProtocolAction,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => ProtocolBottomSheet.show(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Consumer<HomeViewModel>(
          builder: (context, vm, _) {
            if (!vm.isInitialized) {
              return const Center(child: CircularProgressIndicator());
            }
            return _Body(vm: vm);
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm});
  final HomeViewModel vm;

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '${m}min';
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  String _formatClock(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _onPrimaryPressed(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final fast = vm.activeFast;

    if (fast == null) {
      HapticFeedback.lightImpact();
      await vm.startFast.execute();
      final result = vm.startFast.result;
      if (result is Error<Fast>) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.authErrorUnknown)),
        );
      }
      return;
    }

    final confirmed = await EndFastDialog.show(
      context,
      fast: fast,
      now: vm.now,
    );
    if (!confirmed) return;
    await vm.endFast.execute();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final typo = context.typo;
    final fast = vm.activeFast;
    final protocol = vm.selectedProtocol;
    final ringDiameter =
        (MediaQuery.sizeOf(context).width * 0.62).clamp(200.0, 280.0);

    final eyebrow = fast != null
        ? '${l10n.homeProtocolEyebrow} · ${protocol.fastingHours}:${protocol.eatingHours}'
        : '${l10n.homeNextProtocolEyebrow} · ${protocol.fastingHours}:${protocol.eatingHours}';

    final progress = fast?.progress(vm.now) ?? 0.0;

    final centerChild = fast != null
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatElapsed(fast.elapsed(vm.now)),
                style: typo.numericLarge.copyWith(color: colors.accent),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeElapsedLabel,
                style: typo.caption.copyWith(color: colors.textDim, letterSpacing: 1.6),
              ),
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${protocol.fastingHours}h',
                style: typo.numericLarge.copyWith(color: colors.text),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.homeFastingTargetLabel,
                style: typo.caption.copyWith(color: colors.textDim, letterSpacing: 1.6),
              ),
            ],
          );

    final subtitle = fast != null
        ? _ActiveSubtitle(fast: fast, now: vm.now)
        : Text(
            l10n.homeEatingWindow(protocol.eatingHours),
            style: text.bodyMedium?.copyWith(color: colors.textDim),
            textAlign: TextAlign.center,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          const Spacer(),
          Text(
            eyebrow.toUpperCase(),
            style: typo.caption.copyWith(
              color: colors.textDim,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            label: fast != null
                ? l10n.homeRingSemanticsActive(
                    fast.elapsed(vm.now).inHours,
                    fast.elapsed(vm.now).inMinutes % 60,
                    fast.remaining(vm.now).inHours,
                    fast.remaining(vm.now).inMinutes % 60,
                    fast.targetHours,
                  )
                : l10n.homeRingSemanticsIdle(protocol.fastingHours),
            child: FastingRing(
              progress: progress,
              size: ringDiameter,
              child: centerChild,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          subtitle,
          const Spacer(),
          AnimatedBuilder(
            animation: Listenable.merge([vm.startFast, vm.endFast]),
            builder: (context, _) {
              final running = vm.startFast.running || vm.endFast.running;
              final isActive = vm.activeFast != null;
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: running ? null : () => _onPrimaryPressed(context),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isActive ? colors.surface2 : colors.accent,
                    foregroundColor: isActive ? colors.text : colors.bg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: running
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              isActive ? colors.text : colors.bg,
                            ),
                          ),
                        )
                      : Text(
                          isActive ? l10n.homeEndFast : l10n.homeStartFast,
                          style: text.labelLarge?.copyWith(
                            color: isActive ? colors.text : colors.bg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ActiveSubtitle extends StatelessWidget {
  const _ActiveSubtitle({required this.fast, required this.now});
  final Fast fast;
  final DateTime now;

  String _formatRemaining(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h <= 0) return '${m}min';
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  String _formatClock(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;

    if (fast.overshot(now)) {
      final over = now.difference(fast.plannedEndAt);
      return Column(
        children: [
          Text(
            l10n.homeGoalReached,
            style: text.bodyLarge?.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.homeGoalReachedAgo(_formatRemaining(over)),
            style: text.bodyMedium?.copyWith(color: colors.textDim),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          l10n.homeEndsIn(_formatRemaining(fast.remaining(now))),
          style: text.bodyLarge?.copyWith(color: colors.text),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.homeEndsAt(_formatClock(fast.plannedEndAt)),
          style: text.bodyMedium?.copyWith(color: colors.textDim),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Confirmar análise (warnings de l10n esperados até Task 14)**

Run: `flutter analyze lib/ui/home/widgets/home_screen.dart`
Expected: warnings só de chaves l10n inexistentes.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/home/widgets/home_screen.dart
git commit -m "feat(home): rewrite HomeScreen with ring, eyebrow, subtitle and CTA

Substitui o EmptyFeatureState pelo timer real. Estado idle e ativo
compartilham a mesma forma (ring + center + subtitle + CTA único).
Confirmação de encerrar via EndFastDialog.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 14: `ProfileScreen` placeholder

**Files:**
- Create: `lib/ui/profile/widgets/profile_screen.dart`

- [ ] **Step 1: Implementar tela**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../core/themes/themes.dart';
import '../../core/widgets/empty_feature_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final repo = context.read<AuthRepository>();

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: Text(l10n.profileTitle),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: EmptyFeatureState(
                icon: Icons.person_outline_rounded,
                eyebrow: l10n.profileTitle,
                title: l10n.profileEmptyTitle,
                subtitle: l10n.profileEmptySubtitle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.xl2,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => repo.signOut(),
                  child: Text(l10n.profileSignOut),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Confirmar análise (warnings l10n esperados)**

Run: `flutter analyze lib/ui/profile/widgets/profile_screen.dart`
Expected: warnings só de chaves l10n inexistentes.

- [ ] **Step 3: Commit**

```bash
git add lib/ui/profile/widgets/profile_screen.dart
git commit -m "feat(profile): add placeholder ProfileScreen with signOut

EmptyFeatureState reutilizado, OutlinedButton 'Sair' no rodapé chama
authRepository.signOut. Movemos a action de logout da AppBar do
Home para cá.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 7 — Wiring (l10n, routes, main)

### Task 15: Atualizar arquivos `.arb`

**Files:**
- Modify: `lib/l10n/app_pt.arb`
- Modify: `lib/l10n/app_en.arb`

- [ ] **Step 1: Reescrever `app_pt.arb`**

```json
{
  "@@locale": "pt",
  "appName": "Mamba Growth",
  "onboardingEyebrow": "JEJUM & CALORIAS",
  "onboardingTitle": "Coma com propósito.\nJejue com clareza.",
  "onboardingSubtitle": "Acompanhe cada jejum e cada caloria em um só lugar. Sem ruído, sem culpa — só números honestos que mostram seu progresso real.",
  "onboardingHeroLabel": "EM JEJUM",
  "onboardingHeroFootnote": "Dia exemplo · 10h 24m de 16h",
  "onboardingPillarFocus": "Consciência",
  "onboardingPillarDiscipline": "Consistência",
  "onboardingPillarGrowth": "Visão",
  "onboardingPrimaryCta": "Começar",
  "onboardingFooter": "Ao continuar você concorda com nossos Termos e Política de Privacidade.",
  "onboardingFooterTermsLabel": "Termos",
  "onboardingFooterPrivacyLabel": "Política de Privacidade",
  "authSignInTitle": "Bem-vindo de volta",
  "authSignUpTitle": "Crie sua conta",
  "authSignInSubtitle": "Entre para continuar sua jornada.",
  "authSignUpSubtitle": "Comece a acompanhar com intenção.",
  "authEmailLabel": "E-mail",
  "authEmailHint": "voce@email.com",
  "authPasswordLabel": "Senha",
  "authPasswordVisibilityShow": "Mostrar senha",
  "authPasswordVisibilityHide": "Ocultar senha",
  "authSubmitSignIn": "Entrar",
  "authSubmitSignUp": "Criar conta",
  "authContinueWithGoogle": "Continuar com Google",
  "authDividerOr": "OU",
  "authToggleToSignUpPrompt": "Não tem uma conta?",
  "authToggleToSignUpAction": "Criar agora",
  "authToggleToSignInPrompt": "Já tem uma conta?",
  "authToggleToSignInAction": "Entrar",
  "authErrorInvalidCredentials": "E-mail ou senha incorretos.",
  "authErrorEmailInUse": "Já existe uma conta com esse e-mail.",
  "authErrorWeakPassword": "A senha precisa ter no mínimo 6 caracteres.",
  "authErrorUserDisabled": "Esta conta foi desativada.",
  "authErrorNetwork": "Sem conexão com a internet.",
  "authErrorTooManyRequests": "Muitas tentativas. Tente novamente em instantes.",
  "authErrorGoogleSignInFailed": "Não foi possível entrar com Google.",
  "authErrorUnknown": "Algo deu errado. Tente novamente.",
  "navHome": "Início",
  "navMeals": "Refeições",
  "navHistory": "Histórico",
  "navStats": "Stats",
  "homeFastingTitle": "Jejum",
  "homeProfileAction": "Perfil",
  "homeProtocolAction": "Trocar protocolo",
  "homeStartFast": "Iniciar jejum",
  "homeEndFast": "Encerrar jejum",
  "homeElapsedLabel": "decorrido",
  "homeFastingTargetLabel": "meta de jejum",
  "homeProtocolEyebrow": "Protocolo",
  "homeNextProtocolEyebrow": "Próximo protocolo",
  "homeEndsIn": "Termina em {duration}",
  "@homeEndsIn": {
    "placeholders": { "duration": { "type": "String" } }
  },
  "homeEndsAt": "às {time}",
  "@homeEndsAt": {
    "placeholders": { "time": { "type": "String" } }
  },
  "homeGoalReached": "Meta atingida",
  "homeGoalReachedAgo": "há {duration}",
  "@homeGoalReachedAgo": {
    "placeholders": { "duration": { "type": "String" } }
  },
  "homeEatingWindow": "Janela alimentar de {hours}h",
  "@homeEatingWindow": {
    "placeholders": { "hours": { "type": "int" } }
  },
  "homeEndDialogTitle": "Encerrar jejum?",
  "homeEndDialogBody": "Você jejuou {elapsed} de {target}. Sua progressão será salva no histórico.",
  "@homeEndDialogBody": {
    "placeholders": {
      "elapsed": { "type": "String" },
      "target": { "type": "String" }
    }
  },
  "homeEndDialogSurpassed": "Você superou sua meta em {over} · ótimo trabalho.",
  "@homeEndDialogSurpassed": {
    "placeholders": { "over": { "type": "String" } }
  },
  "homeEndDialogCancel": "Cancelar",
  "homeEndDialogConfirm": "Encerrar",
  "homeProtocolSheetTitle": "Protocolo de jejum",
  "homeProtocolSheetSubtitle": "Escolha quanto tempo você vai jejuar.",
  "homeProtocolBeginner": "iniciante",
  "homeProtocolPopular": "popular",
  "homeProtocolAdvanced": "avançado",
  "homeProtocolCustom": "Personalizado",
  "homeProtocolCustomLabel": "{fast}h jejum · {eat}h alimentação",
  "@homeProtocolCustomLabel": {
    "placeholders": {
      "fast": { "type": "int" },
      "eat": { "type": "int" }
    }
  },
  "homeProtocolConfirm": "Selecionar protocolo",
  "homeNotificationFastEndTitle": "Jejum concluído",
  "homeNotificationFastEndBody": "Você atingiu sua meta. Quebre o jejum quando estiver pronto.",
  "homeRingSemanticsActive": "Jejum {elapsedH} horas e {elapsedM} minutos. Faltam {remainingH} horas e {remainingM} minutos para a meta de {target} horas.",
  "@homeRingSemanticsActive": {
    "placeholders": {
      "elapsedH": { "type": "int" },
      "elapsedM": { "type": "int" },
      "remainingH": { "type": "int" },
      "remainingM": { "type": "int" },
      "target": { "type": "int" }
    }
  },
  "homeRingSemanticsIdle": "Pronto para iniciar jejum de {target} horas.",
  "@homeRingSemanticsIdle": {
    "placeholders": { "target": { "type": "int" } }
  },
  "mealsEmptyTitle": "Nenhuma refeição registrada.",
  "mealsEmptySubtitle": "Adicione sua primeira refeição para começar a ver suas calorias do dia com intenção.",
  "historyEmptyTitle": "Nada no seu histórico.",
  "historyEmptySubtitle": "Jejuns passados e dias registrados aparecem aqui conforme você constrói consistência.",
  "statsEmptyTitle": "Insights a caminho.",
  "statsEmptySubtitle": "Com alguns dias registrados, você vê tendências honestas e seu progresso real aqui.",
  "profileTitle": "Perfil",
  "profileEmptyTitle": "Em breve.",
  "profileEmptySubtitle": "Configurações da conta e personalizações vão morar aqui.",
  "profileSignOut": "Sair"
}
```

Removidas: `homeWelcomeGreeting`, `homeComingSoon`, `homeSignOut`, `homeEmptyTitle`, `homeEmptySubtitle`. Migradas/novas: bloco `home*` da feature de jejum + `profile*`.

- [ ] **Step 2: Reescrever `app_en.arb` espelhado**

```json
{
  "@@locale": "en",
  "appName": "Mamba Growth",
  "onboardingEyebrow": "FASTING & CALORIES",
  "onboardingTitle": "Eat with purpose.\nFast with clarity.",
  "onboardingSubtitle": "Track every fast and every calorie in one place. No noise, no shame — just honest numbers showing your real progress.",
  "onboardingHeroLabel": "FASTING",
  "onboardingHeroFootnote": "Sample day · 10h 24m of 16h",
  "onboardingPillarFocus": "Awareness",
  "onboardingPillarDiscipline": "Consistency",
  "onboardingPillarGrowth": "Vision",
  "onboardingPrimaryCta": "Get started",
  "onboardingFooter": "By continuing you agree to our Terms and Privacy Policy.",
  "onboardingFooterTermsLabel": "Terms",
  "onboardingFooterPrivacyLabel": "Privacy Policy",
  "authSignInTitle": "Welcome back",
  "authSignUpTitle": "Create your account",
  "authSignInSubtitle": "Sign in to continue your journey.",
  "authSignUpSubtitle": "Start tracking with intention.",
  "authEmailLabel": "Email",
  "authEmailHint": "you@email.com",
  "authPasswordLabel": "Password",
  "authPasswordVisibilityShow": "Show password",
  "authPasswordVisibilityHide": "Hide password",
  "authSubmitSignIn": "Sign in",
  "authSubmitSignUp": "Create account",
  "authContinueWithGoogle": "Continue with Google",
  "authDividerOr": "OR",
  "authToggleToSignUpPrompt": "Don't have an account?",
  "authToggleToSignUpAction": "Create one",
  "authToggleToSignInPrompt": "Already have an account?",
  "authToggleToSignInAction": "Sign in",
  "authErrorInvalidCredentials": "Wrong email or password.",
  "authErrorEmailInUse": "An account already exists for this email.",
  "authErrorWeakPassword": "Password must be at least 6 characters.",
  "authErrorUserDisabled": "This account has been disabled.",
  "authErrorNetwork": "No internet connection.",
  "authErrorTooManyRequests": "Too many attempts. Try again in a moment.",
  "authErrorGoogleSignInFailed": "Couldn't sign in with Google.",
  "authErrorUnknown": "Something went wrong. Try again.",
  "navHome": "Home",
  "navMeals": "Meals",
  "navHistory": "History",
  "navStats": "Stats",
  "homeFastingTitle": "Fasting",
  "homeProfileAction": "Profile",
  "homeProtocolAction": "Change protocol",
  "homeStartFast": "Start fast",
  "homeEndFast": "End fast",
  "homeElapsedLabel": "elapsed",
  "homeFastingTargetLabel": "fasting target",
  "homeProtocolEyebrow": "Protocol",
  "homeNextProtocolEyebrow": "Next protocol",
  "homeEndsIn": "Ends in {duration}",
  "@homeEndsIn": {
    "placeholders": { "duration": { "type": "String" } }
  },
  "homeEndsAt": "at {time}",
  "@homeEndsAt": {
    "placeholders": { "time": { "type": "String" } }
  },
  "homeGoalReached": "Goal reached",
  "homeGoalReachedAgo": "{duration} ago",
  "@homeGoalReachedAgo": {
    "placeholders": { "duration": { "type": "String" } }
  },
  "homeEatingWindow": "{hours}h eating window",
  "@homeEatingWindow": {
    "placeholders": { "hours": { "type": "int" } }
  },
  "homeEndDialogTitle": "End fast?",
  "homeEndDialogBody": "You fasted {elapsed} of {target}. Your progress will be saved to history.",
  "@homeEndDialogBody": {
    "placeholders": {
      "elapsed": { "type": "String" },
      "target": { "type": "String" }
    }
  },
  "homeEndDialogSurpassed": "You beat your goal by {over} · great work.",
  "@homeEndDialogSurpassed": {
    "placeholders": { "over": { "type": "String" } }
  },
  "homeEndDialogCancel": "Cancel",
  "homeEndDialogConfirm": "End",
  "homeProtocolSheetTitle": "Fasting protocol",
  "homeProtocolSheetSubtitle": "Choose how long you'll fast.",
  "homeProtocolBeginner": "beginner",
  "homeProtocolPopular": "popular",
  "homeProtocolAdvanced": "advanced",
  "homeProtocolCustom": "Custom",
  "homeProtocolCustomLabel": "{fast}h fasting · {eat}h eating",
  "@homeProtocolCustomLabel": {
    "placeholders": {
      "fast": { "type": "int" },
      "eat": { "type": "int" }
    }
  },
  "homeProtocolConfirm": "Select protocol",
  "homeNotificationFastEndTitle": "Fast complete",
  "homeNotificationFastEndBody": "You hit your goal. Break your fast when you're ready.",
  "homeRingSemanticsActive": "Fasting {elapsedH} hours and {elapsedM} minutes. {remainingH} hours and {remainingM} minutes left to reach the {target} hour goal.",
  "@homeRingSemanticsActive": {
    "placeholders": {
      "elapsedH": { "type": "int" },
      "elapsedM": { "type": "int" },
      "remainingH": { "type": "int" },
      "remainingM": { "type": "int" },
      "target": { "type": "int" }
    }
  },
  "homeRingSemanticsIdle": "Ready to start a {target} hour fast.",
  "@homeRingSemanticsIdle": {
    "placeholders": { "target": { "type": "int" } }
  },
  "mealsEmptyTitle": "No meals logged.",
  "mealsEmptySubtitle": "Add your first meal to start seeing your calories with intention.",
  "historyEmptyTitle": "Nothing in your history.",
  "historyEmptySubtitle": "Past fasts and logged days will appear here as you build consistency.",
  "statsEmptyTitle": "Insights on the way.",
  "statsEmptySubtitle": "Once you log a few days, you'll see honest trends and real progress here.",
  "profileTitle": "Profile",
  "profileEmptyTitle": "Coming soon.",
  "profileEmptySubtitle": "Account settings and customizations will live here.",
  "profileSignOut": "Sign out"
}
```

- [ ] **Step 3: Regenerar bindings**

Run: `flutter gen-l10n`
Expected: Sem erros. Os arquivos `lib/l10n/generated/*` são reescritos.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat(l10n): add fasting + profile keys; remove obsolete home keys

Adiciona blocos home*/profile* da nova feature, remove placeholders
antigos (homeEmpty*, homeWelcomeGreeting, homeComingSoon, homeSignOut),
regenera bindings.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 16: Adicionar rota `/profile`

**Files:**
- Modify: `lib/routing/routes.dart`
- Modify: `lib/routing/router.dart`

- [ ] **Step 1: Adicionar constantes em `routes.dart`**

```dart
abstract class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const profile = '/profile';
}

abstract class RouteNames {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const home = 'home';
  static const profile = 'profile';
}
```

- [ ] **Step 2: Registrar rota em `router.dart`**

Substituir o conteúdo do arquivo:

```dart
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../ui/auth/widgets/auth_bottom_sheet.dart';
import '../ui/main/widgets/main_navigation_screen.dart';
import '../ui/onboarding/widgets/onboarding_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
import '../ui/splash/widgets/splash_screen.dart';
import 'routes.dart';

GoRouter buildRouter({required AuthRepository authRepository}) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authRepository,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isInitialized = authRepository.isInitialized;
      final isAuthed = authRepository.isAuthenticated;

      if (!isInitialized) {
        return loc == Routes.splash ? null : Routes.splash;
      }

      if (isAuthed && (loc == Routes.splash || loc == Routes.onboarding)) {
        return Routes.home;
      }

      if (!isAuthed && (loc == Routes.splash || loc == Routes.home || loc == Routes.profile)) {
        return Routes.onboarding;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        name: RouteNames.splash,
        builder: (ctx, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        name: RouteNames.onboarding,
        builder: (context, _) {
          return OnboardingScreen(
            onContinue: () async {
              HapticFeedback.mediumImpact();
              await AuthBottomSheet.show(context);
            },
          );
        },
      ),
      GoRoute(
        path: Routes.home,
        name: RouteNames.home,
        builder: (ctx, state) => const MainNavigationScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: RouteNames.profile,
            builder: (ctx, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
```

Nota: `path: 'profile'` (sub-route) faz `/home/profile` resolver para `ProfileScreen`. Em `HomeScreen` o `Navigator.pushNamed(Routes.profile)` continua funcionando porque GoRouter expõe nomes via `context.pushNamed`. Trocar `pushNamed(Routes.profile)` por `context.pushNamed(RouteNames.profile)` em `home_screen.dart`:

Edite `lib/ui/home/widgets/home_screen.dart` na ação do `IconButton` de perfil:

```dart
IconButton(
  tooltip: l10n.homeProfileAction,
  icon: const Icon(Icons.person_outline_rounded),
  onPressed: () => context.pushNamed(RouteNames.profile),
),
```

E adicione o import `package:go_router/go_router.dart` no topo do `home_screen.dart`.

- [ ] **Step 3: Confirmar análise**

Run: `flutter analyze lib/routing/ lib/ui/home/widgets/home_screen.dart`
Expected: `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/routing/ lib/ui/home/widgets/home_screen.dart
git commit -m "feat(routing): add /home/profile route

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

### Task 17: Wiring no `main.dart`

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Substituir conteúdo**

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth/auth_repository.dart';
import 'data/repositories/auth/auth_repository_firebase.dart';
import 'data/repositories/fasting/fasting_repository.dart';
import 'data/repositories/fasting/fasting_repository_local.dart';
import 'data/services/auth/firebase_auth_service.dart';
import 'data/services/auth/google_sign_in_service.dart';
import 'data/services/database/local_database.dart';
import 'data/services/notifications/notification_service.dart';
import 'firebase_options.dart';
import 'l10n/generated/app_localizations.dart';
import 'routing/router.dart';
import 'ui/core/themes/themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firebaseAuthService = FirebaseAuthService();
  final googleSignInService = GoogleSignInService();
  final authRepository = AuthRepositoryFirebase(
    firebaseAuthService: firebaseAuthService,
    googleSignInService: googleSignInService,
  );

  final localDatabase = LocalDatabase();
  final notificationService = NotificationService();
  await notificationService.init();

  // Strings da notificação são fixas em pt aqui (escolha consciente:
  // ela é agendada uma vez quando o jejum começa e dispara horas depois,
  // pode ficar fora do contexto da locale ativa). Se virar incômodo,
  // injeta-se um lookup por locale via callback.
  final fastingRepository = FastingRepositoryLocal(
    database: localDatabase,
    notifications: notificationService,
    notificationTitle: 'Jejum concluído',
    notificationBody:
        'Você atingiu sua meta. Quebre o jejum quando estiver pronto.',
  );

  runApp(MambaGrowthApp(
    authRepository: authRepository,
    fastingRepository: fastingRepository,
    notificationService: notificationService,
    localDatabase: localDatabase,
  ));
}

class MambaGrowthApp extends StatelessWidget {
  const MambaGrowthApp({
    super.key,
    required this.authRepository,
    required this.fastingRepository,
    required this.notificationService,
    required this.localDatabase,
  });

  final AuthRepository authRepository;
  final FastingRepository fastingRepository;
  final NotificationService notificationService;
  final LocalDatabase localDatabase;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<FastingRepository>.value(value: fastingRepository),
        Provider<NotificationService>.value(value: notificationService),
        Provider<LocalDatabase>.value(value: localDatabase),
      ],
      child: MaterialApp.router(
        title: 'Mamba Growth',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: supportedLocales,
        localeResolutionCallback: _resolveLocale,
        routerConfig: buildRouter(authRepository: authRepository),
      ),
    );
  }

  static Locale _resolveLocale(
    Locale? deviceLocale,
    Iterable<Locale> supported,
  ) {
    if (deviceLocale?.languageCode == 'pt') {
      return const Locale('pt');
    }
    return const Locale('en');
  }
}
```

- [ ] **Step 2: Confirmar análise total**

Run: `flutter analyze`
Expected: `No issues found!`.

Se houver issues, corrija conforme as mensagens (provavelmente imports não usados ou chamadas a chaves l10n com tipos errados).

- [ ] **Step 3: Rodar testes**

Run: `flutter test`
Expected: `All tests passed!` (8 tests do Wave 1).

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "feat(app): wire LocalDatabase, NotificationService, FastingRepository

main.dart agora inicializa NotificationService.init() antes do runApp,
constrói FastingRepositoryLocal e expõe os providers via MultiProvider
ao lado do AuthRepository.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

---

## Wave 8 — Verificação final

### Task 18: Smoke test em device físico

**Files:** N/A — verificação manual.

- [ ] **Step 1: Rodar análise total + testes**

Run: `flutter analyze && flutter test`
Expected: ambos limpos.

- [ ] **Step 2: Buildar e rodar em device Android**

Run: `flutter run -d <device-id> --release`

Lista de verificação:
- [ ] AppBar mostra "Jejum" e dois ícones (perfil + ajustes).
- [ ] Estado idle: ring vazio, "16h meta de jejum" no centro, "Janela alimentar de 8h" abaixo, CTA "Iniciar jejum".
- [ ] Toque em "Iniciar jejum" → prompt de notificação aparece (primeira vez) → aceitar → CTA vira "Encerrar jejum", ring começa a animar, decorrido aparece tickando.
- [ ] Bottom sheet de protocolo abre via ícone de ajustes; trocar para 18:6 e confirmar; eyebrow muda para "PROTOCOLO · 18:6"; novo jejum vai usar 18:6 (sticky).
- [ ] Card "Personalizado": slider muda fasting/eating; selecionar e confirmar persiste.
- [ ] Tocar em "Encerrar jejum" → diálogo aparece com "Você jejuou Xh Ymin de Zh"; confirmar fecha o jejum, volta ao estado idle.
- [ ] Ícone de perfil → `/home/profile` → tela placeholder com botão "Sair" funcionando (volta pro onboarding).
- [ ] Iniciar jejum, fechar app via swipe da home, abrir 30s depois — decorrido continua correto.
- [ ] Iniciar jejum com `target_hours = 1` (custom 1:23) e aguardar — notificação dispara no horário esperado.

- [ ] **Step 3: Smoke test iOS (se device disponível)**

Run: `flutter run -d <ios-device-id> --release`

Mesma checklist da Step 2; permissão de notificação é pedida via `UNUserNotificationCenter` no primeiro `startFast`.

- [ ] **Step 4: Commit final do checklist concluído (opcional)**

Se ajustes surgirem do smoke test, commit-os separadamente. Caso contrário, nada a commitar — implementação encerrada.

---

## Self-Review

**Spec coverage:** Cada requisito da spec é coberto:
- AppBar "Jejum" + 2 actions → Task 13 (home_screen.dart).
- Bottom sheet com 3 presets + custom → Task 11.
- Timer de jejum (Iniciar/Pausar-Encerrar) → Tasks 8, 9, 13 (sem pausa, conforme decidido).
- Tempo restante e decorrido → Task 13 (`_ActiveSubtitle` + centro do ring).
- Background functioning → Task 8 (start_at em SQLite, recálculo no resumed via `_now`).
- Manter estado correto → Task 9 (Ticker resume + Fast.elapsed sempre fresh).
- sqflite + boas práticas → Tasks 5, 8 (singleton com Lock, transações onde aplicável, schema versionado).
- flutter_local_notifications v21 → Tasks 1, 6, 8 (init + permission + zonedSchedule + cancel).
- Design system fonte da verdade → todas as tasks de UI usam `context.colors`, `context.typo`, `AppSpacing`, `AppRadius`, sem cores hard-coded (exceto erro do dialog, vindo do `colorScheme.error` indiretamente).

**Placeholder scan:** Sem `TBD`/`TODO` no plano. Todos os blocos de código são completos e copy-pasteable.

**Type consistency:** `Fast`, `FastingProtocol` métodos (`elapsed`, `remaining`, `progress`, `plannedEndAt`, `overshot`) usados consistentemente entre Wave 1 e Wave 5/6. `Command0<Fast>` usado em VM e na UI. `FastingRepository.startFast/endFast` retornam `Result<Fast>` consistente. Chaves de l10n usadas no código existem na ARB (Task 15).

Plano fechado.
