"""Junta as notícias de todas as fontes e mantém um cache em memória."""

import asyncio
import logging
import time
from collections.abc import Awaitable, Callable
from datetime import datetime, timezone

from app.schemas import Article, SourceStatus
from app.services.categorizer import normalize

logger = logging.getLogger(__name__)

# Cada fonte é um nome + uma função assíncrona que devolve as notícias dela.
Source = tuple[str, Callable[[], Awaitable[list[Article]]]]


class NewsAggregator:
    def __init__(self, sources: list[Source], ttl_seconds: int) -> None:
        self._sources = sources
        self._ttl = ttl_seconds
        self._articles: list[Article] = []
        self._by_id: dict[str, Article] = {}
        self._fetched_at: float | None = None
        self._lock = asyncio.Lock()
        self.last_update: datetime | None = None
        self.source_status: list[SourceStatus] = []

    @property
    def cached_count(self) -> int:
        return len(self._articles)

    def _is_fresh(self) -> bool:
        return self._fetched_at is not None and time.monotonic() - self._fetched_at < self._ttl

    async def refresh(self) -> None:
        results = await asyncio.gather(
            *(fetch() for _, fetch in self._sources), return_exceptions=True
        )

        merged: dict[str, Article] = {}
        status: list[SourceStatus] = []
        for (name, _), result in zip(self._sources, results):
            if isinstance(result, BaseException):
                logger.warning("Falha ao buscar %s: %r", name, result)
                status.append(SourceStatus(name=name, ok=False, articles=0, error=repr(result)))
                continue
            status.append(SourceStatus(name=name, ok=True, articles=len(result)))
            for article in result:
                merged.setdefault(article.id, article)  # remove duplicadas (mesmo link)

        self.source_status = status
        # Se todas as fontes falharem, mantém o cache antigo em vez de ficar vazio.
        if not merged and self._articles:
            return

        self._articles = sorted(merged.values(), key=lambda a: a.published_at, reverse=True)
        self._by_id = merged
        self._fetched_at = time.monotonic()
        self.last_update = datetime.now(timezone.utc)

    async def articles(self) -> list[Article]:
        if not self._is_fresh():
            async with self._lock:
                if not self._is_fresh():  # outra requisição pode ter atualizado enquanto esperávamos
                    await self.refresh()
        return self._articles

    async def get(self, article_id: str) -> Article | None:
        await self.articles()
        return self._by_id.get(article_id)

    async def by_category(self, category: str | None) -> list[Article]:
        articles = await self.articles()
        if not category:
            return articles
        return [a for a in articles if a.category == category]

    async def featured(self, limit: int) -> list[Article]:
        """As mais recentes com imagem, no máximo uma por fonte para variar."""
        chosen: list[Article] = []
        used_sources: set[str] = set()
        for article in await self.articles():
            if article.image_url and article.source not in used_sources:
                chosen.append(article)
                used_sources.add(article.source)
                if len(chosen) == limit:
                    break
        return chosen

    async def search(self, query: str) -> list[Article]:
        terms = normalize(query).split()
        if not terms:
            return []
        results = []
        for article in await self.articles():
            text = normalize(f"{article.title} {article.summary} {article.category} {article.source}")
            if all(term in text for term in terms):
                results.append(article)
        return results
