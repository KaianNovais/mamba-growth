# Meals (Calorias) Feature — Design Spec

**Data:** 2026-04-29
**Autor:** Claude (com kaiannovais)
**Status:** Aprovado em brainstorming; aguardando revisão da spec antes do plano

## Contexto

A aba **Refeições** hoje é placeholder (`meals_screen.dart` com `EmptyFeatureState`). Esta spec define a feature de registro de calorias: o usuário registra refeições (nome + calorias, horário automático), edita/exclui, e visualiza o consumo do dia em um anel de progresso espelhando a estética do Home.

A tela de **Perfil** ganha uma seção para definir/remover a meta diária de calorias.

## Decisões de produto (alinhadas em brainstorming)

1. **Meta opcional.** Definida no Perfil. Com meta → anel + "X kcal restantes" / "X kcal acima da meta". Sem meta → hero numérico do total + hint "defina uma meta no perfil".
2. **Horário sempre automático.** `DateTime.now()` no momento do salvar. Não editável (alinha com filosofia "números honestos").
3. **Escopo: só hoje na tela.** Refeições passadas ficam no banco mas a tela atual mostra apenas o dia corrente. Histórico por dia fica como camada futura.
4. **Ultrapassar a meta:** transição visual sóbria — anel preenche em accent (`#D4A24C`), arco extra em âmbar quente (`#E08A4C`). Sem vermelho-alarme. Subtítulo neutro ("X acima da meta", sem "!").
5. **Edição:** nome e calorias editáveis. Horário NÃO editável (decisão 2). Exclusão via menu `⋮` no card, com confirmação + snackbar Desfazer (4s).
6. **Consistência visual:** `FastingRing` é refatorado para `ProgressRing` genérico em `core/widgets/`, parametrizado por cor. Reutilizado pelo Home e pelo Meals.

## Stack

- **Estado:** `provider` + `ChangeNotifier` + `Command0/Command1` (mesmo padrão do fasting).
- **Persistência:** `sqflite` (já no projeto) — nova tabela `meals`, migration v1 → v2.
- **Settings:** tabela `settings` existente, novo key `daily_calorie_goal`.

## Arquitetura

### Camadas

```
lib/
  data/
    services/
      database/
        local_database.dart           # bump _version 1→2 + onUpgrade
    repositories/
      meals/
        meals_repository.dart         # abstract ChangeNotifier
        meals_repository_local.dart   # SQLite-backed, cache + broadcast
  domain/
    models/
      meal.dart                       # @immutable
  ui/
    core/
      widgets/
        progress_ring.dart            # ex-FastingRing, parametrizado
    home/widgets/
      home_screen.dart                # passa a importar ProgressRing
    meals/
      view_models/
        meals_view_model.dart
      widgets/
        meals_screen.dart
        meal_list_item.dart
        add_meal_sheet.dart
    profile/
      widgets/
        profile_screen.dart           # ganha seção "Calorias"
        calorie_goal_sheet.dart
```

### Repositórios separados

`MealsRepository` é independente do `FastingRepository`. Features ortogonais — acoplamento seria red flag.

### Refator do `FastingRing` → `ProgressRing`

```dart
// lib/ui/core/widgets/progress_ring.dart
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    required this.size,
    this.color,           // default = accent (theme)
    this.overflowColor,   // arco extra quando progress > 1
    this.child,
  });
  final double progress;        // 0..∞ (clamp interno do paint)
  final double size;
  final Color? color;
  final Color? overflowColor;
  final Widget? child;
}
```

`fasting_ring.dart` é deletado e o Home importa `ProgressRing` do `core/widgets/`. Comportamento atual preservado byte-a-byte (mesmo CustomPainter, só recebe `color` opcional).

## Modelo de dados

### `Meal`

```dart
@immutable
class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.calories,
    required this.eatenAt,
  });

  final int id;
  final String name;          // não vazio, trim, 1..60 chars
  final int calories;         // 1..9999
  final DateTime eatenAt;
}
```

Sem macros. Sem unidades alternativas. Sem campos opcionais.

### Schema SQLite

```sql
CREATE TABLE meals (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  name        TEXT    NOT NULL,
  calories    INTEGER NOT NULL CHECK (calories > 0),
  eaten_at    INTEGER NOT NULL          -- millisecondsSinceEpoch
);

CREATE INDEX idx_meals_eaten_at ON meals(eaten_at DESC);
```

### Migration

```dart
// LocalDatabase: _version = 2
onUpgrade: (db, from, to) async {
  if (from < 2) {
    await db.execute('CREATE TABLE meals (...)');
    await db.execute('CREATE INDEX idx_meals_eaten_at (...)');
  }
}
```

A tabela `fasts` permanece intocada. Usuários atuais não perdem dados.

### Meta diária — `settings`

- key: `daily_calorie_goal`
- value: string com o número (ex: `"2000"`); ausência da row = sem meta
- range válido: 500..9999
- nenhuma migration necessária — usa a tabela existente

## Repositório

### Contrato

```dart
abstract class MealsRepository extends ChangeNotifier {
  bool get isInitialized;

  /// Stream com replay-on-subscribe das refeições do dia [day].
  /// Re-emite ao adicionar/atualizar/excluir.
  Stream<List<Meal>> watchMealsForDay(DateTime day);

  /// Listenable da meta atual (null = sem meta).
  ValueListenable<int?> get goalListenable;
  int? get currentGoal;

  Future<Result<Meal>> addMeal({required String name, required int calories});
  Future<Result<Meal>> updateMeal(Meal meal);
  Future<Result<void>> deleteMeal(int id);

  Future<void> setGoal(int kcal);
  Future<void> clearGoal();
}
```

### Implementação local

- Bootstrap: lê goal de `settings`, lê refeições de hoje, emite no stream.
- Cache em memória das refeições do dia atual (`_todayCache`).
- `_todayController` é `StreamController<List<Meal>>.broadcast()`. `watchMealsForDay` faz `yield _cache; yield* controller.stream` — replay-on-subscribe (mesmo padrão do `watchCompletedFasts`).
- Day-rollover: ao chamar `watchMealsForDay(day)`, repo guarda `_currentDay`; se `day != _currentDay`, refaz a query e emite novamente.
- `addMeal`: insere com `eatenAt = DateTime.now()`. Se `now` cai em outro dia que `_currentDay`, ainda dispara update na stream (caller decide se renderiza).
- `setGoal/clearGoal`: upsert/delete na `settings`, atualiza `goalListenable`.

## ViewModel

```dart
class MealsViewModel extends ChangeNotifier with WidgetsBindingObserver {
  MealsViewModel({required MealsRepository repository});

  bool get isInitialized;
  DateTime get day;                // dia "âncora", default = today()
  List<Meal> get meals;            // refeições do dia
  int get totalKcal;               // soma derivada
  int? get goal;                   // espelha repo.goalListenable
  double get progress;             // total / goal, 0 se goal null
  bool get overGoal;               // total > goal && goal != null

  Command1<Meal, ({String name, int calories})> addMeal;
  Command1<Meal, Meal> updateMeal;
  Command1<void, int> deleteMeal;

  Future<void> undoDelete(Meal meal);  // re-insert do snackbar
}
```

- `WidgetsBindingObserver.didChangeAppLifecycleState`: ao `resumed`, recomputa `day = DateTime(now.year, now.month, now.day)` — cobre o caso raro de o app ficar aberto cruzando meia-noite. Sem ticker 1Hz.
- `Command1<T, A>` já existe em `utils/command.dart` — usa direto.

## UI

### `MealsScreen` — layout

Estrutura externa: `Scaffold` + `AppBar` (matching Home) + `SafeArea(top: false)` + `Column`:

```
[Eyebrow caption]                       — "HOJE · META 2.000 KCAL" (uppercase, letterSpacing 2.4)
[Spacing xl]
[ProgressRing 240–280px]                — kcal grande no centro (numericLarge),
                                          "kcal" caption logo abaixo
[Spacing xl]
[Subtitle Column]                       — "750 kcal restantes" / "180 acima da meta"
                                          + "de 2.000 kcal" (textDim)
[Spacing xl]
[Divider sutil borderDim]
[Spacing lg]
[List eyebrow]                          — "HOJE · 3 REFEIÇÕES"
[Spacing md]
[ListView de MealListItem]              — separados por SizedBox md
[Spacing xl]
[FilledButton "Adicionar refeição"]     — full-width 56h, accent bg, ícone +
```

A tela inteira é um `SingleChildScrollView` com `Column`. Lista interna usa `Column` (não `ListView` aninhado) com itens construídos a partir do `vm.meals`.

### Estados

- **Sem meta:** anel some, hero `numericDisplay 56pt` com total kcal centralizado. Subtitle vira hint clicável "Defina uma meta no perfil para acompanhar seu progresso" → `pushNamed(profile)`.
- **Sem refeições hoje (com meta):** anel mostra `0` no centro com `progress = 0`. Lista é substituída por mini empty state inline ("Nenhuma refeição registrada hoje. Toque no botão abaixo..."). O `EmptyFeatureState` existente é reaproveitado.
- **Sem refeições + sem meta:** hero "0 kcal" + hint da meta + mini empty state da lista.
- **Acima da meta:** anel preenche 100% em accent + arco sobressalente em `overflowColor`. Subtitle "180 kcal acima da meta · 2.180 / 2.000".

### Cor "âmbar quente" — overflow

- Hex: `#E08A4C`
- Contraste sobre `bg #0A0A0B`: 4.7:1 (AA grande / próximo de AAA texto pequeno)
- Não conflita com semântica de erro (que não existe no app hoje).
- Atende `feedback_dark_mode_contrast.md` (preferência por contraste alto em tons mutados).

### `MealListItem`

Card `surface` + `border borderDim` + `borderRadius lg`. Conteúdo:

```
Row:
  Expanded:
    Column:
      Text(name, titleMedium, color text)
      Text("${calories} kcal", numericMedium, color text)
  Text(time HH:mm, numericSmall, textDim)
  IconButton ⋮ (size 18, hit area 48)
```

- Card inteiro `InkWell` → abre `AddMealSheet` em modo edição.
- Botão `⋮` (PopupMenuButton) com itens "Editar" / "Excluir" (excluir em vermelho semântico — única ocorrência de vermelho no app, justificada pelo contexto destrutivo). O botão usa seu próprio `Material/InkWell` interno; o tap nele NÃO deve propagar pra o `InkWell` do card. Implementação: `PopupMenuButton` em `Material(type: transparency)` dentro de uma `SizedBox` que captura o gesto, então o tap fora do botão (no resto do card) cai no `InkWell` externo.
- Excluir → dialog de confirmação → snackbar "Refeição removida · DESFAZER" (4s).

### `AddMealSheet`

`showModalBottomSheet` com `isScrollControlled: true`. Sobe junto com `viewInsets.bottom` do teclado.

Conteúdo:

```
[Drag handle]
[Title "Nova refeição" / "Editar refeição"]
[Subtitle "Hoje · HH:mm"]            — congela ao abrir, não atualiza
[Input "Nome" + counter "n/60"]
[Input "Calorias" + suffix "kcal", numeric keyboard]
[FilledButton "Salvar" / "Salvar alterações"] — disabled se inválido
[TextButton "Cancelar"]
```

Validação:
- Nome: trim, 1..60 chars. Erro inline on `blur` (regra `inline-validation`).
- Calorias: parsing seguro, 1..9999. Teclado `TextInputType.number`.
- Submit: spinner inline → fecha → `SnackBar` "Refeição adicionada".
- Modo edição: pré-preenche, mostra "Salvar alterações". Não tem botão excluir aqui (vive no menu `⋮`).

### `ProfileScreen` — seção "Calorias"

Substitui parte do `EmptyFeatureState` placeholder. O sign-out continua no rodapé.

```
[Avatar + nome + email]                — usa AuthRepository.currentUser
[Divider]
[Eyebrow "CALORIAS"]
[Card tappable]
  - com meta:    "Meta diária" / "{kcal} kcal por dia"  → "Definir »"
  - sem meta:    "Meta diária" / "Acompanhe seu progresso diário" → "Definir »"
[Spacer]
[OutlinedButton "Sair"]                — já existe
```

Tap no card abre `CalorieGoalSheet`.

### `CalorieGoalSheet`

```
[Drag handle]
[Title "Meta diária"]
[Subtitle "Quantas calorias você quer consumir por dia?"]
[Input numérico "Calorias" + suffix "kcal", numericLarge mono]
[Chips "1500 · 2000 · 2500"]          — preenchem o input ao toque
[FilledButton "Salvar"]
[TextButton "Remover meta"]            — só aparece se já existe meta
```

Validação: 500..9999.

## L10n

Strings novas (PT/EN). Convenção `meals*` / `mealSheet*` / `profileGoal*`. ICU para plurais e placeholders. Lista completa nas seções 3 e 4 da discussão de design — vai pro arquivo `app_localizations.arb`/`app_localizations_pt.dart` na implementação.

## Acessibilidade

- **`ProgressRing`** envolto em `Semantics(label: "X kcal de Y. Z restantes" | "X kcal. Z acima da meta")`.
- **`MealListItem`** vira `Semantics(button: true, label: "Almoço, 620 kcal, registrado às 12:45. Toque para editar")`.
- **Touch targets** ≥ 44pt em tudo (cards são 56+; `IconButton` default já é 48).
- **Inputs** com label visível (não placeholder-only), erro logo abaixo, `keyboardType` semântico.
- **Reduced motion**: anel anima com `AnimatedSwitcher` 200ms ease-out; respeitamos `MediaQuery.disableAnimations` para 0ms.
- **Haptics**: `HapticFeedback.lightImpact()` ao salvar refeição (consistência com Home).
- **Dark-mode contrast** validado por par fg/bg (regra `color-accessible-pairs`).

## Integração com fasting

**Decisão explícita:** registrar refeição durante um jejum ativo é permitido sem aviso. O app não faz julgamento — quem decide se viola o protocolo é o usuário. Não há cross-talk entre features.

## Testes

```
test/data/repositories/meals/
  meals_repository_local_test.dart    # in-memory sqflite via sqflite_common_ffi
                                       - addMeal persiste com eatenAt = now
                                       - watchMealsForDay filtra dia
                                       - delete remove
                                       - setGoal/clearGoal idempotente
                                       - migration v1→v2 cria tabela

test/ui/meals/view_models/
  meals_view_model_test.dart          # FakeMealsRepository
                                       - estado loading → loaded
                                       - totalKcal derivado
                                       - addMeal → command success → meals atualiza
                                       - deleteMeal + undoDelete restaura
                                       - day-rollover via didChangeAppLifecycleState

test/ui/meals/widgets/
  meals_screen_test.dart              # widget tests
                                       - mostra anel quando há meta
                                       - mostra "X acima" quando estoura
                                       - mostra hero numérico quando sem meta
                                       - empty state quando lista vazia
                                       - botão "Adicionar" abre AddMealSheet

  add_meal_sheet_test.dart            - submit desabilitado com nome vazio
                                       - submit desabilitado com kcal=0
                                       - submit chama VM com valores corretos
                                       - modo edição pré-preenche

  meal_list_item_test.dart            - card abre sheet edição
                                       - menu ⋮ exibe "Editar"/"Excluir"
                                       - exclusão pede confirmação

test/ui/profile/widgets/
  profile_screen_test.dart            - seção "Calorias" mostra meta atual
                                       - sem meta exibe "Definir"
                                       - tap abre CalorieGoalSheet

  calorie_goal_sheet_test.dart        - chips preenchem input
                                       - validação 500-9999
                                       - "Remover meta" só aparece com meta
```

Padrão de fakes herdado dos testes existentes (`home_view_model_test.dart`).

## Tasks de implementação (rascunho — vai pro plano)

1. Refator: `FastingRing` → `ProgressRing` em `core/widgets/`, com cor parametrizada. Atualizar Home. Garantir `flutter test` verde.
2. Migration v1→v2 + tabela `meals` + `MealsRepository` + testes do repo.
3. `MealsViewModel` + `Command1` (se ainda não existe) + testes do VM.
4. `MealsScreen` + `MealListItem` + `AddMealSheet` + testes de widget.
5. Seção "Calorias" no Perfil + `CalorieGoalSheet` + testes.
6. L10n PT/EN final.
7. QA manual: rodar app, registrar/editar/excluir, undo, definir/limpar meta, rollover, teclado.

## Risks & open questions

- **Day-rollover sem ticker:** se o usuário deixar o app aberto cruzando meia-noite sem mexer, a tela mostra refeições do dia anterior até `resumed`. Aceito: caso raríssimo + o `resumed` cobre o uso real (abrir o app pela manhã).
- **Sem hist por dia agora:** decidido escopo "só hoje". Esta spec não cobre histórico de calorias por dia. Pode virar feature futura nas abas Histórico ou Stats.
- **Refator de `FastingRing`:** muda imports do Home + arquivo da `widget_test.dart` se ele referenciar `FastingRing` (verificar antes do plano). Risco baixo; se houver, é busca-substitui.
