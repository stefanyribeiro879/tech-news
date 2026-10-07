import pytest

from app.services.categorizer import DEFAULT_CATEGORY
from app.services.scope import is_in_scope


def test_categoria_especifica_sempre_entra():
    assert is_in_scope("OpenAI lança modelo", "", "Inteligência Artificial", strict=True)


@pytest.mark.parametrize(
    "title",
    [
        "Startup brasileira cria chip para satélites",
        "Google anuncia novo recurso no Chrome",
        "Anatel aprova nova regra para a fibra óptica",
    ],
)
def test_geral_com_termo_de_tecnologia_entra_mesmo_em_feed_estrito(title):
    assert is_in_scope(title, "", DEFAULT_CATEGORY, strict=True)


@pytest.mark.parametrize(
    "title",
    [
        "Governo anuncia pacote para a saúde",
        "Flamengo vence e assume a liderança",
        "Famosos que passaram o fim de semana em Trancoso",
    ],
)
def test_geral_sem_tecnologia_sai_em_feed_estrito(title):
    assert not is_in_scope(title, "Texto qualquer.", DEFAULT_CATEGORY, strict=True)


def test_feed_de_tecnologia_barra_assunto_claramente_alheio():
    assert not is_in_scope("Flamengo vence o Brasileirão", "", DEFAULT_CATEGORY)


def test_feed_de_tecnologia_mantem_geral_neutro():
    # Sem termo de tecnologia nem assunto alheio: confia na fonte.
    assert is_in_scope("Empresa anuncia resultado trimestral", "", DEFAULT_CATEGORY)
