import 'dart:async';

import 'package:flutter/material.dart' hide Action;
import 'package:oref/flutter.dart';

enum ArticleCategory {
  technology('技术'),
  lifestyle('生活');

  const ArticleCategory(this.label);
  final String label;
}

class Article {
  const Article({required this.id, required this.title, required this.body});

  final int id;
  final String title;
  final String body;
}

typedef ArticleSource = ({ArticleCategory category, int take});
typedef ArticleRead = ({
  ArticleCategory category,
  int take,
  int? after,
  ReadReason reason,
});

/// A finite in-memory service; the call log records actual loader calls.
class DemoArticleApi {
  DemoArticleApi({this.delay = const Duration(milliseconds: 250)});

  final Duration delay;
  final calls = <ArticleRead>[];
  bool failNextAppend = false;

  static final data = <ArticleCategory, List<Article>>{
    for (final category in ArticleCategory.values)
      category: List<Article>.unmodifiable([
        for (var index = 1; index <= 7; index++)
          Article(
            id: (category.index + 1) * 100 + index,
            title: '${category.label}文章 $index',
            body: '这是${category.label}分类的第 $index 篇模拟文章。',
          ),
      ]),
  };

  Future<List<Article>> read(
    ArticleSource source,
    int? after,
    ReadRequest request,
  ) async {
    calls.add((
      category: source.category,
      take: source.take,
      after: after,
      reason: request.reason,
    ));
    final fail = after != null && failNextAppend;
    if (fail) failNextAppend = false;
    final ready = Completer<void>();
    final timer = Timer(delay, ready.complete);
    final cancellation = request.onCancel(() {
      timer.cancel();
      if (!ready.isCompleted) {
        ready.completeError(StateError('Read cancelled'));
      }
    });
    try {
      await ready.future;
      if (fail) throw StateError('模拟追加失败');
      final articles = data[source.category]!;
      final previous = after == null
          ? -1
          : articles.indexWhere((article) => article.id == after);
      if (after != null && previous == -1) {
        throw StateError('Unknown article cursor: $after');
      }
      final start = previous + 1;
      final end = start + source.take;
      return articles.sublist(
        start,
        end > articles.length ? articles.length : end,
      );
    } finally {
      cancellation.dispose();
      timer.cancel();
    }
  }
}

/// Local filtering and paging, with the complete resource protocol in the UI.
class ArticlePagesPage extends StatelessWidget {
  const ArticlePagesPage({super.key, this.api});

  final DemoArticleApi? api;

  @override
  Widget build(BuildContext context) =>
      StateBuilder<({Value<ArticleCategory> category, DemoArticleApi api})>(
        create: () => (
          category: Value(ArticleCategory.technology),
          api: api ?? DemoArticleApi(),
        ),
        builder: (context, local) => Scaffold(
          appBar: AppBar(
            title: const Text('文章分页'),
            actions: [
              IconButton(
                tooltip: '让下次追加失败',
                onPressed: () {
                  local.api.failNextAppend = true;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('下一次追加将失败，可在页尾重试。')),
                  );
                },
                icon: const Icon(Icons.bug_report_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButton<ArticleCategory>(
                  key: const ValueKey('article-category'),
                  isExpanded: true,
                  value: local.category.value,
                  items: [
                    for (final category in ArticleCategory.values)
                      DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                  ],
                  onChanged: (category) {
                    if (category != null) local.category.value = category;
                  },
                ),
              ),
              Expanded(
                child: PagesBuilder<ArticleSource, Article, int>.create(
                  source: () => (category: local.category.value, take: 3),
                  load: local.api.read,
                  nextCursor: (source, page) =>
                      page.length < source.take ? null : page.last.id,
                  builder: (context, state, pages) => RefreshIndicator(
                    key: const ValueKey('article-refresh'),
                    onRefresh: () async {
                      try {
                        await pages.refresh();
                      } catch (_) {
                        // This operation's error is displayed below.
                      }
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (state.phase == PagePhase.initial)
                          const LinearProgressIndicator(),
                        if (state.error != null) ...[
                          Text('读取失败：${state.error}'),
                          TextButton(
                            onPressed: () => pages.refresh().ignore(),
                            child: const Text('重试读取'),
                          ),
                        ],
                        for (final article in state.items)
                          ListTile(
                            key: ValueKey('article-${article.id}'),
                            title: Text(article.title),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ArticleDetailPage(article: article),
                              ),
                            ),
                          ),
                        if (state.nextError != null) ...[
                          Text('追加失败：${state.nextError}'),
                          TextButton(
                            key: const ValueKey('article-retry-append'),
                            onPressed: state.phase == PagePhase.idle
                                ? () => pages.loadMore().ignore()
                                : null,
                            child: const Text('重试追加'),
                          ),
                        ] else if (state.hasLoaded && state.hasNext)
                          OutlinedButton(
                            key: const ValueKey('article-load-more'),
                            onPressed: state.phase == PagePhase.idle
                                ? () => pages.loadMore().ignore()
                                : null,
                            child: Text(
                              state.phase == PagePhase.append
                                  ? '正在加载…'
                                  : '加载更多',
                            ),
                          ),
                        if (state.hasLoaded && !state.hasNext)
                          const Text('已加载全部文章'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('文章详情')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(article.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Text(article.body),
        ],
      ),
    ),
  );
}
