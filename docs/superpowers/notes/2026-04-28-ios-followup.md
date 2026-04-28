# iOS follow-up — Firebase Auth

Lista de pendências para validar/finalizar o auth flow no iOS. **Pré-requisito:** ambiente macOS com Xcode.

## Estado atual (2026-04-28)

- `ios/Runner/GoogleService-Info.plist` **NÃO está presente** no repo. O `firebase.json` lista uma `appId` para iOS, então o projeto Firebase já tem o app iOS registrado, mas o arquivo de configuração não foi baixado/comitado.
- Sem o plist, builds iOS vão falhar ao inicializar Firebase em runtime.
- Sem o `REVERSED_CLIENT_ID` registrado em `Info.plist`, Google Sign-In não consegue completar o callback OAuth.

## Passos quando estiver no macOS

1. **Baixar o `GoogleService-Info.plist`** rodando `flutterfire configure` na raiz do repo (selecionar apenas iOS para evitar regerar Android), OU baixar manualmente do Firebase Console → Project settings → "Your apps" → app iOS → `GoogleService-Info.plist`.
2. Mover/colar o arquivo em `ios/Runner/GoogleService-Info.plist` e adicioná-lo ao target `Runner` no Xcode (`File → Add Files to "Runner"…` com "Copy items if needed" desmarcado e o target `Runner` marcado).
3. Em `ios/Runner/Info.plist`, garantir que existe um bloco `CFBundleURLTypes` registrando o `REVERSED_CLIENT_ID` do Firebase como URL scheme:

   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>{{REVERSED_CLIENT_ID}}</string>
       </array>
     </dict>
   </array>
   ```

   Substituir `{{REVERSED_CLIENT_ID}}` pelo valor do campo homônimo dentro do `GoogleService-Info.plist`.

4. Em `ios/Podfile`, garantir `platform :ios, '13.0'` (ou superior — `firebase_auth 6.x` exige >= 13).
5. `cd ios && pod install` (ou `pod install --repo-update` se houver lock issues).
6. Abrir `ios/Runner.xcworkspace` no Xcode e fazer um build de validação (Cmd+B). Resolver eventuais problemas de signing/bundle id.
7. Rodar em device/simulador: `flutter run -d <ios-device>`.
8. Validar manualmente:
   - Sign in com email/senha (após habilitar provider no Firebase Console).
   - Sign in com Google (tela de seleção de conta deve aparecer).
   - Sign out volta para `/onboarding`.
   - Reabrir app com sessão ativa vai direto para `/home`.

## Notas

- `GoogleSignInService` deste app passa `serverClientId: null`. No iOS, o plugin `google_sign_in 7.x` lê o client ID do `Info.plist` (campo `GIDClientID` que vem do `GoogleService-Info.plist`). Se o plist não estiver presente, o plugin lança `GoogleSignInException` em runtime.
- Não há configuração extra necessária para o `firebase_auth` em iOS além do `GoogleService-Info.plist` e do bootstrap em `main.dart` (`Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`), que já está implementado.
