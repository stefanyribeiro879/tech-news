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

### 3. App Android (APK)

```bash
flutter build apk --release
```

O arquivo fica em `build/app/outputs/flutter-apk/app-release.apk`. Ele não vai para o git; mande pelo WhatsApp/Drive ou anexe numa Release do GitHub. No celular, abra o arquivo e permita "instalar apps de fontes desconhecidas". O APK usa o backend do Render, então funciona em qualquer rede (Wi-Fi ou 4G).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
