part of '../main.dart';

class _ComputedPanelStateData {
  _ComputedPanelStateData({
    required this.searchController,
    required this.searchQuery,
    required this.statusFilter,
    required this.selectedId,
    required this.sortKey,
    required this.sortAscending,
  });

  final TextEditingController searchController;
  final oref.WritableSignal<String> searchQuery;
  final oref.WritableSignal<String> statusFilter;
  final oref.WritableSignal<int?> selectedId;
  final oref.WritableSignal<_SortKey> sortKey;
  final oref.WritableSignal<bool> sortAscending;

  void toggleSelection(int id) {
    selectedId.set(selectedId() == id ? null : id);
  }

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
    final currentStatus = statusFilter();
    final currentSortKey = sortKey();
    final ascending = sortAscending();
    final filtered = entries.where((entry) {
      final matchesQuery =
          query.isEmpty || entry.label.toLowerCase().contains(query);
      final status = entry.status ?? 'Active';
      final matchesStatus = currentStatus == 'All' || status == currentStatus;
      return matchesQuery && matchesStatus;
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

_ComputedPanelStateData _useComputedPanelState(BuildContext context) {
  final searchController = oref.useMemoized(
    context,
    () => TextEditingController(),
  );
  final searchQuery = oref.signal(context, '', debugLabel: 'computed.search');
  final statusFilter = oref.signal(
    context,
    'All',
    debugLabel: 'computed.statusFilter',
  );
  final selectedId = oref.signal<int?>(
    context,
    null,
    debugLabel: 'computed.selected',
  );
  final sortKey = oref.signal(
    context,
    _SortKey.updated,
    debugLabel: 'computed.sortKey',
  );
  final sortAscending = oref.signal(
    context,
    false,
    debugLabel: 'computed.sortAscending',
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
  return _ComputedPanelStateData(
    searchController: searchController,
    searchQuery: searchQuery,
    statusFilter: statusFilter,
    selectedId: selectedId,
    sortKey: sortKey,
    sortAscending: sortAscending,
  );
}
