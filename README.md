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

### 1. Backend no Render (só na primeira vez)

1. Entre em https://render.com com a conta do GitHub dona do repositório.
2. **New > Blueprint**, escolha o repositório `tech-news` e a branch `main`, e confirme.
3. Quando o deploy terminar, copie o endereço do serviço (ex.: `https://tech-news-api.onrender.com`) e teste `.../health` no navegador.
4. Se o endereço for diferente, atualize `productionApiUrl` em [lib/news_api.dart](lib/news_api.dart).

A cada push na `main`, o Render publica o backend de novo sozinho.

> No plano free o servidor "dorme" após 15 min sem acesso e leva até ~1 min para acordar. Antes de apresentar, abra o app uma vez.

### 2. App no GitHub Pages (sempre que o app mudar)

```bash
flutter build web --release --base-href /tech-news/ --output docs
```

Faça commit da pasta `docs/` e push na `main`. O site fica em https://stefanyribeiro879.github.io/tech-news/.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
