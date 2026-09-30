from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, Request

from app.schemas import Article, NewsPage
from app.services.aggregator import NewsAggregator
from app.services.categorizer import CATEGORIES

router = APIRouter(tags=["notícias"])


def _aggregator(request: Request) -> NewsAggregator:
    return request.app.state.aggregator


def _paginate(items: list[Article], page: int, limit: int) -> NewsPage:
    start = (page - 1) * limit
    return NewsPage(items=items[start : start + limit], total=len(items), page=page, limit=limit)


@router.get("/categories", response_model=list[str])
async def list_categories() -> list[str]:
    return CATEGORIES


@router.get("/news", response_model=NewsPage)
async def list_news(
    request: Request,
    category: Annotated[str | None, Query(description="Ex.: Mobile, Games, Segurança")] = None,
    page: Annotated[int, Query(ge=1)] = 1,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
) -> NewsPage:
    if category and category not in CATEGORIES:
        raise HTTPException(404, f"Categoria desconhecida. Use uma de: {', '.join(CATEGORIES)}")
    articles = await _aggregator(request).by_category(category)
    return _paginate(articles, page, limit)


@router.get("/news/featured", response_model=list[Article])
async def featured_news(
    request: Request, limit: Annotated[int, Query(ge=1, le=10)] = 5
) -> list[Article]:
    return await _aggregator(request).featured(limit)


@router.get("/news/search", response_model=NewsPage)
async def search_news(
    request: Request,
    q: Annotated[str, Query(min_length=2, max_length=100, description="Texto a buscar")],
    page: Annotated[int, Query(ge=1)] = 1,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
) -> NewsPage:
    return _paginate(await _aggregator(request).search(q), page, limit)


@router.get("/news/{article_id}", response_model=Article)
async def get_news(request: Request, article_id: str) -> Article:
    article = await _aggregator(request).get(article_id)
    if article is None:
        raise HTTPException(404, "Notícia não encontrada (pode ter saído do cache).")
    return article
