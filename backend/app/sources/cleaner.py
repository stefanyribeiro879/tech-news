"""Limpeza do corpo das notícias.

Os feeds misturam a matéria com anúncios, cards de oferta, índice, chamadas
para outras notícias ("Leia também", "Veja mais") e avisos de afiliados. Aqui
fica só o texto da matéria, em duas etapas:

1. No HTML: remove blocos inteiros (widgets, embeds, listas de links...).
2. No texto: remove linhas de chamada, créditos de foto e manchetes soltas
   (o g1 manda o texto sem HTML, então só esta etapa funciona para ele).
"""

import html
import re

from bs4 import BeautifulSoup, NavigableString, Tag

# Elementos que nunca fazem parte do texto da matéria.
_DROP_TAGS = [
    "script", "style", "noscript", "iframe", "form", "button", "svg", "figure",
    "figcaption", "img", "picture", "video", "audio", "details", "aside", "nav",
    "table",
]

# Classes/ids de blocos que não são matéria (ofertas, índice, embeds...).
_JUNK_ATTR_RE = re.compile(
    r"widget|produto|oferta|offer|sponsor|patrocin|publicidade|advert|\bads?\b"
    r"|banner|related|relacionad|leia-?tambem|newsletter|share|social"
    r"|table-of-contents|\btoc\b|aviso|instagram|twitter|tiktok|youtube|embed"
    r"|callout|cupom|coupon",
    re.IGNORECASE,
)

# Trechos de texto que denunciam anúncio ou chamada para outra notícia.
_JUNK_TEXT_RE = re.compile(
    r"^(leia|veja|confira|assista)\s+tamb[ée]m\b"
    r"|^leia\s+mais\b"
    r"|apareceu primeiro em"
    r"|\{\{\s*[A-Z_]+\s*\}\}"
    r"|aviso de [ée]tica|links? de afiliados?|programa de afiliados"
    r"|clique (aqui )?para (ler|ver|saber|ouvir|assistir)"
    r"|favorite o g1|ou[çc]a (o|os) podcasts?|o podcast .{0,60}est[áa] dispon[íi]vel"
    r"|^isso [ée] fant[áa]stico$"
    r"|continua (depois|ap[óo]s) (da |a )?publicidade|^publicidade$"
    r"|ct ofertas|canais de ofertas|achados do tb"
    r"|^\W*siga (o|a|nosso|nossa)\b.{0,60}\b(whatsapp|telegram|google news|instagram|youtube|canal)"
    r"|^\W*(entre|participe) (no|do|dos) (nosso )?(canal|grupo|canais)"
    r"|tem alguma sugest[ãa]o de reportagem|^agora no g1$"
    r"|ver esse post no instagram|um post compartilhado por"
    r"|inscreva-se|assine (a|nossa) newsletter",
    re.IGNORECASE,
)

# Crédito de foto em linha própria (g1): "Reprodução/TV Globo", "Reuters".
_CREDIT_RE = re.compile(
    r"^(reprodu[çc][ãa]o|divulga[çc][ãa]o|arquivo( pessoal)?|getty images|reuters"
    r"|afp|ap|pexels|unsplash|unplash|freepik|shutterstock|istock)\s*($|[/:])"
    r"|^(foto|imagem)\s*:"
    r"|^[^\s/]+( [^\s/]+){0,3} ?/ ?\S.*$",
    re.IGNORECASE,
)

# Fim de frase. Linha sem isso no fim do texto costuma ser manchete solta.
_SENTENCE_END_RE = re.compile(r"[.!?…:;\"”'’»)]$")

_WORD_RE = re.compile(r"\w")
_TAG_RE = re.compile(r"<[^>]+>")
_BLOCK_END_RE = re.compile(r"</(p|div|h\d|li|ul|ol|blockquote)>|<br\s*/?>", re.IGNORECASE)
_SPACES_RE = re.compile(r"[ \t\r\f\v ]+")
_BLANK_LINES_RE = re.compile(r"\n\s*\n+")

BULLET = "• "


def html_to_text(raw: str) -> str:
    """Remove as tags HTML, mantendo a quebra entre parágrafos."""
    text = _BLOCK_END_RE.sub("\n\n", raw)
    text = html.unescape(_TAG_RE.sub("", text))
    text = _SPACES_RE.sub(" ", text)
    text = _BLANK_LINES_RE.sub("\n\n", text)
    return "\n".join(line.strip() for line in text.strip().splitlines())


def _text(tag: Tag) -> str:
    return " ".join(tag.get_text(" ").split())


def _is_link_only(tag: Tag) -> bool:
    """Bloco cujo texto inteiro é um link: chamada para outra matéria."""
    text = _text(tag)
    links = " ".join(_text(a) for a in tag.find_all("a"))
    return bool(text) and text == " ".join(links.split())


def _has_junk_attr(tag: Tag) -> bool:
    if tag.attrs is None:
        return False
    classes = tag.get("class") or []
    if isinstance(classes, str):
        classes = [classes]
    attrs = " ".join([*classes, tag.get("id") or ""])
    return bool(attrs.strip()) and _JUNK_ATTR_RE.search(attrs) is not None


def _drop_lead_caption(soup: BeautifulSoup) -> None:
    """g1: o texto começa com <img><br> e a legenda da foto na 1ª linha."""
    first = next((n for n in soup.contents if not (isinstance(n, NavigableString) and not n.strip())), None)
    if not (isinstance(first, Tag) and first.name == "img"):
        return
    node = first.next_sibling
    while node is not None and (
        (isinstance(node, Tag) and node.name == "br")
        or (isinstance(node, NavigableString) and not node.strip())
    ):
        node = node.next_sibling
    if isinstance(node, NavigableString):
        rest = node.lstrip().split("\n", 1)
        node.replace_with(rest[1] if len(rest) > 1 else "")


def _clean_soup(soup: BeautifulSoup) -> None:
    _drop_lead_caption(soup)

    for tag in soup.find_all(_DROP_TAGS):
        tag.decompose()

    for tag in soup.find_all(_has_junk_attr):
        if not tag.decomposed:
            tag.decompose()

    # Cards de produto com link patrocinado (o texto da matéria é bem maior).
    for link in soup.find_all("a", rel=lambda rel: rel and "sponsored" in rel):
        if link.decomposed:
            continue
        card = link.find_parent("div")
        if card is not None and len(_text(card)) < 1200:
            card.decompose()

    # Listas só de links ("Leia mais:" seguido dos links).
    for lst in soup.find_all(["ul", "ol"]):
        if lst.decomposed:
            continue
        items = lst.find_all("li", recursive=False)
        if items and all(_is_link_only(li) for li in items):
            lst.decompose()

    for tag in soup.find_all(["p", "li", "h1", "h2", "h3", "h4", "h5", "h6"]):
        if tag.decomposed:
            continue
        text = _text(tag)
        if _JUNK_TEXT_RE.search(text) or _is_link_only(tag):
            tag.decompose()

    for li in soup.find_all("li"):
        li.insert(0, BULLET)


def clean_text(text: str) -> str:
    """Tira linhas de chamada/crédito e manchetes soltas do fim do texto."""
    lines: list[str] = []
    for line in text.split("\n"):
        line = line.strip()
        if not line:
            lines.append("")
            continue
        # Sem nenhuma letra ou número: sobra de widget ("&", "•", "|").
        if _JUNK_TEXT_RE.search(line) or not _WORD_RE.search(line):
            continue
        if len(line) <= 60 and not _SENTENCE_END_RE.search(line) and _CREDIT_RE.search(line):
            # A linha antes do crédito é a legenda da foto.
            while lines and not lines[-1]:
                lines.pop()
            if lines and len(lines[-1]) <= 200 and not lines[-1].startswith(BULLET):
                lines.pop()
            continue
        lines.append(line)

    # Fim do texto: manchetes de outras matérias e legendas sem ponto final.
    # Nunca apaga o único parágrafo (resumos curtos às vezes não têm ponto).
    while sum(1 for line in lines if line) > 1 and (
        not lines[-1]
        or (
            len(lines[-1]) <= 160
            and not lines[-1].startswith(BULLET)
            and not _SENTENCE_END_RE.search(lines[-1])
        )
    ):
        lines.pop()

    while lines and not lines[0]:
        lines.pop(0)

    return _BLANK_LINES_RE.sub("\n\n", "\n".join(lines)).strip()


def clean_article_html(raw: str) -> str:
    """HTML do feed → só o texto da matéria, com parágrafos separados."""
    if not raw or not raw.strip():
        return ""
    soup = BeautifulSoup(raw, "html.parser")
    _clean_soup(soup)
    return clean_text(html_to_text(str(soup)))
