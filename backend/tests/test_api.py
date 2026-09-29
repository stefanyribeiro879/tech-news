"""Testa a API com fontes falsas (sem acessar a internet)."""

from datetime import datetime, timedelta, timezone

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas import Article
from app.services.aggregator import NewsAggregator

BASE = datetime(2026, 9, 29, 12, 0, tzinfo=timezone.utc)


def make(id_, title, category, hours_ago, source="A", image=True):
    return Article(
        id=id_,
        title=title,
        summary=f"Resumo de {title}",
        content="Conteúdo",
        url=f"https://exemplo.com/{id_}",
        image_url=f"https://exemplo.com/{id_}.jpg" if image else None,
        source=source,
        category=category,
        published_at=BASE - timedelta(hours=hours_ago),
    )


async def source_a():
    return [
        make("1", "Nova IA da OpenAI", "Inteligência Artificial", 1),
        make("2", "Lançamento do iPhone", "Mobile", 3),
        make("3", "Golpe no Pix", "Segurança", 5, image=False),
    ]


async def source_b():
    return [
        make("1", "Nova IA da OpenAI (duplicada)", "Inteligência Artificial", 1, source="B"),
        make("4", "Trailer de GTA 6", "Games", 2, source="B"),
    ]


async def broken_source():
    raise RuntimeError("feed fora do ar")


@pytest.fixture
def client():
    with TestClient(app) as c:
        app.state.aggregator = NewsAggregator(
            [("A", source_a), ("B", source_b), ("Quebrada", broken_source)], ttl_seconds=60
        )
        yield c


def test_lista_ordenada_e_sem_duplicadas(client):
    body = client.get("/news").json()
    assert body["total"] == 4
    assert [a["id"] for a in body["items"]] == ["1", "4", "2", "3"]


def test_paginacao(client):
    body = client.get("/news", params={"page": 2, "limit": 3}).json()
    assert [a["id"] for a in body["items"]] == ["3"]
    assert body["page"] == 2


def test_filtra_por_categoria(client):
    body = client.get("/news", params={"category": "Games"}).json()
    assert [a["id"] for a in body["items"]] == ["4"]


def test_categoria_invalida(client):
    assert client.get("/news", params={"category": "Culinária"}).status_code == 404


def test_destaques_com_imagem_e_uma_por_fonte(client):
    ids = [a["id"] for a in client.get("/news/featured").json()]
    assert ids == ["1", "4"]


def test_busca_ignora_acentos(client):
    body = client.get("/news/search", params={"q": "iphone lançamento"}).json()
    assert [a["id"] for a in body["items"]] == ["2"]
    body = client.get("/news/search", params={"q": "lancamento"}).json()
    assert body["total"] == 1


def test_detalhe_da_noticia(client):
    assert client.get("/news/4").json()["title"] == "Trailer de GTA 6"
    assert client.get("/news/nao-existe").status_code == 404


def test_health_mostra_fonte_com_falha(client):
    client.get("/news")
    sources = {s["name"]: s for s in client.get("/health").json()["sources"]}
    assert sources["A"]["ok"] and sources["A"]["articles"] == 3
    assert not sources["Quebrada"]["ok"]


def test_categorias(client):
    assert "Segurança" in client.get("/categories").json()
