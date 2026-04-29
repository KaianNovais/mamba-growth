# Home (Jejum) Feature — Design Spec

**Data:** 2026-04-29
**Autor:** Claude (com kaiannovais)
**Status:** Aprovado seções 1–5; teste reduzido (seção 6.2 revisada)

## Contexto

A aba Home hoje é placeholder vazio (`home_screen.dart` com `EmptyFeatureState`). Esta spec define a feature core do app: timer de jejum intermitente com seleção de protocolo, persistência em SQLite e notificação de fim via `flutter_local_notifications`.

## Decisões de produto (alinhadas em brainstorming)

1. **Background:** persistência simples — `start_at` salvo no SQLite; ao reabrir o app recalculamos `elapsed = now − start_at`. Sem foreground service.
2. **Pausar/encerrar:** apenas "Encerrar" (com confirmação). Sem pausa, sem editar `start_at`.
3. **Histórico:** jejuns encerrados são salvos numa tabela `fasts`, prontos pra alimentar a aba Histórico (placeholder hoje).
4. **Protocolo customizado:** par `fasting:eating` que soma 24h (ex: 20:4).
5. **Timer display:** ring de progresso com decorrido no centro + restante embaixo.
6. **Estado idle (sem jejum ativo):** mesmo ring, vazio, com CTA "Iniciar jejum" — continuidade visual ao começar.
7. **Default + sticky:** 16:8 como padrão; última escolha do usuário persiste.
8. **Botão de perfil:** rota `/profile` + `ProfileScreen` placeholder com `EmptyFeatureState` e logout dentro.
9. **Permissão de notificação:** pedida no primeiro toque em "Iniciar jejum".

## Stack

- **Estado:** `provider` + `ChangeNotifier` + `Command` (mesmo padrão do auth).
- **Persistência:** `sqflite: ^2.4.2+1` + `path` + `synchronized`.
- **Notificação:** `flutter_local_notifications: ^21.0.0` + `timezone`.

## Arquitetura

### Camadas

```
lib/
  data/
    services/
      database/
        local_database.dart           # singleton sqflite, Lock, schema
      notifications/
        notification_service.dart     # wrapper flutter_local_notifications
    repositories/
      fasting/
        fasting_repository.dart       # abstract ChangeNotifier
        fasting_repository_local.dart # SQLite-backed
  domain/
    models/
      fast.dart
      fasting_protocol.dart
  ui/
    home/
      view_models/
        home_view_model.dart
      widgets/
        home_screen.dart              # substitui o atual
        fasting_ring.dart             # CustomPainter
        protocol_bottom_sheet.dart
        end_fast_dialog.dart
    profile/
      widgets/
        profile_screen.dart           # placeholder + signOut
  routing/
    routes.dart                       # adiciona /profile
    router.dart                       # adiciona rota /profile
```

`main.dart` ganha providers extras: `LocalDatabase`, `NotificationService`, `FastingRepository` (todos antes do `MaterialApp.router`).

### Schema SQLite (versão 1)

```sql
CREATE TABLE fasts (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  start_at      INTEGER NOT NULL,        -- millisecondsSinceEpoch UTC
  end_at        INTEGER,                 -- NULL = ativo
  target_hours  INTEGER NOT NULL,
  eating_hours  INTEGER NOT NULL,
  completed     INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX idx_fasts_active ON fasts(end_at) WHERE end_at IS NULL;
CREATE INDEX idx_fasts_start  ON fasts(start_at DESC);

CREATE TABLE settings (
  key   TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
```

**Invariantes:**
- No máximo um registro com `end_at IS NULL` (enforçado no repo, não no banco).
- `completed = 1` quando `(end_at - start_at) >= target_hours * 3600 * 1000`, gravado uma vez no encerrar.
- `selected_protocol_id` em `settings` (string: `"12:12"`, `"16:8"`, `"18:6"`, `"custom:N:M"`).

**Configuração:**
- `singleInstance: true`.
- `onConfigure`: `PRAGMA foreign_keys = ON` (futuro-proofing).
- Singleton com `synchronized.Lock` (padrão da doc tekartik/sqflite).

### Modelos de domínio

```dart
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

  static const presets = [
    FastingProtocol(id: '12:12', fastingHours: 12, eatingHours: 12, isCustom: false),
    FastingProtocol(id: '16:8',  fastingHours: 16, eatingHours:  8, isCustom: false),
    FastingProtocol(id: '18:6',  fastingHours: 18, eatingHours:  6, isCustom: false),
  ];
  static const defaultProtocol = presets[1];
}

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
  Duration elapsed(DateTime now) => now.difference(startAt);
  Duration get target => Duration(hours: targetHours);
  Duration remaining(DateTime now) {
    final r = target - elapsed(now);
    return r.isNegative ? Duration.zero : r;
  }
  double progress(DateTime now) =>
      (elapsed(now).inSeconds / target.inSeconds).clamp(0.0, 1.0);
}
```

Timestamps como `INTEGER` (millisecondsSinceEpoch UTC), conversão pra `DateTime` no `fromMap`/`toMap`.

### `FastingRepository` (interface)

```dart
abstract class FastingRepository extends ChangeNotifier {
  Fast? get activeFast;
  FastingProtocol get selectedProtocol;
  bool get isInitialized;

  Future<Result<Fast>> startFast();
  Future<Result<Fast>> endFast();
  Future<void> setProtocol(FastingProtocol);
}
```

### Ciclo de vida do `FastingRepositoryLocal`

1. **Construtor:** dispara `_load()`. `isInitialized = false` até completar.
2. **`_load()`:** lê `selected_protocol_id` (default 16:8), faz `SELECT * FROM fasts WHERE end_at IS NULL LIMIT 1`, marca `isInitialized = true`, `notifyListeners()`.
3. **`startFast()`:**
   - Re-entrancy guard se já há ativo.
   - `INSERT` com `start_at = now`, `end_at = NULL`, hours do protocolo selecionado.
   - Pede permissão de notificação (one-shot, idempotente). Agenda `zonedSchedule(id: 1, scheduledDate: tz.TZDateTime.from(start + target, tz.local), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle)` se concedida.
   - Atualiza `_activeFast`, `notifyListeners()`.
4. **`endFast()`:**
   - `UPDATE fasts SET end_at = now, completed = (...) WHERE id = ?`.
   - `cancel(1)`.
   - `_activeFast = null`, `notifyListeners()`.
5. **`setProtocol(p)`:** `INSERT OR REPLACE INTO settings`, `notifyListeners()`.

Múltiplos statements rodam em `db.transaction((txn) async { ... })`.

### `HomeViewModel`

- `extends ChangeNotifier with WidgetsBindingObserver`.
- `Timer.periodic(1s)` enquanto `activeFast != null` e app `resumed`. Ticker só atualiza `_now = DateTime.now()` e dispara `notifyListeners`.
- `Command0<Fast> startFast` e `Command0<Fast> endFast` reusam `utils/command.dart`.
- `didChangeAppLifecycleState`: para o ticker em `paused`, retoma em `resumed`.
- Cálculo de elapsed/remaining mora no modelo `Fast` — ticker apenas dispara repaint, não computa nada. Por isso fechar/reabrir devolve estado correto: `_now` é sempre fresco.

### `NotificationService`

- Inicializa `FlutterLocalNotificationsPlugin` + `tz.initializeTimeZones()` em `main.dart` antes de `runApp`.
- `requestPermissionIfNeeded()`: Android via `requestNotificationsPermission()` + `requestExactAlarmsPermission()`; iOS via `requestPermissions(alert: true, badge: true, sound: true)`. Retorna `bool`.
- `scheduleFastEnd({required DateTime endAt, required String title, required String body})`: `zonedSchedule(id: 1, scheduledDate: tz.TZDateTime.from(endAt, tz.local), androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle)`.
- `cancelFastEnd()`: `cancel(1)`.
- Canal Android: `mamba_growth_fasting`, importance high.

## UX/UI

### `HomeScreen` (estrutura)

AppBar `Jejum` + dois actions: `IconButton` perfil → `pushNamed('profile')`, `IconButton` ajustes → `ProtocolBottomSheet.show(context)`.

Body central:
- **Eyebrow:** caption textDim, "Protocolo · 16:8" (ativo) ou "Próximo protocolo · 16:8" (idle).
- **Ring** (`FastingRing`, 240×240, clamp 200..280): diâmetro responsivo a `MediaQuery.size.width * 0.62`. Track stroke 6 `colors.borderDim`, progress arc stroke 6 `colors.accent`, `StrokeCap.round`, começa às 12h, sentido horário. Animação de progress via `TweenAnimationBuilder` 280ms `easeOutCubic` — suaviza tick 1Hz.
- **Centro do ring:**
  - Ativo: número grande monoespaçado (`GeistMono`, ~36sp, accent) com `HHh MMmin`, label caption "decorrido".
  - Idle: `targetHours` + "h" grande (text), label caption "meta de jejum".
- **Subtítulo abaixo do ring:**
  - Ativo: "Termina em **1h 28min**" (bodyLarge text) + "às **18:42**" (caption textDim). Quando passa do alvo: "**Meta atingida** · há 23min" (accent).
  - Idle: "Janela alimentar de **8h**" (bodyMedium textDim).
- **CTA único:** `FilledButton` largura total, altura 56, radius `AppRadius.lg`. Label troca entre "Iniciar jejum" (accent) e "Encerrar jejum" (`colors.surface2`). Loading via `CircularProgressIndicator` 18×18.
- `RepaintBoundary` envolvendo o ring isola repaint 1Hz do resto da tela.

### `ProtocolBottomSheet`

Reusa `bottomSheetTheme` (já no `app_theme.dart`). Drag handle, headline "Protocolo de jejum", subtitle textDim.

3 cards de presets (1/3 da largura cada): `12:12`, `16:8`, `18:6` com sub-label `iniciante`/`popular`/`avançado`. Selecionado: borda `colors.accent` 1.5px + fundo `colors.accent.withValues(alpha: 0.08)`. `HapticFeedback.selectionClick()` ao trocar.

Card "Personalizado" largura total, expande inline com `Slider` de jejum (1..23h) e janela alimentar derivada (`24 − fasting`). Sub-label live: "20h jejum · 4h alimentação".

`FilledButton` "Selecionar protocolo" no rodapé — habilita só quando muda. Estado é local no sheet (`StatefulWidget`); commita no `repo.setProtocol` ao confirmar.

### `EndFastDialog`

Reusa `dialogTheme`. Título "Encerrar jejum?". Corpo: "Você jejuou 14h 32min de 16h. Sua progressão será salva no histórico." (mensagem muda quando passa do alvo: "Você superou sua meta em 23min · ótimo trabalho.").

`Cancelar` (TextButton accent) | `Encerrar` (FilledButton `colors.error`). `HapticFeedback.mediumImpact()` ao confirmar.

### `ProfileScreen` (placeholder)

`EmptyFeatureState` com `Icons.person_outline_rounded`, eyebrow "Perfil", título "Em breve", subtitle. `OutlinedButton` "Sair" no rodapé executando `repo.signOut()`. Logout sai da AppBar do Home (que tinha hoje) e vai pra cá.

### Acessibilidade

- `Semantics` no ring com label completo ("Jejum 14 horas e 32 minutos. Faltam 1 hora e 28 minutos para a meta de 16 horas.").
- Tooltips nos `IconButton` da AppBar.
- Contraste já garantido pelo design system (memória registrada de AAA em texto muted).

### L10n

Adicionar em `app_pt.arb` e `app_en.arb`:

- `homeFastingTitle` ("Jejum" / "Fasting")
- `homeProfileAction`, `homeProtocolAction`
- `homeStartFast`, `homeEndFast`
- `homeElapsedLabel` ("decorrido" / "elapsed")
- `homeFastingTargetLabel` ("meta de jejum" / "fasting target")
- `homeEndsAt({time})` ("às {time}" / "at {time}")
- `homeEndsIn({duration})`, `homeGoalReached`, `homeGoalReachedAgo({duration})`
- `homeEatingWindow({hours})` ("Janela alimentar de {hours}h")
- `homeEndDialogTitle`, `homeEndDialogBody({elapsed, target})`, `homeEndDialogCancel`, `homeEndDialogConfirm`, `homeEndDialogSurpassed({over})`
- `homeProtocolSheetTitle`, `homeProtocolSheetSubtitle`, `homeProtocolBeginner`, `homeProtocolPopular`, `homeProtocolAdvanced`, `homeProtocolCustom`, `homeProtocolCustomLabel({fast, eat})`, `homeProtocolConfirm`
- `homeNotificationFastEndTitle`, `homeNotificationFastEndBody`
- `homeNotificationsDeniedToast`
- `profileTitle`, `profileEmptyTitle`, `profileEmptySubtitle`, `profileSignOut`

## Plano de migração

Ordem de implementação (top-down, dependências primeiro):

1. **`pubspec.yaml`:** `sqflite: ^2.4.2+1`, `path: ^1.9.0`, `synchronized: ^3.3.0+3`, `flutter_local_notifications: ^21.0.0`, `timezone: ^0.10.0`. `flutter pub get`.
2. **Plataformas:**
   - **Android `AndroidManifest.xml`:** permissões `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`. Receivers `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver` (recomendados pelo plugin).
   - **iOS `AppDelegate.swift`:** `UNUserNotificationCenter.current().delegate = self` no `didFinishLaunchingWithOptions`.
3. **Domínio:** `fasting_protocol.dart`, `fast.dart`.
4. **Serviços data:** `local_database.dart`, `notification_service.dart`.
5. **Repository:** abstract + impl.
6. **`main.dart`:** instanciação + `MultiProvider`.
7. **ViewModel:** `home_view_model.dart`.
8. **UI:** `fasting_ring.dart` → `protocol_bottom_sheet.dart` → `end_fast_dialog.dart` → `home_screen.dart` (substitui o atual) → `profile_screen.dart`.
9. **Routing:** `/profile` em `routes.dart` e `router.dart`.
10. **L10n:** chaves novas + geração automática.

## Testes

Um arquivo só: `test/domain/fasting_test.dart`. `flutter_test` puro, sem mocks, sem ffi, sem widget tests. Cobre `FastingProtocol` (default + soma 24h dos presets) e `Fast` (`elapsed`, `remaining`, `progress`, `isActive`). Edge case "passou da meta" incluído.

Validação manual em device físico para:
- Notificação real de fim de jejum.
- Estado correto ao fechar/reabrir o app.
- Permissão negada não trava o jejum.

## Riscos

| Risco | Mitigação |
|---|---|
| Permissão de exact alarm negada | Fallback `AndroidScheduleMode.inexactAllowWhileIdle` |
| Mudança de fuso durante jejum | `start_at` em UTC; reagendar no `resumed` se `timeZoneOffset` mudou (v2 opcional) |
| App matado durante jejum | `exactAllowWhileIdle` + boot receiver; estado vive no SQLite |
| Rebuilds excessivos no tick 1Hz | `RepaintBoundary` no ring, `context.select` para campos pontuais do VM |
| UI antes de `isInitialized` | Skeleton (ring cinza, CTA disabled) enquanto carrega |

## Memórias relevantes

- **Dark mode AAA contraste:** já satisfeito pelo design system existente (cores `text`/`textDim`/`textDimmer` em `AppColors.dark`).
- **Verificar antes de deletar:** novos arquivos de teste serão *criados*, nunca substituem existentes — `git show`/Read antes de qualquer remoção.
