# tech_news

Aplicativo mobile de notícias sobre tecnologia desenvolvido como parte do Projeto A3 do curso de Redes de Computadores.

O TechNews tem como objetivo centralizar conteúdos relacionados à tecnologia e permitir que o usuário acompanhe notícias de acordo com seus interesses.

## Como rodar

O app busca as notícias no backend (pasta [backend/](backend/)), que lê feeds RSS de sites de tecnologia.

1. Suba o backend (detalhes em [backend/README.md](backend/README.md)):
   ```bash
   cd backend
   python run.py
   ```
2. Em outro terminal, na raiz do projeto:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

Para conferir se nenhuma tela "estoura" o layout no celular ou no computador:

```bash
flutter test
```

Endereço da API usado pelo app ([lib/news_api.dart](lib/news_api.dart)):

| Onde o app roda | Endereço |
|---|---|
| Chrome / Windows | `http://127.0.0.1:8000` |
| Emulador Android | `http://10.0.2.2:8000` |
| Celular na mesma rede | `flutter run --dart-define=API_URL=http://IP-DO-PC:8000` (e o backend com `--host 0.0.0.0`) |
| Versão publicada (`flutter build`) | `productionApiUrl` (backend no Render) |

## Publicação (gratuita)

- **App web**: GitHub Pages, servido a partir da pasta `docs/` da branch `main`.
- **Backend**: [Render](https://render.com), plano free, configurado em [render.yaml](render.yaml).
- **Usuários e notícias salvas**: [Supabase](https://supabase.com) (login por e-mail/senha + banco Postgres). As tabelas e regras de segurança estão em [supabase/schema.sql](supabase/schema.sql); a URL e a publishable key ficam em [lib/supabase_service.dart](lib/supabase_service.dart).

> O projeto gratuito do Supabase é pausado após 1 semana sem uso. Para reativar: painel do Supabase > "Restore project".

### Esqueci a senha (e-mail com código)

O app envia um código de 6 dígitos por e-mail. Para isso funcionar, configure no painel do Supabase:

1. **Authentication > Emails > Templates > Reset password**: cole o conteúdo de [supabase/email-templates/reset-password.html](supabase/email-templates/reset-password.html). É o `{{ .Token }}` que coloca o código no e-mail.
2. **Authentication > Sign In / Providers > Email**: *Email OTP Length* = `6`.
3. **Authentication > Emails > SMTP Settings**: configure um SMTP próprio. O serviço de e-mail padrão do Supabase só envia para membros da equipe do projeto e tem limite de poucos e-mails por hora.

### 1. Backend no Render (só na primeira vez)

1. Entre em https://render.com com a conta do GitHub dona do repositório.
2. **New > Blueprint**, escolha o repositório `tech-news` e a branch `main`, e confirme.
3. Quando o deploy terminar, copie o endereço do serviço (ex.: `https://technews-a3-api.onrender.com`) e teste `.../health` no navegador.
4. Se o endereço for diferente, atualize `productionApiUrl` em [lib/news_api.dart](lib/news_api.dart).

A cada push na `main`, o Render publica o backend de novo sozinho.

> No plano free o servidor "dorme" após 15 min sem acesso e leva até ~1 min para acordar. Antes de apresentar, abra o app uma vez.

### 2. App no GitHub Pages (sempre que o app mudar)

```bash
flutter build web --release --base-href /tech-news/ --output docs
```

Faça commit da pasta `docs/` e push na `main`. O site fica em https://stefanyribeiro879.github.io/tech-news/.

### 3. App Android (APK) e atualização automática

O APK é gerado e publicado pelo GitHub Actions ([.github/workflows/release-android.yml](.github/workflows/release-android.yml)). Ao abrir, o app consulta a última Release do GitHub. Se houver versão nova, mostra "Atualização disponível", e a atualização é **obrigatória**. O app confere a permissão "Instalar apps desconhecidos", baixa o APK e pede a confirmação do Android. Se a instalação falhar, o app mostra o motivo e oferece "Tentar de novo" ou "Baixar pelo navegador".

**Pacotes de atualização.** As mudanças se acumulam e só viram versão quando o pacote estiver pronto:

1. Trabalhe na branch `eduardo`. Cada push roda a **Verificação** ([ci.yml](.github/workflows/ci.yml)), com análise do código e testes, sem publicar nada.
2. Com o pacote pronto e verificado, leve para a `main` e aumente `version:` no [pubspec.yaml](pubspec.yaml), por exemplo de `1.1.0+4` para `1.2.0+5`. Aumente sempre os dois números.
3. No GitHub, vá em **Actions > Release Android > Run workflow**. Ele roda os testes, gera o APK e cria a Release `v1.2.0`. Se a versão já tiver sido publicada, ele recusa.

**Configuração (só na primeira vez).** A chave de assinatura precisa ser sempre a mesma. Se ela mudar, o Android recusa instalar a atualização.

1. Gere a chave, com o `keytool` que vem com o Android Studio (`<Android Studio>/jbr/bin/keytool`):
   ```bash
   keytool -genkey -v -keystore technews-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias technews
   ```
   Guarde o arquivo e a senha em lugar seguro, fora do git. Se perder a chave, todos terão que reinstalar o app.
2. No GitHub, em **Settings > Secrets and variables > Actions > Secrets**, crie:
   - `ANDROID_KEYSTORE_BASE64`: o conteúdo do arquivo em base64 (`base64 -w0 technews-release.jks`)
   - `ANDROID_KEYSTORE_PASSWORD`: a senha
   - `ANDROID_KEY_ALIAS`: `technews`
3. (Opcional) Na aba **Variables** da mesma tela, crie `SUPABASE_URL` só se quiser trocar o endereço do proxy sem mexer no código. O padrão está em [lib/supabase_service.dart](lib/supabase_service.dart).

Para gerar um APK assinado no seu computador, crie `android/key.properties`, que está fora do git:
```
storeFile=../caminho/technews-release.jks
storePassword=SUA_SENHA
keyAlias=technews
keyPassword=SUA_SENHA
```

### 4. Proxy do Supabase (Cloudflare Workers, gratuito)

Algumas redes, DNS privados e bloqueadores barram `*.supabase.co`, e o cadastro falha com "Connection refused". O Worker em [cloudflare/supabase-proxy](cloudflare/supabase-proxy) recebe as chamadas do app num endereço `*.workers.dev` e repassa ao Supabase. O plano grátis cobre 100 mil requisições por dia.

```bash
cd cloudflare/supabase-proxy
npx wrangler login
npx wrangler deploy
```

O deploy mostra o endereço, por exemplo `https://technews-supabase.SEU-USUARIO.workers.dev`. Teste `.../health` no navegador; deve aparecer `ok`. O endereço atual (`https://technews-supabase.technews-a3.workers.dev`) já é o padrão do app em [lib/supabase_service.dart](lib/supabase_service.dart). Para testar localmente: `flutter run --dart-define=SUPABASE_URL=https://...workers.dev`.

> Os links de confirmação de e-mail enviados pelo Supabase continuam apontando para `supabase.co`.

## Segurança

**No código:**
- **Banco:** cada usuário só acessa os próprios dados (RLS em [supabase/schema.sql](supabase/schema.sql)). O arquivo [supabase/security.sql](supabase/security.sql) acrescenta limites de tamanho, até 500 salvos por pessoa, só links http(s) e a função de excluir a própria conta.
- **Links de feeds:** backend e app descartam links que não sejam http(s), como `javascript:` e `data:`.
- **Senhas novas:** no mínimo 8 caracteres, com letras e números.
- **Android:**
  - sem backup da sessão na nuvem;
  - só HTTPS na versão publicada;
  - sem permissões desnecessárias;
  - código ofuscado;
  - o atualizador só baixa APK das Releases deste repositório e confere o SHA-256. O Android ainda confere a assinatura.
- **Proxy:** até 20 tentativas por minuto por IP no login, cadastro e códigos. Só repassa as rotas do Supabase.
- **Dependabot:** avisa sobre dependências com correção de segurança.

**Configurações feitas nos painéis (não ficam no código):**
- **Supabase:**
  - rodar [supabase/security.sql](supabase/security.sql);
  - *Authentication > Sign In / Providers > Email*: senha mínima 8 com letras e números, OTP de 6 dígitos, expiração do OTP em 900 s;
  - *URL Configuration*: Site URL do GitHub Pages;
  - *Advisors > Security Advisor* sem alertas.
- **Cloudflare:** `npx wrangler deploy` em `cloudflare/supabase-proxy`, sempre que o proxy mudar.
- **GitHub:**
  - verificação em duas etapas nas contas com acesso;
  - *Settings > Branches*: proteger a `main`, exigindo que a Verificação passe;
  - *Settings > Code security*: Secret scanning, Push protection e Dependabot alerts ligados;
  - *Settings > Pages > Source*: GitHub Actions.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
