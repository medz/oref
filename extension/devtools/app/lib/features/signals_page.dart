import 'package:flutter/material.dart';
import 'package:oref/devtools.dart';
import 'package:oref/oref.dart' as oref;

import '../app/constants.dart';
import '../app/palette.dart';
import '../app/scopes.dart';
import '../shared/hooks/search_query.dart';
import '../shared/utils/helpers.dart';
import '../shared/widgets/filter_group.dart';
import '../shared/widgets/glass.dart';
import '../shared/widgets/info_row.dart';
import '../shared/widgets/inline_empty_state.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/panel.dart';
import '../shared/widgets/sort_header_cell.dart';
import '../shared/widgets/status_badge.dart';

class SignalsPage extends StatelessWidget {
  const SignalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = useSignalsState(context);

    return oref.SignalBuilder(
      builder: (context) {
        return ConnectionGuard(
          child: PanelScrollView(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final controller = OrefDevToolsScope.of(context);
                final entries = samplesByKind(
                  controller.snapshot?.samples ?? const <Sample>[],
                  'signal',
                );
                final isSplit = constraints.maxWidth >= 980;
                final filtered = state.filter(entries);
                final selected = entries.firstWhereOrNull(
                  (entry) => entry.id == state.selectedId(),
                );
                final list = _SignalList(
                  entries: filtered,
                  selectedId: selected?.id,
                  isCompact: !isSplit,
                  sortKey: state.sortKey(),
                  sortAscending: state.sortAscending(),
                  onSortName: () => state.toggleSort(SortKey.name),
                  onSortUpdated: () => state.toggleSort(SortKey.updated),
                  onSelect: (entry) => state.toggleSelection(entry.id),
                );
                final detail = _SignalDetail(entry: selected);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: 'Signals',
                      description:
                          'Inspect live signal values, owners, and update cadence.',
                      filteredCount: filtered.length,
                      totalCount: entries.length,
                      onExport: () => exportData(
                        context,
                        'signals',
                        filtered.map((entry) => entry.toJson()).toList(),
                      ),
                      children: [
                        const SizedBox(height: 4),
                        GlassInput(
                          controller: state.searchController,
                          hintText: 'Search signals...',
                        ),
                        const SizedBox(height: 12),
                        FilterGroup(
                          label: 'Status',
                          filters: signalFilters,
                          selectedFilter: state.statusFilter(),
                          onFilterChange: state.statusFilter.set,
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isSplit)
                      selected == null
                          ? list
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: list),
                                const SizedBox(width: 20),
                                SizedBox(width: 320, child: detail),
                              ],
                            )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          list,
                          if (selected != null) ...[
                            const SizedBox(height: 16),
                            detail,
                          ],
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class SignalsState {
  SignalsState({
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
      sortAscending.set(key == SortKey.name);
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

SignalsState useSignalsState(BuildContext context) {
  final searchState = useSearchQueryState(
    context,
    debugLabel: 'signals.search',
    debounce: const Duration(milliseconds: 200),
  );
  final statusFilter = oref.signal(
    context,
    'All',
    debugLabel: 'signals.statusFilter',
  );
  final selectedId = oref.signal<int?>(
    context,
    null,
    debugLabel: 'signals.selected',
  );
  final sortKey = oref.signal(
    context,
    SortKey.updated,
    debugLabel: 'signals.sortKey',
  );
  final sortAscending = oref.signal(
    context,
    false,
    debugLabel: 'signals.sortAscending',
  );
  return SignalsState(
    searchController: searchState.controller,
    searchQuery: searchState.query,
    statusFilter: statusFilter,
    selectedId: selectedId,
    sortKey: sortKey,
    sortAscending: sortAscending,
  );
}

class _SignalList extends StatelessWidget {
  const _SignalList({
    required this.entries,
    required this.selectedId,
    required this.isCompact,
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
    required this.onSelect,
  });

  final List<Sample> entries;
  final int? selectedId;
  final bool isCompact;
  final SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;
  final ValueChanged<Sample> onSelect;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact)
            _SignalTableHeader(
              sortKey: sortKey,
              sortAscending: sortAscending,
              onSortName: onSortName,
              onSortUpdated: onSortUpdated,
            ),
          if (entries.isEmpty)
            const InlineEmptyState(
              message: 'No signals match the current filter.',
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < entries.length; index++) ...[
                    _SignalRow(
                      entry: entries[index],
                      isSelected: selectedId == entries[index].id,
                      isCompact: isCompact,
                      onTap: () => onSelect(entries[index]),
                    ),
                    if (index != entries.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SignalTableHeader extends StatelessWidget {
  const _SignalTableHeader({
    required this.sortKey,
    required this.sortAscending,
    required this.onSortName,
    required this.onSortUpdated,
  });

  final SortKey sortKey;
  final bool sortAscending;
  final VoidCallback onSortName;
  final VoidCallback onSortUpdated;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SortHeaderCell(
              label: 'Name',
              isActive: sortKey == SortKey.name,
              ascending: sortAscending,
              onTap: onSortName,
              style: labelStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Value', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Type', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Text('Status', style: labelStyle),
            ),
          ),
          Expanded(
            flex: 2,
            child: SortHeaderCell(
              label: 'Updated',
              isActive: sortKey == SortKey.updated,
              ascending: sortAscending,
              onTap: onSortUpdated,
              style: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.entry,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final Sample entry;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = isSelected
        ? OrefPalette.teal.withValues(alpha: 0.2)
        : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: highlight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? OrefPalette.teal.withValues(alpha: 0.4)
                  : colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.label),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(entry.type),
                        ),
                        StatusBadge(status: entry.status ?? 'Active'),
                        GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(formatAge(entry.updatedAt)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.value ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(entry.label, textAlign: TextAlign.center),
                          const SizedBox(height: 4),
                          Text(
                            entry.owner,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(entry.type, textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: StatusBadge(status: entry.status ?? 'Active'),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatAge(entry.updatedAt),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SignalDetail extends StatelessWidget {
  const _SignalDetail({required this.entry});

  final Sample? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Select a signal to view details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry!.label, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          StatusBadge(status: entry!.status ?? 'Active'),
          const SizedBox(height: 16),
          InfoRow(label: 'Owner', value: entry!.owner),
          InfoRow(label: 'Scope', value: entry!.scope),
          InfoRow(label: 'Type', value: entry!.type),
          InfoRow(label: 'Value', value: entry!.value ?? ''),
          InfoRow(label: 'Updated', value: formatAge(entry!.updatedAt)),
          InfoRow(label: 'Listeners', value: '${entry!.listeners ?? 0}'),
          InfoRow(label: 'Deps', value: '${entry!.dependencies ?? 0}'),
          if (entry!.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(entry!.note, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
