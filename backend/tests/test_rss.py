from datetime import datetime, timezone
from pathlib import Path

from app.sources.rss import article_id, html_to_text, parse_feed, truncate

FIXTURE = Path(__file__).parent / "fixtures" / "sample_feed.xml"


def _articles():
    return {a.url: a for a in parse_feed(FIXTURE.read_bytes(), "Fonte Teste")}


def test_ignora_itens_sem_link():
    assert len(_articles()) == 3


def test_converte_campos_basicos():
    article = _articles()["https://exemplo.com/ia-openai"]
    assert article.id == article_id("https://exemplo.com/ia-openai")
    assert article.source == "Fonte Teste"
    assert article.category == "Inteligência Artificial"
    assert article.summary == "O novo modelo de inteligência artificial promete ajudar desenvolvedores."
    assert article.content == "Primeiro parágrafo.\n\nSegundo & último parágrafo."
    assert article.published_at == datetime(2026, 9, 28, 17, 0, tzinfo=timezone.utc)


def test_encontra_imagem_no_html_e_no_media_content():
    articles = _articles()
    assert articles["https://exemplo.com/ia-openai"].image_url == "https://exemplo.com/ia.jpg"
    assert articles["https://exemplo.com/golpe"].image_url == "https://exemplo.com/golpe.jpg"
    assert articles["https://exemplo.com/resultado"].image_url is None


def test_sem_content_usa_o_resumo_como_conteudo():
    article = _articles()["https://exemplo.com/golpe"]
    assert article.content == "Criminosos usam phishing para enganar vítimas."
    assert article.category == "Segurança"


def test_html_to_text_remove_tags_e_entidades():
    assert html_to_text("<p>A &amp; B</p><p>C<br>D</p>") == "A & B\n\nC\n\nD"


def test_truncate_corta_na_palavra():
    text = "palavra " * 100
    result = truncate(text, 30)
    assert len(result) <= 31
    assert result.endswith("…")
    assert not result.startswith(" ")
