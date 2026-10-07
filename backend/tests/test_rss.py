from datetime import datetime, timezone
from pathlib import Path

from app.sources.rss import article_id, html_to_text, is_web_url, parse_feed, truncate

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


def test_so_aceita_links_web():
    assert is_web_url("https://exemplo.com/noticia")
    assert is_web_url("http://exemplo.com")
    assert not is_web_url("javascript:alert(1)")
    assert not is_web_url("data:text/html,oi")
    assert not is_web_url("https://")
    assert not is_web_url(None)


def test_descarta_noticia_com_link_perigoso():
    feed = """<?xml version="1.0"?><rss version="2.0"><channel><title>T</title>
    <item><title>Golpe</title><link>javascript:alert(1)</link></item>
    <item><title>Ok</title><link>https://exemplo.com/ok</link>
      <description>&lt;img src="javascript:x"&gt;</description></item>
    </channel></rss>""".encode("utf-8")
    articles = parse_feed(feed, "Teste")
    assert [a.url for a in articles] == ["https://exemplo.com/ok"]
    assert articles[0].image_url is None


STRICT_FEED = """<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel><title>Feed generalista</title>
  <item>
    <title>Empresa anuncia resultado trimestral</title>
    <link>https://exemplo.com/resultado</link>
    <description>Os números do trimestre superaram a expectativa do mercado.</description>
  </item>
  <item>
    <title>Google lança novo recurso no Chrome</title>
    <link>https://exemplo.com/chrome</link>
    <description>A novidade chega a todos os usuários nas próximas semanas.</description>
  </item>
  <item>
    <title>OpenAI lança novo modelo de IA</title>
    <link>https://exemplo.com/ia</link>
    <description>O modelo promete ajudar desenvolvedores.</description>
  </item>
</channel></rss>""".encode("utf-8")


def test_feed_estrito_descarta_geral_sem_tecnologia():
    estrito = {a.url for a in parse_feed(STRICT_FEED, "Generalista", strict=True)}
    assert estrito == {"https://exemplo.com/chrome", "https://exemplo.com/ia"}


def test_feed_nao_estrito_mantem_geral_neutro():
    normal = {a.url for a in parse_feed(STRICT_FEED, "Tecnologia")}
    assert "https://exemplo.com/resultado" in normal
