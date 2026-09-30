"""Leitura de feeds RSS e conversão para o modelo Article."""

import hashlib
import html
import re
from calendar import timegm
from dataclasses import dataclass
from datetime import datetime, timezone

import feedparser
import httpx

from app.schemas import Article
from app.services.categorizer import categorize


@dataclass(frozen=True)
class Feed:
    name: str
    url: str


FEEDS: list[Feed] = [
    Feed("Tecnoblog", "https://tecnoblog.net/feed/"),
    Feed("Canaltech", "https://canaltech.com.br/rss/"),
    Feed("Olhar Digital", "https://olhardigital.com.br/feed/"),
    Feed("g1 Tecnologia", "https://g1.globo.com/rss/g1/tecnologia/"),
    Feed("Tudocelular", "https://www.tudocelular.com/feed/"),
]

SUMMARY_MAX_CHARS = 280

_TAG_RE = re.compile(r"<[^>]+>")
_IMG_RE = re.compile(r"<img[^>]+src=[\"']([^\"']+)[\"']", re.IGNORECASE)
_BLOCK_END_RE = re.compile(r"</(p|div|h\d|li)>|<br\s*/?>", re.IGNORECASE)
_SPACES_RE = re.compile(r"[ \t\r\f\v]+")
_BLANK_LINES_RE = re.compile(r"\n\s*\n+")
_WEB_URL_RE = re.compile(r"^https?://[^\s/]+", re.IGNORECASE)


def is_web_url(url: str | None) -> bool:
    """Só links http(s): bloqueia "javascript:", "data:" etc. vindos do feed."""
    return bool(url) and len(url) <= 2048 and _WEB_URL_RE.match(url) is not None


def article_id(url: str) -> str:
    """ID estável: o mesmo link sempre gera o mesmo id."""
    return hashlib.sha1(url.encode("utf-8")).hexdigest()[:16]


def html_to_text(raw: str) -> str:
    """Remove as tags HTML, mantendo a quebra entre parágrafos."""
    text = _BLOCK_END_RE.sub("\n\n", raw)
    text = html.unescape(_TAG_RE.sub("", text))
    text = _SPACES_RE.sub(" ", text)
    text = _BLANK_LINES_RE.sub("\n\n", text)
    return "\n".join(line.strip() for line in text.strip().splitlines())


def truncate(text: str, limit: int = SUMMARY_MAX_CHARS) -> str:
    text = " ".join(text.split())
    if len(text) <= limit:
        return text
    return text[:limit].rsplit(" ", 1)[0].rstrip(".,;:") + "…"


def _find_image(entry: feedparser.FeedParserDict, raw_html: str) -> str | None:
    for media in entry.get("media_content", []) + entry.get("media_thumbnail", []):
        if media.get("url") and media.get("medium", "image") == "image":
            return media["url"]
    for enclosure in entry.get("enclosures", []):
        if enclosure.get("type", "").startswith("image/") and enclosure.get("href"):
            return enclosure["href"]
    match = _IMG_RE.search(raw_html)
    return html.unescape(match.group(1)) if match else None


def _safe_image(entry: feedparser.FeedParserDict, raw_html: str) -> str | None:
    image = _find_image(entry, raw_html)
    return image if is_web_url(image) else None


def _published(entry: feedparser.FeedParserDict) -> datetime:
    parsed = entry.get("published_parsed") or entry.get("updated_parsed")
    if parsed:
        return datetime.fromtimestamp(timegm(parsed), tz=timezone.utc)
    return datetime.now(timezone.utc)


def parse_feed(raw: bytes | str, source: str) -> list[Article]:
    """Converte o XML de um feed em uma lista de Article (sem acessar a rede)."""
    parsed = feedparser.parse(raw)
    articles: list[Article] = []

    for entry in parsed.entries:
        url = entry.get("link")
        title = html.unescape(entry.get("title", "")).strip()
        if not is_web_url(url) or not title:
            continue

        summary_html = entry.get("summary", "")
        content_html = entry["content"][0].get("value", "") if entry.get("content") else ""

        summary = truncate(html_to_text(summary_html))
        content = html_to_text(content_html) or html_to_text(summary_html)
        tags = [t.get("term", "") for t in entry.get("tags", [])]

        articles.append(
            Article(
                id=article_id(url),
                title=title,
                summary=summary,
                content=content,
                url=url,
                image_url=_safe_image(entry, content_html + summary_html),
                source=source,
                category=categorize(title, summary, tags),
                published_at=_published(entry),
            )
        )
    return articles


async def fetch_feed(client: httpx.AsyncClient, feed: Feed) -> list[Article]:
    response = await client.get(feed.url)
    response.raise_for_status()
    return parse_feed(response.content, feed.name)
