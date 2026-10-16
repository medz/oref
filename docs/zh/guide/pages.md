# Pages

Pages 管理不可变累计列表与可空下一页游标；游标类型 C 必须非空。
业务提供 loader 与 nextCursor，库不猜测页大小、最后 ID、去重或服务端结束规则。

下面的组件片段从内存中分页取出 30 个 ID，完整展示加载、追加与错误显示：

```dart
PagesBuilder<int, int, int>.create(
  source: () => 10,
  load: (take, cursor, request) async {
    final start = cursor ?? 0;
    return [for (var id = start; id < start + take && id < 30; id++) id];
  },
  nextCursor: (take, page) =>
      page.isEmpty || page.last == 29 ? null : page.last + 1,
  builder: (context, state, pages) => Column(
    children: [
      if (state.phase != PagePhase.idle) const LinearProgressIndicator(),
      if (state.error != null) Text('${state.error}'),
      Expanded(
        child: ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (_, index) => Text('Item ${state.items[index]}'),
        ),
      ),
      if (state.nextError != null) Text('${state.nextError}'),
      TextButton(
        onPressed: state.phase == PagePhase.idle && state.hasNext
            ? () => pages.loadMore().ignore()
            : null,
        child: const Text('Load more'),
      ),
      TextButton(
        onPressed: () => pages.refresh().ignore(),
        child: const Text('Refresh first page'),
      ),
    ],
  ),
)
```

## 行为

- ensureLoaded/refresh 返回本次第一页，loadMore 返回本次新增页；累计列表读取 state.items。
- phase 只会是 idle、initial、refresh、append 之一。刷新优先于追加，废弃旧追加结果，
  只重新取第一页。
- error/stackTrace 属于首屏或刷新；nextError/nextStackTrace 属于追加。
  追加失败保留列表与可重试游标。
- nextCursor 返回 null 表示结束。空页必须结束；空页仍给游标或重复旧游标属于 StateError，
  不修改已经加载的列表。
- 首次激活前 loadMore 返回 notReady；成功读到末尾后返回不可变空列表，零额外请求。
- 重复进行中追加共用 Future，相同输入的进行中刷新也合并。

惰性 itemBuilder 捕获本次不可变快照；它稍后执行时不负责建立父 Builder 的响应订阅。
平铺不可变列表追加会复制累计条目，应结合真实列表分配和布局成本判断是否需要额外优化。
另见[生命周期](./flutter.md)和[物理请求取消](./errors.md)。
