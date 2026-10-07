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
    assert categorize("SEGURANÇA DIGITAL em alta") == "Segurança"


def test_nao_confunde_palavras_parecidas():
    # "ia" não pode casar dentro de "dia" ou "notícia"
    assert categorize("Notícia do dia sobre economia") == DEFAULT_CATEGORY


def test_titulo_pesa_mais_que_resumo():
    assert categorize("Novo jogo de Nintendo", "O app usa IA") == "Games"


@pytest.mark.parametrize(
    "title",
    [
        "Corinthians vence jogo decisivo no Brasileirão",  # esporte, não Games
        "Ataque militar deixa feridos na fronteira",  # guerra, não Segurança
        "Segurança pública: governo anuncia novo plano",  # polícia, não Segurança
        "Golpe de Estado é discutido no Congresso",  # política, não Segurança
        "Novo vírus preocupa autoridades de saúde",  # saúde, não Segurança
    ],
)
def test_nao_confunde_assuntos_fora_do_tema(title):
    assert categorize(title) == DEFAULT_CATEGORY


def test_jogo_fora_do_esporte_continua_sendo_games():
    assert categorize("Novo jogo de terror chega ao PC") == "Games"
