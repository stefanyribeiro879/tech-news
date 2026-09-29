import 'dart:async';

import 'package:flutter/material.dart';

import 'news_api.dart';
import 'theme.dart';
import 'widgets.dart';

// ======================================================
// TELA EXPLORAR
// Sem texto: mosaico de temas + mais recentes. Com texto: busca na API.
// ======================================================

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final searchController = TextEditingController();

  String search = '';
  String? topicFilter; // tema escolhido no mosaico
  List<NewsArticle> results = [];
  bool loading = true;
  String? error;
  int _request = 0;

  // Espera o usuário parar de digitar antes de chamar a API.
  Timer? debounce;

  bool get isSearching => search.length >= 2;

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void onSearchChanged(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 400), () {
      search = value.trim();
      load();
    });
  }

  void clearSearch() {
    debounce?.cancel();
    searchController.clear();
    search = '';
    load();
  }

  void chooseTopic(String? category) {
    setState(() {
      topicFilter = category;
    });
    load();
  }

  Future<void> load() async {
    final request = ++_request;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = isSearching
          ? await NewsApi.search(search)
          : await NewsApi.latest(category: topicFilter, limit: 40);
      if (!mounted || request != _request) return;

      setState(() {
        results = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: ListView(
        padding: pagePadding(context, top: 16),
        children: [
          const Text(
            'Explorar',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Procure um assunto ou passeie pelos temas.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),

          const SizedBox(height: 18),

          ListenableBuilder(
            listenable: searchController,
            builder: (context, _) => TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Ex.: iPhone, ChatGPT, golpe no Pix...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        onPressed: clearSearch,
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          if (!isSearching) ...[
            const SectionHeader(title: 'Temas'),
            _TopicGrid(selected: topicFilter, onSelect: chooseTopic),
            const SizedBox(height: 26),
          ],

          SectionHeader(
            title: isSearching
                ? 'Resultados para "$search"'
                : topicFilter ?? 'Mais recentes',
            topic: !isSearching && topicFilter != null
                ? topicOf(topicFilter!)
                : null,
            actionLabel: !isSearching && topicFilter != null
                ? 'Ver todos'
                : null,
            onAction: () => chooseTopic(null),
          ),

          if (loading)
            const LoadingState(message: 'Procurando...')
          else if (error != null)
            EmptyState(
              emoji: '📡',
              title: 'Não conseguimos buscar agora',
              subtitle: error!,
              actionLabel: 'Tentar novamente',
              onAction: load,
            )
          else if (results.isEmpty)
            const EmptyState(
              emoji: '🔎',
              title: 'Nada encontrado',
              subtitle: 'Tente outra palavra, mais curta ou sem acento.',
            )
          else
            ...results.map((article) => NewsListTile(article: article)),
        ],
      ),
    );
  }
}

class _TopicGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _TopicGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 560 ? 3 : 2;
        final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: topics.map((topic) {
            final isSelected = selected == topic.category;

            return SizedBox(
              width: width,
              height: 92,
              child: Material(
                color: topic.background(context),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelect(isSelected ? null : topic.category),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? topic.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(topic.icon, color: topic.foreground(context)),
                        Text(
                          topic.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: topic.foreground(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
