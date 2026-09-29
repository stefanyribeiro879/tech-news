# Tech News API (backend)

API em FastAPI que busca notícias de tecnologia em feeds RSS brasileiros, padroniza tudo em um formato único e entrega ao app Flutter.

```
Flutter (app / web) ──HTTP/JSON──► FastAPI ──► feeds RSS (Tecnoblog, Canaltech, Olhar Digital, g1, Tudocelular)
                                      └── cache em memória (15 min)
```

## Como rodar

Requer Python 3.11+.

```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
source .venv/bin/activate

pip install -r requirements-dev.txt
uvicorn app.main:app --reload
```

- API: http://127.0.0.1:8000
- Documentação interativa (Swagger): http://127.0.0.1:8000/docs

Para testar a partir do celular/emulador na mesma rede, use `uvicorn app.main:app --host 0.0.0.0` e acesse pelo IP da máquina (no emulador Android, `http://10.0.2.2:8000`).

## Rotas

| Método | Rota | Descrição |
|---|---|---|
| GET | `/health` | Status da API, horário da última atualização e situação de cada feed |
| GET | `/categories` | Categorias disponíveis |
| GET | `/news?category=&page=1&limit=20` | Notícias mais recentes, paginadas e com filtro de categoria |
| GET | `/news/featured?limit=5` | Destaques: mais recentes com imagem, uma por fonte |
| GET | `/news/search?q=` | Busca no título, resumo, categoria e fonte (ignora acentos) |
| GET | `/news/{id}` | Uma notícia específica |

Formato de cada notícia:

```json
{
  "id": "3f2a9c1b7e4d5a60",
  "title": "…",
  "summary": "Resumo de até 280 caracteres",
  "content": "Texto disponível no feed (pode ser parcial)",
  "url": "https://link-da-materia-original",
  "image_url": "https://… ou null",
  "source": "Tecnoblog",
  "category": "Inteligência Artificial",
  "published_at": "2026-09-29T12:00:00Z"
}
```

## Como funciona

- **Fontes** ([app/sources/rss.py](app/sources/rss.py)): lista de feeds e conversão de RSS para `Article`. Para adicionar uma fonte, basta incluir um `Feed(nome, url)` em `FEEDS`.
- **Categorias** ([app/services/categorizer.py](app/services/categorizer.py)): definidas por palavras-chave (palavras no título valem o dobro). Sem correspondência, a notícia fica em `Geral`.
- **Agregador** ([app/services/aggregator.py](app/services/aggregator.py)): busca todos os feeds em paralelo, remove duplicadas pelo link, ordena por data e guarda em cache. Se um feed falhar, os outros continuam funcionando; se todos falharem, o cache anterior é mantido.
- **Configuração** ([app/config.py](app/config.py)): pode ser alterada por variáveis de ambiente ou arquivo `.env` (veja `.env.example`).

## Testes

```bash
pytest
```

Os testes usam um feed de exemplo local e fontes falsas, então não dependem da internet.
