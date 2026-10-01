import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_settings.dart';
import 'news_api.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA DE LEITURA DA NOTÍCIA
// ======================================================

class ArticlePage extends StatefulWidget {
  final NewsArticle article;

  const ArticlePage({super.key, required this.article});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final scrollController = ScrollController();

  // Quanto da página já foi lido (0 a 1), para a barrinha do topo.
  final readProgress = ValueNotifier<double>(0);

  late final List<ArticleBlock> blocks = parseArticleBlocks(
    widget.article.content,
  );

  NewsArticle get article => widget.article;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(updateProgress);
  }

  @override
  void dispose() {
    scrollController.dispose();
    readProgress.dispose();
    super.dispose();
  }

  void updateProgress() {
    final position = scrollController.position;
    readProgress.value = position.maxScrollExtent <= 0
        ? 1
        : (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
  }

  // Muitos feeds trazem só o começo da matéria; o texto completo fica no site.
  // Abre o site dentro do app (navegador embutido do Android); se o aparelho
  // não suportar, cai para o navegador externo.
  Future<void> openOriginal(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final url = safeWebUri(article.url);
    if (url == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Link da matéria inválido.')),
      );
      return;
    }

    var opened = false;
    try {
      opened = await launchUrl(url, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      opened = await launchUrl(url, mode: LaunchMode.externalApplication);
    }

    if (!opened) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a matéria.')),
      );
    }
  }

  // Evita repetir o resumo quando o conteúdo já começa com ele.
  bool get showSummary {
    String clean(String text) =>
        text.replaceAll('…', '').replaceAll(RegExp(r'\s+'), ' ').trim();

    final summary = clean(article.summary);
    final content = clean(blocks.map((block) => block.text).join(' '));
    return summary.isNotEmpty && !content.startsWith(summary);
  }

  // Tempo estimado de leitura do texto disponível (~200 palavras por minuto).
  String get readingTime {
    final words = '${article.summary} ${article.content}'
        .split(RegExp(r'\s+'))
        .length;
    final minutes = (words / 200).ceil().clamp(1, 60);
    return '$minutes min de leitura';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: ListenableBuilder(
        listenable: appSettings,
        builder: (context, _) {
          final scale = appSettings.readingScale;

          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: colors.surface,
                leading: Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconButton(
                    tooltip: 'Voltar',
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.30),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Tamanho do texto',
                    onPressed: appSettings.nextReadingScale,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.30),
                    ),
                    icon: const Icon(
                      Icons.format_size_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  BookmarkButton(article: article, onImage: true),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      NewsImage(article: article, iconSize: 64),
                      // Escurece o topo (botões legíveis em fotos claras) e
                      // funde a base da foto com o fundo da página.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0, 0.3, 0.75, 1],
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.transparent,
                              Colors.transparent,
                              colors.surface.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: ValueListenableBuilder<double>(
                    valueListenable: readProgress,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      backgroundColor: Colors.transparent,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TopicPill(category: article.category),

                          const SizedBox(height: 14),

                          Text(
                            article.title,
                            style: TextStyle(
                              fontSize: 28 * scale,
                              height: 1.22,
                              letterSpacing: -0.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 18),

                          _SourceRow(article: article, readingTime: readingTime),

                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 22),

                          SelectionArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showSummary)
                                  _Lead(text: article.summary, scale: scale),
                                for (final block in blocks)
                                  _BlockView(
                                    block: block,
                                    scale: scale,
                                    category: article.category,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          _ContinueReading(
                            source: article.source,
                            onOpen: () => openOriginal(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Fonte, horário e tempo de leitura.
class _SourceRow extends StatelessWidget {
  final NewsArticle article;
  final String readingTime;

  const _SourceRow({required this.article, required this.readingTime});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: colors.primary.withValues(alpha: 0.14),
          child: Text(
            article.source.isNotEmpty ? article.source.substring(0, 1) : '?',
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.source,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${article.time} · $readingTime',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Resumo em destaque, antes do texto (o "olho" da matéria).
class _Lead extends StatelessWidget {
  final String text;
  final double scale;

  const _Lead({required this.text, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 22 * scale),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: context.accentGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18.5 * scale,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  color: context.colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockView extends StatelessWidget {
  final ArticleBlock block;
  final double scale;
  final String category;

  const _BlockView({
    required this.block,
    required this.scale,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final body = TextStyle(
      fontSize: 17.5 * scale,
      height: 1.75,
      letterSpacing: 0.1,
      color: colors.onSurface.withValues(alpha: 0.88),
    );

    return switch (block.kind) {
      ArticleBlockKind.heading => Padding(
        padding: EdgeInsets.only(top: 10 * scale, bottom: 12 * scale),
        child: Text(
          block.text,
          style: TextStyle(
            fontSize: 21 * scale,
            height: 1.3,
            fontWeight: FontWeight.w900,
            color: colors.onSurface,
          ),
        ),
      ),
      ArticleBlockKind.bullet => Padding(
        padding: EdgeInsets.only(left: 4, bottom: 10 * scale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 7,
              height: 7,
              // Centraliza a bolinha na primeira linha do texto.
              margin: EdgeInsets.only(top: 17.5 * scale * 1.75 / 2 - 3.5),
              decoration: BoxDecoration(
                color: topicOf(category).foreground(context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(block.text, style: body)),
          ],
        ),
      ),
      ArticleBlockKind.paragraph => Padding(
        padding: EdgeInsets.only(bottom: 20 * scale),
        child: Text(block.text, style: body),
      ),
    };
  }
}

// Convite para ler a matéria completa no site da fonte.
class _ContinueReading extends StatelessWidget {
  final String source;
  final VoidCallback onOpen;

  const _ContinueReading({required this.source, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quer continuar lendo?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'O texto acima é o trecho enviado pelo $source. '
            'A matéria completa abre aqui mesmo, no app.',
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.chrome_reader_mode_outlined),
            label: const Text('Ler matéria completa'),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// TEXTO DA NOTÍCIA EM BLOCOS
// O backend já entrega o texto limpo (backend/app/sources/cleaner.py). Aqui
// ele é dividido em parágrafos, subtítulos e itens de lista, e as chamadas
// mais comuns são tiradas de novo: as notícias salvas antes da limpeza
// continuam guardadas com elas no banco.
// ======================================================

enum ArticleBlockKind { paragraph, heading, bullet }

class ArticleBlock {
  final ArticleBlockKind kind;
  final String text;

  const ArticleBlock(this.kind, this.text);
}

final _junkLineRe = RegExp(
  r'^(leia|veja|confira|assista)\s+tamb[ée]m\b'
  r'|^leia\s+mais\b'
  r'|apareceu primeiro em'
  r'|\{\{\s*[A-Z_]+\s*\}\}'
  r'|aviso de [ée]tica|links? de afiliados?|programa de afiliados'
  r'|clique (aqui )?para (ler|ver|saber|ouvir|assistir)'
  r'|ct ofertas|canais de ofertas|achados do tb'
  r'|tem alguma sugest[ãa]o de reportagem|favorite o g1'
  r'|ver esse post no instagram|um post compartilhado por',
  caseSensitive: false,
);

final _sentenceEndRe = RegExp(r'''[.!?…:;"”'’»)]$''');
final _wordRe = RegExp(r'\w');

const _bullet = '• ';

List<ArticleBlock> parseArticleBlocks(String content) {
  final lines = content
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && _wordRe.hasMatch(line))
      .where((line) => !_junkLineRe.hasMatch(line))
      .toList();

  final blocks = <ArticleBlock>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    if (line.startsWith(_bullet)) {
      blocks.add(
        ArticleBlock(
          ArticleBlockKind.bullet,
          line.substring(_bullet.length).trim(),
        ),
      );
      continue;
    }

    // Subtítulo: linha curta, sem ponto final, entre parágrafos.
    final isHeading =
        i > 0 &&
        i < lines.length - 1 &&
        line.length <= 90 &&
        line.split(' ').length <= 14 &&
        !_sentenceEndRe.hasMatch(line);

    blocks.add(
      ArticleBlock(
        isHeading ? ArticleBlockKind.heading : ArticleBlockKind.paragraph,
        line,
      ),
    );
  }
  return blocks;
}
