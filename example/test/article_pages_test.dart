import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oref/flutter.dart';
import 'package:oref_examples/article_pages.dart';

Future<void> finishRead(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first page and category changes use the same unkeyed adapter', (
    tester,
  ) async {
    final api = DemoArticleApi(delay: const Duration(milliseconds: 10));
    await tester.pumpWidget(MaterialApp(home: ArticlePagesPage(api: api)));
    await finishRead(tester);
    expect(api.calls, hasLength(1));
    expect(api.calls.single.category, ArticleCategory.technology);
    expect(api.calls.single.after, isNull);
    expect(api.calls.single.take, 3);
    expect(find.text('技术文章 1'), findsOneWidget);
    expect(find.text('技术文章 3'), findsOneWidget);
    expect(find.text('技术文章 4'), findsNothing);
    final element = tester.element(
      find.byType(PagesBuilder<ArticleSource, Article, int>),
    );

    await tester.tap(find.byKey(const ValueKey('article-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生活').last);
    await finishRead(tester);
    expect(
      identical(
        element,
        tester.element(find.byType(PagesBuilder<ArticleSource, Article, int>)),
      ),
      isTrue,
    );
    expect(api.calls, hasLength(2));
    expect(api.calls.last.category, ArticleCategory.lifestyle);
    expect(api.calls.last.after, isNull);
    expect(find.text('生活文章 1'), findsOneWidget);
    expect(find.text('技术文章 1'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'append failure preserves items and retries its original cursor',
    (tester) async {
      final api = DemoArticleApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(MaterialApp(home: ArticlePagesPage(api: api)));
      await finishRead(tester);
      api.failNextAppend = true;
      await tester.tap(find.byKey(const ValueKey('article-load-more')));
      await finishRead(tester);
      expect(find.textContaining('模拟追加失败'), findsOneWidget);
      expect(find.text('技术文章 1'), findsOneWidget);
      expect(find.text('技术文章 3'), findsOneWidget);
      expect(find.text('技术文章 4'), findsNothing);
      expect(api.calls, hasLength(2));
      expect(api.calls.last.after, 103);
      expect(api.calls.last.reason, ReadReason.append);

      await tester.tap(find.byKey(const ValueKey('article-retry-append')));
      await finishRead(tester);
      expect(api.calls, hasLength(3));
      expect(api.calls.last.after, 103);
      expect(find.textContaining('模拟追加失败'), findsNothing);
      expect(find.text('技术文章 1'), findsOneWidget);
      expect(find.text('技术文章 6'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'refresh reads only page one and navigation retains loaded pages',
    (tester) async {
      final api = DemoArticleApi(delay: const Duration(milliseconds: 10));
      await tester.pumpWidget(MaterialApp(home: ArticlePagesPage(api: api)));
      await finishRead(tester);
      await tester.tap(find.byKey(const ValueKey('article-load-more')));
      await finishRead(tester);
      expect(api.calls, hasLength(2));
      expect(find.text('技术文章 6'), findsOneWidget);

      await tester.tap(find.text('技术文章 1'));
      await tester.pumpAndSettle();
      expect(find.text('文章详情'), findsOneWidget);
      expect(find.text('这是技术分类的第 1 篇模拟文章。'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('技术文章 6'), findsOneWidget);
      expect(api.calls, hasLength(2));

      final refresh = tester.state<RefreshIndicatorState>(
        find.byKey(const ValueKey('article-refresh')),
      );
      refresh.show().ignore();
      await tester.pump(const Duration(milliseconds: 300));
      await finishRead(tester);
      expect(api.calls, hasLength(3));
      expect(api.calls.last.after, isNull);
      expect(api.calls.last.reason, ReadReason.refresh);
      expect(find.text('技术文章 1'), findsOneWidget);
      expect(find.text('技术文章 3'), findsOneWidget);
      expect(find.text('技术文章 4'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
