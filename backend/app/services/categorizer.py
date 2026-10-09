"""Define a categoria de uma notícia a partir de palavras-chave."""

import re
import unicodedata

DEFAULT_CATEGORY = "Geral"

# A ordem importa: em caso de empate, vence a categoria que aparece primeiro.
# Palavras sem acento e em minúsculas (o texto é normalizado antes da busca).
KEYWORDS: dict[str, list[str]] = {
    "Inteligência Artificial": [
        "inteligencia artificial", "ia", "ai", "chatgpt", "openai", "gemini",
        "claude", "anthropic", "llm", "copilot", "deepseek", "grok",
        "machine learning", "aprendizado de maquina", "chatbot", "ias", "IAs", "ia generativa", "ia generativas", "inteligencias artificiais","IA",
    ],
    "Mobile": [
        "iphone", "android", "smartphone", "smartphones", "celular", "celulares",
        "galaxy", "xiaomi", "motorola", "ios", "ipad", "tablet", "whatsapp",
        "pixel", "redmi", "poco", "oneplus", "oppo", "realme", "huawei", "5g",
        "operadora", "operadoras",
    ],
    "Games": [
        "game", "games", "videogame", "videogames", "gamer", "playstation", "ps5",
        "xbox", "nintendo", "switch 2", "steam", "console", "gta", "fortnite",
        "minecraft", "esports", "valorant", "league of legends", "call of duty",
    ],
    "Segurança": [
        "ciberseguranca", "seguranca digital", "seguranca da informacao", "hacker",
        "hackers", "ciberataque", "ciberataques", "ataque hacker", "ataque cibernetico",
        "ataque de ransomware", "ataque ddos", "ataque de phishing", "vazamento de dados",
        "dados vazados", "golpe", "golpes", "malware", "ransomware", "phishing",
        "vulnerabilidade", "falha de seguranca", "senha", "senhas", "fraude digital",
        "fraude online", "fraude eletronica", "antivirus", "virus de computador",
        "trojan", "spyware",
    ],
}

# Palavras que só valem se a notícia NÃO for sobre esporte ("jogo do Corinthians").
CONTEXTUAL: dict[str, list[str]] = {
    "Games": ["jogo", "jogos", "fifa"],
}

# Contexto esportivo, que anula as palavras de CONTEXTUAL.
SPORTS_WORDS = [
    "futebol", "brasileirao", "campeonato", "libertadores", "copa do mundo",
    "selecao", "rodada", "torcida", "estadio", "flamengo", "corinthians",
    "palmeiras", "nba", "formula 1", "olimpiadas",
]

# Frases que parecem do nosso tema, mas não são ("golpe de Estado").
FALSE_FRIENDS = ["golpe de estado", "golpe militar", "golpe de misericordia"]

CATEGORIES: list[str] = [*KEYWORDS, DEFAULT_CATEGORY]

_PATTERNS = {
    category: re.compile(r"\b(" + "|".join(map(re.escape, words)) + r")\b")
    for category, words in KEYWORDS.items()
}


def _compile(words: list[str]) -> re.Pattern[str]:
    return re.compile(r"\b(" + "|".join(map(re.escape, words)) + r")\b")


_CONTEXTUAL_PATTERNS = {category: _compile(words) for category, words in CONTEXTUAL.items()}
_SPORTS = _compile(SPORTS_WORDS)
_FALSE_FRIENDS = _compile(FALSE_FRIENDS)


def normalize(text: str) -> str:
    """Minúsculas e sem acentos, para comparar 'Segurança' com 'seguranca'."""
    decomposed = unicodedata.normalize("NFKD", text.lower())
    return "".join(c for c in decomposed if not unicodedata.combining(c))


def categorize(title: str, summary: str = "", tags: list[str] | None = None) -> str:
    """Pontua cada categoria; palavras no título valem o dobro."""
    title_norm = _FALSE_FRIENDS.sub(" ", normalize(title))
    body_norm = _FALSE_FRIENDS.sub(" ", normalize(" ".join([summary, *(tags or [])])))
    is_sports = bool(_SPORTS.search(title_norm) or _SPORTS.search(body_norm))

    best, best_score = DEFAULT_CATEGORY, 0
    for category, pattern in _PATTERNS.items():
        score = 2 * len(pattern.findall(title_norm)) + len(pattern.findall(body_norm))
        extra = _CONTEXTUAL_PATTERNS.get(category)
        if extra and not is_sports:
            score += 2 * len(extra.findall(title_norm)) + len(extra.findall(body_norm))
        if score > best_score:
            best, best_score = category, score
    return best
