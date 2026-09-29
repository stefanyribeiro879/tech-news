import logging
from contextlib import asynccontextmanager
from functools import partial

import httpx
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import news
from app.schemas import Health
from app.services.aggregator import NewsAggregator
from app.sources.rss import FEEDS, fetch_feed

logging.basicConfig(level=logging.INFO)

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with httpx.AsyncClient(
        timeout=settings.request_timeout_seconds,
        follow_redirects=True,
        headers={"User-Agent": "TechNews/0.1 (+https://github.com/stefanyribeiro879/tech-news)"},
    ) as client:
        sources = [(feed.name, partial(fetch_feed, client, feed)) for feed in FEEDS]
        app.state.aggregator = NewsAggregator(sources, settings.cache_ttl_seconds)
        yield


app = FastAPI(
    title=settings.app_name,
    description="Agrega notícias de tecnologia de vários feeds RSS em um formato único.",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_origin_regex=settings.cors_origin_regex,
    allow_methods=["GET"],
    allow_headers=["*"],
)

app.include_router(news.router)


@app.get("/health", response_model=Health, tags=["status"])
async def health(request: Request) -> Health:
    aggregator: NewsAggregator = request.app.state.aggregator
    return Health(
        status="ok",
        cached_articles=aggregator.cached_count,
        last_update=aggregator.last_update,
        sources=aggregator.source_status,
    )
