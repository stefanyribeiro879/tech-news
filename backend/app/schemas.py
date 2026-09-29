from datetime import datetime

from pydantic import BaseModel


class Article(BaseModel):
    """Formato único de notícia entregue ao app, independente da fonte."""

    id: str
    title: str
    summary: str
    content: str
    url: str
    image_url: str | None = None
    source: str
    category: str
    published_at: datetime


class NewsPage(BaseModel):
    items: list[Article]
    total: int
    page: int
    limit: int


class SourceStatus(BaseModel):
    name: str
    ok: bool
    articles: int
    error: str | None = None


class Health(BaseModel):
    status: str
    cached_articles: int
    last_update: datetime | None
    sources: list[SourceStatus]
