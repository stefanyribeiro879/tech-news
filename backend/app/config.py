
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configurações lidas de variáveis de ambiente ou do arquivo .env."""

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_name: str = "Tech News API"

    # Tempo (segundos) que as notícias ficam em cache antes de buscar de novo.
    cache_ttl_seconds: int = 900

    # Tempo máximo (segundos) de espera por cada feed.
    request_timeout_seconds: float = 10.0

    # Origens autorizadas a chamar a API pelo navegador (versão web do app).
    cors_origins: list[str] = [
        "http://localhost",
        "http://127.0.0.1",
        "https://stefanyribeiro879.github.io",
    ]
    # Qualquer porta do localhost (o `flutter run -d chrome` usa porta aleatória).
    cors_origin_regex: str = r"http://(localhost|127\.0\.0\.1)(:\d+)?"


@lru_cache
def get_settings() -> Settings:
    return Settings()
