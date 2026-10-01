"""Limpeza do corpo das notícias: trechos reduzidos dos feeds reais."""

from app.sources.cleaner import clean_article_html


def test_remove_widget_de_oferta_e_aviso_de_afiliado():
    raw = """
    <div class="widget-produto"><div class="oferta"><a href="https://tecno.click/x"
      rel="sponsored nofollow">28% OFF Ver preço</a><ul><li>Tela OLED</li></ul></div>
      <div class="widget-footer">Participe dos canais de ofertas do Achados do TB</div></div>
    <p>O console está saindo <a href="https://tecno.click/x" rel="sponsored">por R$ 1.952</a>.</p>
    <p><span class="aviso-etica"><a href="https://tecnoblog.net/etica/">Aviso de ética:</a>
      ao clicar em um link de afiliado, recebemos uma comissão.</span></p>
    <p><a href="https://tecnoblog.net/achados/outra">Outra oferta imperdível</a></p>
    """
    assert clean_article_html(raw) == "O console está saindo por R$ 1.952."


def test_remove_resumo_indice_e_legendas():
    raw = """
    <figure><img src="https://x/a.jpg"><figcaption>Legenda (imagem: Fulano)</figcaption></figure>
    <details class="tb-resumo">Resumo<ul><li>Tópico repetido.</li></ul></details>
    <div class="wp-block-yoast-seo-table-of-contents"><h2>Índice</h2>
      <ul><li><a href="#a">Parte 1</a></li></ul></div>
    <p>Texto da matéria.</p>
    <h2>Parte 1</h2>
    <p>Mais texto.</p>
    """
    assert clean_article_html(raw) == "Texto da matéria.\n\nParte 1\n\nMais texto."


def test_remove_chamadas_para_outras_materias():
    raw = """
    <p>Primeiro parágrafo.</p>
    <ul><li><a href="https://wa.me/x">📱 Veja as melhores promoções no WhatsApp do CT Ofertas</a></li></ul>
    <p><strong>Leia mais:</strong></p>
    <ul><li><a href="https://o.com/1">Notícia um</a></li><li><a href="https://o.com/2">Notícia dois</a></li></ul>
    <p>Veja também no <strong>Canaltech</strong>: <a href="https://c.com/x">Outra</a></p>
    <p>{{WHATSAPP_CHANNEL}}</p>
    <p>Último parágrafo.</p>
    <p>O post <a href="https://o.com/p">Título</a> apareceu primeiro em <a href="https://o.com">Olhar Digital</a>.</p>
    """
    assert clean_article_html(raw) == "Primeiro parágrafo.\n\nÚltimo parágrafo."


def test_remove_card_de_produto_patrocinado():
    raw = """
    <p>Reunimos três opções em promoção.</p>
    <div style="border: 1px solid #eee"><h3>Fone X</h3><p>Bom fone.</p>
      <a href="https://amazon.com.br/dp/1" rel="noopener sponsored">Ver na Amazon →</a></div>
    <p>As ofertas mudam rápido.</p>
    """
    assert clean_article_html(raw) == "Reunimos três opções em promoção.\n\nAs ofertas mudam rápido."


def test_mantem_listas_da_materia_com_marcador():
    raw = "<p>Como fazer:</p><ul><li>Abra o app;</li><li>Toque em <a href='https://x'>Ajustes</a>.</li></ul>"
    assert clean_article_html(raw) == "Como fazer:\n\n• Abra o app;\n\n• Toque em Ajustes."


def test_g1_tira_legenda_do_topo_creditos_e_manchetes_do_fim():
    raw = (
        '<img src="https://g1/x.jpg" /><br />     Manchete de outra notícia\n'
        "Primeiro parágrafo da matéria.\n"
        "🗒️ Tem alguma sugestão de reportagem? Mande para o g1\n"
        "Foto do evento em São Paulo\n"
        "Reprodução/TV Globo\n"
        "Segundo parágrafo.\n"
        "*Com informações da Reuters.\n"
        "Outra manchete relacionada do g1\n"
        "Cybercrime; hacker; crimes digitais\n"
    )
    assert clean_article_html(raw) == (
        "Primeiro parágrafo da matéria.\nSegundo parágrafo.\n*Com informações da Reuters."
    )


def test_nao_apaga_resumo_curto_sem_ponto_final():
    raw = "<p>Galaxy S25 atinge um dos menores preços recentes</p><p><a href='https://t/x'>Galaxy S25</a></p>"
    assert clean_article_html(raw) == "Galaxy S25 atinge um dos menores preços recentes"


def test_texto_vazio():
    assert clean_article_html("") == ""
    assert clean_article_html("   ") == ""
