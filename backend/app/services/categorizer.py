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
        "machine learning", "aprendizado de maquina", "chatbot", "ias",
    ],
    "Mobile": [
        "iphone", "android", "smartphone", "smartphones", "celular", "celulares",
        "galaxy", "xiaomi", "motorola", "ios", "ipad", "tablet", "whatsapp",
        "pixel", "redmi", "poco", "oneplus", "oppo", "realme", "huawei", "5g",
        "operadora", "operadoras",
    ],
    "Games": [
        "game", "games", "jogo", "jogos", "gamer", "playstation", "ps5", "xbox",
        "nintendo", "switch 2", "steam", "console", "gta", "fortnite",
        "minecraft", "esports",
    ],
    "Segurança": [
        "seguranca", "ciberseguranca", "hacker", "hackers", "ataque", "ataques",
        "ciberataque", "vazamento", "vazamentos", "golpe", "golpes", "malware",
        "ransomware", "phishing", "vulnerabilidade", "falha de seguranca",
        "senha", "senhas", "fraude", "fraudes", "virus", "spyware",
    ],
}

CATEGORIES: list[str] = [*KEYWORDS, DEFAULT_CATEGORY]

_PATTERNS = {
    category: re.compile(r"\b(" + "|".join(map(re.escape, words)) + r")\b")
    for category, words in KEYWORDS.items()
}


def normalize(text: str) -> str:
    """Minúsculas e sem acentos, para comparar 'Segurança' com 'seguranca'."""
    decomposed = unicodedata.normalize("NFKD", text.lower())
    return "".join(c for c in decomposed if not unicodedata.combining(c))


def categorize(title: str, summary: str = "", tags: list[str] | None = None) -> str:
    """Pontua cada categoria; palavras no título valem o dobro."""
    title_norm = normalize(title)
    body_norm = normalize(" ".join([summary, *(tags or [])]))

    best, best_score = DEFAULT_CATEGORY, 0
    for category, pattern in _PATTERNS.items():
        score = 2 * len(pattern.findall(title_norm)) + len(pattern.findall(body_norm))
        if score > best_score:
            best, best_score = category, score
    return best
