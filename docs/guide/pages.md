# Pages

Pages manages an immutable accumulated list and a nullable next cursor. C must be
a nonnullable cursor type. The application supplies the loader and nextCursor;
Oref does not infer page size, IDs, deduplication, or a backend's end condition.

This complete widget fragment uses a finite in-memory list of 30 IDs:

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

## Behavior

- ensureLoaded and refresh return the first page; loadMore returns only the
  appended page. Read the current accumulated list from state.items.
- phase is one of idle, initial, refresh, append. Refresh supersedes append,
  invalidates its old result, and reloads only the first page.
- error/stackTrace belong to the first page or refresh. nextError/nextStackTrace
  belong to append. Append failure preserves the list and retry cursor.
- nextCursor returns null to finish. Empty pages must also return null. An empty
  page with a next cursor or a repeated cursor fails with StateError and preserves
  already loaded items.
- loadMore before initial activation returns notReady. After a successful
  exhausted page it returns an immutable empty list without another request.
- Repeated pending appends reuse one Future. Same-input refresh calls coalesce.

The example captures this build's immutable state in itemBuilder. It does not
expect a later lazy callback to establish the parent's reactive subscriptions.
Appending a flat immutable list copies accumulated items; measure large-list
allocation and layout in the real application before adding another abstraction.

See [ownership](./flutter.md) for value/shared constructors and
[cancellation](./errors.md) for preventing obsolete physical requests.
