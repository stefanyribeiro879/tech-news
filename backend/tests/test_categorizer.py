import pytest

from app.services.categorizer import DEFAULT_CATEGORY, categorize


@pytest.mark.parametrize(
    ("title", "expected"),
    [
        ("ChatGPT ganha nova função", "Inteligência Artificial"),
        ("Google lança IA para o Android", "Inteligência Artificial"),  # empate: IA vem primeiro
        ("iPhone 18 tem data de lançamento vazada", "Mobile"),
        ("GTA 6 ganha novo trailer no PlayStation", "Games"),
        ("Novo golpe usa phishing para roubar senhas", "Segurança"),
        ("Empresa anuncia resultado trimestral", DEFAULT_CATEGORY),
    ],
)
def test_categoria_pelo_titulo(title, expected):
    assert categorize(title) == expected


def test_ignora_acentos_e_maiusculas():
    assert categorize("SEGURANÇA em alta") == "Segurança"


def test_nao_confunde_palavras_parecidas():
    # "ia" não pode casar dentro de "dia" ou "notícia"
    assert categorize("Notícia do dia sobre economia") == DEFAULT_CATEGORY


def test_titulo_pesa_mais_que_resumo():
    assert categorize("Novo jogo de Nintendo", "O app usa IA") == "Games"
