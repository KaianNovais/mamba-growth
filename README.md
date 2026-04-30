# mamba-growth

Tracker calmo de jejum e calorias. Sem ruído, sem julgamento — só números honestos pra transformar consistência em progresso.

## Como rodar

Precisa: Flutter 3.x, Android SDK, Java 17.

```bash
flutter pub get
flutter run
```

Pra Firebase funcionar localmente, coloque seu `google-services.json` em `android/app/`. Sem o arquivo o app ainda compila (o plugin é aplicado só se ele existir), mas o login Google não funciona.

## Stack

- **Flutter / Dart** — app inteiro
- **Firebase Auth + Google Sign-In** — login
- **SQLite (sqflite)** — guarda jejuns e refeições no aparelho
- **flutter_local_notifications** — avisa quando o jejum acaba

## Arquitetura

MVVM com camadas separadas:

```
lib/
├── data/      # repositories + services (Firebase, SQLite, notificações)
├── domain/    # models puros (Fast, Meal, AuthUser)
├── ui/        # feature folders (home, fasting, meals, profile…)
│   └── <feature>/
│       ├── view_models/   # ChangeNotifier
│       └── widgets/       # telas + componentes
├── routing/   # go_router
└── utils/     # Result<T>, Command
```

- ViewModels são `ChangeNotifier` e expõem estado pronto pra UI.
- Repositories devolvem `Result<T>` (Ok ou Error) em vez de soltar exception.
- Provider injeta tudo na raiz, no `main.dart`.

## Decisões técnicas

- **Offline-first.** Tudo que importa fica em SQLite local. Firebase só pra login.
- **`Result<T>` no contrato Repository → ViewModel.** Erro vira parte do retorno, não exception solta.
- **Provider em vez de Riverpod/Bloc.** Menos código pra um app desse tamanho.
- **go_router.** Rotas declarativas e redirect de auth num lugar só.
- **i18n desde o começo.** PT e EN, decididos pela locale do aparelho.

## Bibliotecas

- `provider` — DI e estado
- `go_router` — navegação
- `firebase_core`, `firebase_auth`, `google_sign_in` — login
- `sqflite` + `sqflite_common_ffi` (testes) — banco local
- `flutter_local_notifications` + `timezone` — notificação de fim de jejum
- `intl` — datas e números localizados
- `confetti` — celebração quando completa um jejum
- `package_info_plus` — versão exibida no perfil

## Trade-offs

- **SQLite local, sem sync entre aparelhos.** Mais simples e privado. Custo: trocou de celular, perdeu o histórico.
- **ChangeNotifier sem `freezed`.** Anda mais rápido. Custo: estado não é imutável de verdade.
- **Provider em vez de Riverpod.** Curva mais baixa. Custo: menos checagem em compile-time.
- **CI gera APK debug, não release assinado.** Não precisa de secret. Custo: APK do CI não dá pra distribuir.

## O que melhoraria com mais tempo

- Sync opcional via Firestore, mantendo offline-first como padrão.
- Mais testes de widget e uma suíte de integração.
- iOS — hoje só Android está polido.
- APK release assinado no CI por tag `v*`.
- Uso de IA para tirar a foto da comida e calcular automaticamente as calorias.
- Implementação de assinatura para ser rentável o app.

## Tempo gasto

30h
