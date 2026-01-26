part of '../main.dart';

class _CollectionsPanelStateData {
  _CollectionsPanelStateData({
    required this.searchController,
    required this.searchQuery,
    required this.typeFilter,
    required this.opFilter,
    required this.sortKey,
    required this.sortAscending,
  });

  final TextEditingController searchController;
  final oref.WritableSignal<String> searchQuery;
  final oref.WritableSignal<String> typeFilter;
  final oref.WritableSignal<String> opFilter;
  final oref.WritableSignal<_SortKey> sortKey;
  final oref.WritableSignal<bool> sortAscending;

  void toggleSort(_SortKey key) {
    if (sortKey() == key) {
      sortAscending.set(!sortAscending());
    } else {
      sortKey.set(key);
      sortAscending.set(key == _SortKey.name);
    }
  }

  List<Sample> filter(List<Sample> entries) {
    final query = searchQuery().trim().toLowerCase();
    final typeValue = typeFilter();
    final opValue = opFilter();
    final currentSortKey = sortKey();
    final ascending = sortAscending();
    final filtered = entries.where((entry) {
      final matchesQuery =
          query.isEmpty || entry.label.toLowerCase().contains(query);
      final matchesType = typeValue == 'All' || entry.type == typeValue;
      final operation = entry.operation ?? 'Idle';
      final matchesOp = opValue == 'All' || operation == opValue;
      return matchesQuery && matchesType && matchesOp;
    }).toList();
    filtered.sort(
      (a, b) => _compareSort(
        currentSortKey,
        ascending,
        a.label,
        b.label,
        a.updatedAt,
        b.updatedAt,
        a.id,
        b.id,
      ),
    );
    return filtered;
  }
}

_CollectionsPanelStateData _useCollectionsPanelState(BuildContext context) {
  final searchController = oref.useMemoized(
    context,
    () => TextEditingController(),
  );
  final searchQuery = oref.signal(
    context,
    '',
    debugLabel: 'collections.search',
  );
  final typeFilter = oref.signal(
    context,
    'All',
    debugLabel: 'collections.typeFilter',
  );
  final opFilter = oref.signal(
    context,
    'All',
    debugLabel: 'collections.opFilter',
  );
  final sortKey = oref.signal(
    context,
    _SortKey.updated,
    debugLabel: 'collections.sortKey',
  );
  final sortAscending = oref.signal(
    context,
    false,
    debugLabel: 'collections.sortAscending',
  );
  final searchListener = oref.useMemoized(context, () {
    void listener() {
      searchQuery.set(searchController.text);
    }

    searchController.addListener(listener);
    return listener;
  });
  oref.onUnmounted(context, () {
    searchController.removeListener(searchListener);
    searchController.dispose();
  });
  return _CollectionsPanelStateData(
    searchController: searchController,
    searchQuery: searchQuery,
    typeFilter: typeFilter,
    opFilter: opFilter,
    sortKey: sortKey,
    sortAscending: sortAscending,
  );
}
