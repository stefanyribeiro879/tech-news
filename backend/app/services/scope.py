"""Filtro de escopo: decide se uma notícia pertence ao tema do app (tecnologia).

Antes, tudo o que os feeds traziam entrava no app: o que não casava com nenhuma
categoria virava "Geral" e aparecia em "Tudo", no Feed e nos destaques.

Regras (`is_in_scope`):
1. Categoria específica (IA, Mobile, Games, Segurança)  -> dentro do escopo.
2. "Geral" com algum termo de tecnologia                -> dentro do escopo.
3. "Geral" sem termo de tecnologia:
   - feed `strict` (generalista: g1, Olhar Digital...)   -> fora.
   - feed de tecnologia, mas assunto claramente alheio
     (futebol, política, famosos...)                      -> fora.
   - caso contrário                                       -> dentro.
"""

from app.services.categorizer import DEFAULT_CATEGORY, _compile, normalize

# Palavras sem acento e em minúsculas (o texto é normalizado antes da busca).
TECH_TERMS: list[str] = [
    "tecnologia", "tecnologico", "tecnologica", "tech", "app", "apps", "aplicativo",
    "aplicativos", "software", "hardware", "internet", "rede social",
    "redes sociais", "google", "apple", "microsoft", "meta", "amazon", "tesla", "spacex",
    "starlink", "nvidia", "intel", "amd", "qualcomm", "samsung", "sony", "netflix",
    "spotify", "youtube", "instagram", "tiktok", "facebook", "telegram", "windows",
    "linux", "chrome", "notebook", "computador", "pc", "processador", "chip", "chips",
    "semicondutor", "semicondutores", "bateria", "wi-fi", "wifi", "satelite", "robo",
    "robos", "drone", "drones", "carro eletrico", "veiculo eletrico", "streaming",
    "nuvem", "cloud", "startup", "startups", "programacao", "desenvolvedor", "codigo",
    "api", "algoritmo", "privacidade", "lgpd", "bitcoin", "criptomoeda", "criptomoedas",
    "blockchain", "big tech", "big techs", "pix", "5g", "6g", "fibra optica", "telecom",
    "anatel", "espacial", "nasa",
]

# Assuntos claramente alheios ao app (só pesam quando não há termo de tecnologia).
OFF_TOPIC_TERMS: list[str] = [
    "futebol", "brasileirao", "campeonato", "libertadores", "copa do mundo", "selecao",
    "flamengo", "corinthians", "palmeiras", "nba", "formula 1", "olimpiadas",
    "eleicao", "eleicoes", "deputado", "senador", "prefeito", "bolsonaro", "lula",
    "assassinato", "homicidio", "policia", "previsao do tempo", "horoscopo", "signo",
    "novela", "bbb", "famosos", "celebridade", "cantor", "cantora", "mega-sena",
    "loteria", "ibovespa", "inflacao", "receita de",
]

_TECH = _compile(TECH_TERMS)
_OFF_TOPIC = _compile(OFF_TOPIC_TERMS)


def is_in_scope(
    title: str,
    summary: str,
    category: str,
    *,
    strict: bool = False,
) -> bool:
    """True se a notícia deve entrar no app. `strict` = feed generalista."""
    if category != DEFAULT_CATEGORY:
        return True

    text = normalize(f"{title} {summary}")
    if _TECH.search(text):
        return True
    if strict:
        return False
    return not _OFF_TOPIC.search(normalize(title))
