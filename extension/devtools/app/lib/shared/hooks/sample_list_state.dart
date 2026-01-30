import 'package:flutter/material.dart';
import 'package:oref/devtools.dart';
import 'package:oref/oref.dart' as oref;

import '../../app/constants.dart';
import '../utils/helpers.dart';
import 'search_query.dart';

class SampleListState {
  SampleListState({
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
  final oref.WritableSignal<SortKey> sortKey;
  final oref.WritableSignal<bool> sortAscending;

  void toggleSelection(int id) {
    selectedId.set(selectedId() == id ? null : id);
  }

  void toggleSort(SortKey key) {
    if (sortKey() == key) {
      sortAscending.set(!sortAscending());
    } else {
      sortKey.set(key);
      sortAscending.set(key == .name);
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
      (a, b) => compareSort(
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

SampleListState useSampleListState(
  BuildContext context, {
  required String debugLabelPrefix,
  Duration debounce = const Duration(milliseconds: 200),
  String initialStatus = 'All',
  SortKey initialSortKey = .updated,
  bool initialSortAscending = false,
}) {
  final searchState = useSearchQueryState(
    context,
    debugLabel: '$debugLabelPrefix.search',
    debounce: debounce,
  );
  final statusFilter = oref.signal(
    context,
    initialStatus,
    debugLabel: '$debugLabelPrefix.statusFilter',
  );
  final selectedId = oref.signal<int?>(
    context,
    null,
    debugLabel: '$debugLabelPrefix.selected',
  );
  final sortKey = oref.signal(
    context,
    initialSortKey,
    debugLabel: '$debugLabelPrefix.sortKey',
  );
  final sortAscending = oref.signal(
    context,
    initialSortAscending,
    debugLabel: '$debugLabelPrefix.sortAscending',
  );
  return SampleListState(
    searchController: searchState.controller,
    searchQuery: searchState.query,
    statusFilter: statusFilter,
    selectedId: selectedId,
    sortKey: sortKey,
    sortAscending: sortAscending,
  );
}
