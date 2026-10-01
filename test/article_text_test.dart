// Texto da notícia dividido em parágrafos, subtítulos e listas.
// Rodar com: flutter test

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_news/article_page.dart';

void main() {
  List<ArticleBlockKind> kinds(String text) =>
      parseArticleBlocks(text).map((block) => block.kind).toList();

  test('separa parágrafos, subtítulos e itens de lista', () {
    const content =
        'Primeiro parágrafo da matéria.\n\n'
        'Como ativar o recurso\n\n'
        'Siga os passos:\n\n'
        '• Abra o app;\n\n'
        '• Toque em Ajustes.\n\n'
        'Último parágrafo.';

    expect(kinds(content), [
      ArticleBlockKind.paragraph,
      ArticleBlockKind.heading,
      ArticleBlockKind.paragraph,
      ArticleBlockKind.bullet,
      ArticleBlockKind.bullet,
      ArticleBlockKind.paragraph,
    ]);
    expect(parseArticleBlocks(content)[3].text, 'Abra o app;');
  });

  test('primeira e última linha nunca viram subtítulo', () {
    expect(kinds('Resumo sem ponto\n\nTexto.\n\nFim sem ponto'), [
      ArticleBlockKind.paragraph,
      ArticleBlockKind.paragraph,
      ArticleBlockKind.paragraph,
    ]);
  });

  test('tira chamadas de notícias salvas antes da limpeza', () {
    const content =
        'Texto da matéria.\n\n'
        'Veja também no Canaltech: Outra notícia\n\n'
        '{{WHATSAPP_CHANNEL}}\n\n'
        '&\n\n'
        'O post Título apareceu primeiro em Olhar Digital.\n\n'
        'Fim da matéria.';

    expect(
      parseArticleBlocks(content).map((block) => block.text).toList(),
      ['Texto da matéria.', 'Fim da matéria.'],
    );
  });

  test('texto vazio não gera blocos', () {
    expect(parseArticleBlocks(''), isEmpty);
  });
}
