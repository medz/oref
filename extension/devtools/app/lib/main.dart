import 'dart:convert';
import 'dart:ui';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oref/devtools.dart';

import 'oref_service.dart';

void main() {
  runApp(const DevToolsExtension(child: OrefDevToolsApp()));
}

class OrefDevToolsApp extends StatelessWidget {
  const OrefDevToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Oref DevTools',
      theme: OrefTheme.light(),
      darkTheme: OrefTheme.dark(),
      themeMode: ThemeMode.system,
      home: const _DevToolsShell(),
    );
  }
}

class OrefDevToolsScope extends InheritedNotifier<OrefDevToolsController> {
  const OrefDevToolsScope({
    super.key,
    required OrefDevToolsController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static OrefDevToolsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<OrefDevToolsScope>();
    assert(scope != null, 'OrefDevToolsScope not found in widget tree.');
    return scope!.notifier!;
  }
}

class OrefTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: OrefPalette.teal,
      onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
      secondary: OrefPalette.indigo,
      onSecondary: Colors.white,
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      surface: brightness == Brightness.dark
          ? const Color(0xFF141B22)
          : const Color(0xFFFFFFFF),
      onSurface: brightness == Brightness.dark
          ? const Color(0xFFEAF2F8)
          : const Color(0xFF11161D),
      background: brightness == Brightness.dark
          ? const Color(0xFF0B1117)
          : const Color(0xFFF6F8FB),
      onBackground: brightness == Brightness.dark
          ? const Color(0xFFEAF2F8)
          : const Color(0xFF11161D),
    );

    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final textTheme = GoogleFonts.spaceGroteskTextTheme(baseTextTheme).copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: Colors.transparent,
      useMaterial3: true,
      dividerColor: brightness == Brightness.dark
          ? const Color(0xFF24313B)
          : const Color(0xFFE1E6EC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: const CardThemeData(color: Colors.transparent, elevation: 0),
    );
  }
}

class OrefPalette {
  static const Color teal = Color(0xFF22E3C4);
  static const Color tealDark = Color(0xFF14B6A1);
  static const Color indigo = Color(0xFF6C5CFF);
  static const Color coral = Color(0xFFFF8C6B);
  static const Color lime = Color(0xFFB5FF6D);
  static const Color pink = Color(0xFFFF71C6);
  static const Color deepBlue = Color(0xFF0C141C);
  static const Color lightBlue = Color(0xFFE7F3FF);
}

class _DevToolsShell extends StatefulWidget {
  const _DevToolsShell();

  @override
  State<_DevToolsShell> createState() => _DevToolsShellState();
}

class _DevToolsShellState extends State<_DevToolsShell> {
  String _selectedLabel = _navItems.first.label;
  late final OrefDevToolsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OrefDevToolsController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSelect(_NavItemData item) {
    if (item.label == _selectedLabel) return;
    setState(() => _selectedLabel = item.label);
  }

  void _openSettings() {
    final settings = _allNavItems.firstWhere(
      (item) => item.label == 'Settings',
      orElse: () => _utilityItems.last,
    );
    _handleSelect(settings);
  }

  _NavItemData get _selectedItem {
    return _allNavItems.firstWhere(
      (item) => item.label == _selectedLabel,
      orElse: () => _navItems.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = _selectedItem;

    return OrefDevToolsScope(
      controller: _controller,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1100;
          final padding = EdgeInsets.symmetric(
            horizontal: isWide ? 28 : 20,
            vertical: 20,
          );

          return Stack(
            children: [
              const _BackgroundLayer(),
              SafeArea(
                child: Padding(
                  padding: padding,
                  child: Column(
                    children: [
                      _TopBar(onOpenSettings: _openSettings),
                      const SizedBox(height: 20),
                      Expanded(
                        child: isWide
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 240,
                                    child: _SideNav(
                                      selectedLabel: _selectedLabel,
                                      onSelect: _handleSelect,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _MainPanel(
                                      selectedItem: selectedItem,
                                    ),
                                  ),
                                ],
                              )
                            : _CompactLayout(
                                selectedLabel: _selectedLabel,
                                onSelect: _handleSelect,
                                selectedItem: selectedItem,
                              ),
                      ),
                    ],
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

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.selectedLabel,
    required this.onSelect,
    required this.selectedItem,
  });

  final String selectedLabel;
  final ValueChanged<_NavItemData> onSelect;
  final _NavItemData selectedItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CompactNav(selectedLabel: selectedLabel, onSelect: onSelect),
        const SizedBox(height: 16),
        Expanded(child: _MainPanel(selectedItem: selectedItem)),
      ],
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final gradient = brightness == Brightness.dark
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1117), Color(0xFF111C24), Color(0xFF0B1117)],
          )
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F8FB), Color(0xFFFDF7F4), Color(0xFFF1F5FB)],
          );

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: const [
          _GlowBlob(
            alignment: Alignment.topLeft,
            size: 360,
            colors: [OrefPalette.teal, Colors.transparent],
          ),
          _GlowBlob(
            alignment: Alignment.topRight,
            size: 420,
            colors: [OrefPalette.indigo, Colors.transparent],
          ),
          _GlowBlob(
            alignment: Alignment.bottomCenter,
            size: 520,
            colors: [OrefPalette.coral, Colors.transparent],
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.alignment,
    required this.size,
    required this.colors,
  });

  final Alignment alignment;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(gradient: RadialGradient(colors: colors)),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final isCompact = MediaQuery.of(context).size.width < 900;
    final canInteract = controller.connected;
    final actions = <Widget>[
      _ActionPill(
        label: 'Refresh',
        icon: Icons.refresh_rounded,
        onTap: canInteract ? controller.refresh : null,
      ),
      _ActionPill(
        label: 'Clear',
        icon: Icons.delete_sweep_rounded,
        onTap: canInteract ? controller.clearHistory : null,
      ),
      _ActionPill(
        label: 'Settings',
        icon: Icons.tune_rounded,
        onTap: onOpenSettings,
      ),
    ];

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _BrandMark(),
                    const Spacer(),
                    _StatusPill(status: controller.status),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 12, runSpacing: 12, children: actions),
              ],
            )
          : Row(
              children: [
                const _BrandMark(),
                const SizedBox(width: 16),
                _StatusPill(status: controller.status),
                const Spacer(),
                for (var index = 0; index < actions.length; index++) ...[
                  actions[index],
                  if (index != actions.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [OrefPalette.teal, OrefPalette.indigo],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x6622E3C4),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.black),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Oref DevTools', style: textTheme.titleMedium),
            Text(
              'Signals • Effects • Collections',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final OrefServiceStatus status;

  @override
  Widget build(BuildContext context) {
    final tone = switch (status) {
      OrefServiceStatus.ready => OrefPalette.lime,
      OrefServiceStatus.connecting => OrefPalette.teal,
      OrefServiceStatus.unavailable => OrefPalette.coral,
      OrefServiceStatus.error => OrefPalette.pink,
      OrefServiceStatus.disconnected => const Color(0xFF8B97A8),
    };
    final label = switch (status) {
      OrefServiceStatus.ready => 'Connected',
      OrefServiceStatus.connecting => 'Connecting',
      OrefServiceStatus.unavailable => 'Extension missing',
      OrefServiceStatus.error => 'Connection error',
      OrefServiceStatus.disconnected => 'Disconnected',
    };

    return _GlassPill(
      color: tone.withOpacity(0.22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = isEnabled
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: _GlassPill(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.selectedLabel, required this.onSelect});

  final String selectedLabel;
  final ValueChanged<_NavItemData> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Panels', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          for (final item in _navItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NavItem(
                item: item,
                isActive: item.label == selectedLabel,
                onTap: () => onSelect(item),
              ),
            ),
          const Divider(height: 32),
          Text('Utilities', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          for (final item in _utilityItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NavItem(
                item: item,
                isActive: item.label == selectedLabel,
                onTap: () => onSelect(item),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactNav extends StatelessWidget {
  const _CompactNav({required this.selectedLabel, required this.onSelect});

  final String selectedLabel;
  final ValueChanged<_NavItemData> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in _navItems)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _NavItem(
                  item: item,
                  isActive: item.label == selectedLabel,
                  onTap: () => onSelect(item),
                ),
              ),
            const SizedBox(width: 8),
            for (final item in _utilityItems)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _NavItem(
                  item: item,
                  isActive: item.label == selectedLabel,
                  onTap: () => onSelect(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.item, required this.isActive, this.onTap});

  final _NavItemData item;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeGradient = LinearGradient(
      colors: [
        OrefPalette.teal.withOpacity(0.9),
        OrefPalette.indigo.withOpacity(0.9),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isActive ? activeGradient : null,
            color: isActive ? null : colorScheme.surface.withOpacity(0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : colorScheme.onSurface.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 18, color: isActive ? Colors.black : null),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isActive ? Colors.black : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainPanel extends StatelessWidget {
  const _MainPanel({required this.selectedItem});

  final _NavItemData selectedItem;

  @override
  Widget build(BuildContext context) {
    if (selectedItem.label == 'Overview') {
      return const _OverviewPanel();
    }
    if (selectedItem.label == 'Signals') {
      return const _SignalsPanel();
    }
    if (selectedItem.label == 'Computed') {
      return const _ComputedPanel();
    }
    if (selectedItem.label == 'Effects') {
      return const _EffectsPanel();
    }
    if (selectedItem.label == 'Collections') {
      return const _CollectionsPanel();
    }
    if (selectedItem.label == 'Batching') {
      return const _BatchingPanel();
    }
    if (selectedItem.label == 'Timeline') {
      return const _TimelinePanel();
    }
    if (selectedItem.label == 'Performance') {
      return const _PerformancePanel();
    }
    if (selectedItem.label == 'Settings') {
      return const _SettingsPanel();
    }

    final info =
        _panelInfo[selectedItem.label] ??
        _PanelInfo(
          title: selectedItem.label,
          description: 'This panel will be wired to live Oref diagnostics.',
          bullets: const [
            'Live data stream',
            'Filters + search',
            'Batch insights',
          ],
        );

    return _PanelPlaceholder(info: info, icon: selectedItem.icon);
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final controller = OrefDevToolsScope.of(context);
    final snapshot = controller.snapshot;
    final stats = snapshot?.stats;
    final signals = snapshot?.signals ?? const <OrefSignal>[];
    final computed = snapshot?.computed ?? const <OrefComputed>[];
    final effects = snapshot?.effects ?? const <OrefEffect>[];
    final collections = snapshot?.collections ?? const <OrefCollection>[];
    final batches = snapshot?.batches ?? const <OrefBatch>[];
    final performance =
        snapshot?.performance ?? const <OrefPerformanceSample>[];
    final settings = snapshot?.settings ?? const OrefDevToolsSettings();
    final canInteract = controller.connected;

    String summarizeTop<T>(
      List<T> entries,
      int Function(T entry) score,
      String Function(T entry) label,
    ) {
      final active = entries.where((entry) => score(entry) > 0).toList();
      if (active.isEmpty) return '—';
      active.sort((a, b) => score(b).compareTo(score(a)));
      return active.take(2).map(label).join(' · ');
    }

    List<int> tail(List<int> values, int count) {
      if (values.length <= count) return values;
      return values.sublist(values.length - count);
    }

    final topSignals = summarizeTop(
      signals,
      (entry) => entry.writes,
      (entry) => '${entry.label} (${entry.writes})',
    );
    final topComputed = summarizeTop(
      computed,
      (entry) => entry.runs,
      (entry) => '${entry.label} (${entry.runs})',
    );
    final hotEffects = summarizeTop(
      effects,
      (entry) => entry.lastDurationMs,
      (entry) => '${entry.label} (${entry.lastDurationMs}ms)',
    );
    final busyCollections = summarizeTop(
      collections,
      (entry) => entry.mutations,
      (entry) => '${entry.label} (${entry.mutations})',
    );

    final totalNodes = signals.length + computed.length + effects.length;
    final activeNodes =
        signals.where((entry) => entry.status != 'Disposed').length +
        computed.where((entry) => entry.status != 'Disposed').length +
        effects.where((entry) => entry.status != 'Disposed').length;
    final watchedNodes =
        signals.where((entry) => entry.listeners > 0).length +
        computed.where((entry) => entry.listeners > 0).length;

    int activityScore(OrefPerformanceSample sample) {
      return sample.signalWrites +
          sample.computedRuns +
          sample.effectRuns +
          sample.collectionMutations;
    }

    final lastSample = performance.isNotEmpty ? performance.last : null;
    final lastActivity = lastSample == null ? 0 : activityScore(lastSample);
    final maxActivity = performance.isEmpty
        ? 0
        : performance
              .map(activityScore)
              .reduce((value, element) => value > element ? value : element);
    final activityProgress = maxActivity == 0
        ? 0.0
        : lastActivity / maxActivity;
    final activityRate = settings.sampleIntervalMs == 0
        ? 0
        : (lastActivity * 60000 / settings.sampleIntervalMs).round();

    final signalPulseValues = tail(
      performance.map((sample) => sample.signalWrites).toList(),
      12,
    );
    final batchPulseValues = tail(
      batches.map((batch) => batch.writeCount).toList(),
      12,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            'Signal diagnostics, activity, and collection health in one place.',
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          _AdaptiveWrap(
            children: [
              _MetricTile(
                label: 'Signals',
                value: _formatCount(stats?.signals),
                trend: _formatDelta(stats?.signalWrites, suffix: 'upd'),
                accent: OrefPalette.teal,
                icon: Icons.bubble_chart_rounded,
              ),
              _MetricTile(
                label: 'Computed',
                value: _formatCount(stats?.computed),
                trend: _formatDelta(stats?.computedRuns, suffix: 'runs'),
                accent: OrefPalette.indigo,
                icon: Icons.schema_rounded,
              ),
              _MetricTile(
                label: 'Effects',
                value: _formatCount(stats?.effects),
                trend: _formatDelta(stats?.effectRuns, suffix: 'runs'),
                accent: OrefPalette.pink,
                icon: Icons.auto_awesome_motion_rounded,
              ),
              _MetricTile(
                label: 'Batches',
                value: _formatCount(stats?.batches),
                trend: _formatDelta(stats?.signalWrites, suffix: 'writes'),
                accent: OrefPalette.coral,
                icon: Icons.layers_rounded,
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 980;
              final insightCard = _InsightCard(
                title: 'Insights',
                subtitle: 'Highlights from the latest signal activity.',
                primary: [
                  _InsightRow('Most updated', topSignals),
                  _InsightRow('Hot effects', hotEffects),
                  _InsightRow('Busy collections', busyCollections),
                ],
                secondary: [
                  _InsightRow('Computed churn', topComputed),
                  _InsightRow(
                    'Active nodes',
                    totalNodes == 0 ? '—' : '$activeNodes / $totalNodes',
                  ),
                  _InsightRow('Last update', _formatAge(snapshot?.timestamp)),
                ],
              );
              final healthCard = _HealthCard(
                activeNodes: activeNodes,
                totalNodes: totalNodes,
                watchedNodes: watchedNodes,
                activityRate: activityRate,
                activityProgress: activityProgress,
              );

              return isStacked
                  ? Column(
                      children: [
                        insightCard,
                        const SizedBox(height: 20),
                        healthCard,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: insightCard),
                        const SizedBox(width: 20),
                        Expanded(child: healthCard),
                      ],
                    );
            },
          ),
          const SizedBox(height: 20),
          _GlassCard(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 860;
                final connectionInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connection', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Streaming updates from the active Flutter isolate. '
                      'Refresh to sync the latest snapshot or clear the '
                      'history for a new pass.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.65),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _GradientButton(
                          label: 'Refresh data',
                          onTap: canInteract ? controller.refresh : null,
                        ),
                        _OutlineButton(
                          label: 'Clear history',
                          onTap: canInteract ? controller.clearHistory : null,
                        ),
                      ],
                    ),
                  ],
                );

                final sessionCard = _GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session', style: textTheme.labelLarge),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Status',
                        value: controller.connected ? 'Connected' : 'Offline',
                      ),
                      _InfoRow(
                        label: 'Signals',
                        value: _formatCount(stats?.signals),
                      ),
                      _InfoRow(
                        label: 'Effects',
                        value: _formatCount(stats?.effects),
                      ),
                      _InfoRow(
                        label: 'Last update',
                        value: _formatAge(snapshot?.timestamp),
                      ),
                    ],
                  ),
                );

                return isStacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          connectionInfo,
                          const SizedBox(height: 20),
                          sessionCard,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: connectionInfo),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: sessionCard),
                        ],
                      );
              },
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 980;
              final leftColumn = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Signal Pulse', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _MiniChart(
                          values: signalPulseValues,
                          icon: Icons.stacked_line_chart_rounded,
                          caption: signalPulseValues.isEmpty
                              ? 'Awaiting samples'
                              : '${signalPulseValues.last} writes / sample',
                          color: OrefPalette.teal,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Track how signals refresh across the frame '
                          'timeline and spot hot paths early.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Batch Heatmap', style: textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _MiniChart(
                          values: batchPulseValues,
                          icon: Icons.grid_view_rounded,
                          caption: batchPulseValues.isEmpty
                              ? 'No batches recorded'
                              : '${batchPulseValues.last} writes last batch',
                          color: OrefPalette.indigo,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Spot dense write bursts and their scopes.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final activityCard = _GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Activity', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if ((snapshot?.timeline ?? []).isEmpty)
                      Text(
                        controller.isUnavailable
                            ? 'Enable Oref DevTools to capture activity.'
                            : 'No recent activity yet.',
                        style: textTheme.bodyMedium,
                      )
                    else
                      for (final event in snapshot!.timeline.reversed.take(6))
                        _TimelineRow(event: event),
                  ],
                ),
              );

              return isStacked
                  ? Column(
                      children: [
                        leftColumn,
                        const SizedBox(height: 20),
                        activityCard,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: leftColumn),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: activityCard),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _SignalsPanel extends StatefulWidget {
  const _SignalsPanel();

  @override
  State<_SignalsPanel> createState() => _SignalsPanelState();
}

class _SignalsPanelState extends State<_SignalsPanel> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ConnectionGuard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controller = OrefDevToolsScope.of(context);
          final entries = controller.snapshot?.signals ?? const <OrefSignal>[];
          final isSplit = constraints.maxWidth >= 980;
          final filtered = _filterSignals(entries);
          final selected =
              entries.firstWhereOrNull((entry) => entry.id == _selectedId) ??
              (entries.isNotEmpty ? entries.first : null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SignalsHeader(
                controller: _searchController,
                selectedFilter: _statusFilter,
                onFilterChange: (value) =>
                    setState(() => _statusFilter = value),
                totalCount: entries.length,
                filteredCount: filtered.length,
                onExport: () => _exportData(
                  context,
                  'signals',
                  filtered.map((entry) => entry.toJson()).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isSplit
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _SignalList(
                              entries: filtered,
                              selectedId: selected?.id,
                              isCompact: false,
                              onSelect: (entry) =>
                                  setState(() => _selectedId = entry.id),
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 320,
                            child: _SignalDetail(entry: selected),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _SignalList(
                              entries: filtered,
                              selectedId: selected?.id,
                              isCompact: true,
                              onSelect: (entry) =>
                                  setState(() => _selectedId = entry.id),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: _SignalDetail(entry: selected),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<OrefSignal> _filterSignals(List<OrefSignal> entries) {
    final query = _searchController.text.trim().toLowerCase();
    return entries.where((entry) {
      final matchesQuery =
          query.isEmpty || entry.label.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All' || entry.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }
}

class _ComputedPanel extends StatefulWidget {
  const _ComputedPanel();

  @override
  State<_ComputedPanel> createState() => _ComputedPanelState();
}

class _ComputedPanelState extends State<_ComputedPanel> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ConnectionGuard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final controller = OrefDevToolsScope.of(context);
          final entries =
              controller.snapshot?.computed ?? const <OrefComputed>[];
          final isSplit = constraints.maxWidth >= 980;
          final filtered = _filterComputed(entries);
          final selected =
              entries.firstWhereOrNull((entry) => entry.id == _selectedId) ??
              (entries.isNotEmpty ? entries.first : null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ComputedHeader(
                controller: _searchController,
                selectedFilter: _statusFilter,
                onFilterChange: (value) =>
                    setState(() => _statusFilter = value),
                totalCount: entries.length,
                filteredCount: filtered.length,
                onExport: () => _exportData(
                  context,
                  'computed',
                  filtered.map((entry) => entry.toJson()).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isSplit
                    ? Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _ComputedList(
                              entries: filtered,
                              selectedId: selected?.id,
                              isCompact: false,
                              onSelect: (entry) =>
                                  setState(() => _selectedId = entry.id),
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 320,
                            child: _ComputedDetail(entry: selected),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _ComputedList(
                              entries: filtered,
                              selectedId: selected?.id,
                              isCompact: true,
                              onSelect: (entry) =>
                                  setState(() => _selectedId = entry.id),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 220,
                            child: _ComputedDetail(entry: selected),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<OrefComputed> _filterComputed(List<OrefComputed> entries) {
    final query = _searchController.text.trim().toLowerCase();
    return entries.where((entry) {
      final matchesQuery =
          query.isEmpty || entry.label.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All' || entry.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }
}

class _ComputedHeader extends StatelessWidget {
  const _ComputedHeader({
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;
  final int totalCount;
  final int filteredCount;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Computed', style: textTheme.headlineSmall),
            const SizedBox(width: 12),
            const _GlassPill(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('Live'),
            ),
            const Spacer(),
            _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            _ActionPill(
              label: 'Export',
              icon: Icons.download_rounded,
              onTap: onExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Inspect derived state, cache hits, and dependency churn.',
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 16),
        _GlassInput(
          controller: controller,
          hintText: 'Search computed values...',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _signalFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == selectedFilter,
                onTap: () => onFilterChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}

class _ComputedList extends StatelessWidget {
  const _ComputedList({
    required this.entries,
    required this.selectedId,
    required this.isCompact,
    required this.onSelect,
  });

  final List<OrefComputed> entries;
  final int? selectedId;
  final bool isCompact;
  final ValueChanged<OrefComputed> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact) const _ComputedTableHeader(),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'No computed values match the current filter.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isSelected = selectedId == entry.id;
                      return _ComputedRow(
                        entry: entry,
                        isSelected: isSelected,
                        isCompact: isCompact,
                        onTap: () => onSelect(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComputedTableHeader extends StatelessWidget {
  const _ComputedTableHeader();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 0.4,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Name', style: labelStyle)),
          Expanded(flex: 2, child: Text('Value', style: labelStyle)),
          Expanded(flex: 2, child: Text('Status', style: labelStyle)),
          Expanded(flex: 2, child: Text('Runs', style: labelStyle)),
          Expanded(flex: 2, child: Text('Updated', style: labelStyle)),
        ],
      ),
    );
  }
}

class _ComputedRow extends StatelessWidget {
  const _ComputedRow({
    required this.entry,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final OrefComputed entry;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = isSelected
        ? OrefPalette.indigo.withOpacity(0.2)
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
                  ? OrefPalette.indigo.withOpacity(0.4)
                  : colorScheme.onSurface.withOpacity(0.08),
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
                        _StatusBadge(status: entry.status),
                        _GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text('${entry.runs} runs'),
                        ),
                        _GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(_formatAge(entry.updatedAt)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.label),
                          const SizedBox(height: 4),
                          Text(
                            entry.owner,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _StatusBadge(status: entry.status),
                    ),
                    Expanded(flex: 2, child: Text('${entry.runs}')),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAge(entry.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ComputedDetail extends StatelessWidget {
  const _ComputedDetail({required this.entry});

  final OrefComputed? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Select a computed value to view details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry!.label, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatusBadge(status: entry!.status),
            const SizedBox(height: 16),
            _InfoRow(label: 'Owner', value: entry!.owner),
            _InfoRow(label: 'Scope', value: entry!.scope),
            _InfoRow(label: 'Type', value: entry!.type),
            _InfoRow(label: 'Value', value: entry!.value),
            _InfoRow(label: 'Updated', value: _formatAge(entry!.updatedAt)),
            _InfoRow(label: 'Runs', value: entry!.runs.toString()),
            _InfoRow(label: 'Last run', value: '${entry!.lastDurationMs}ms'),
            _InfoRow(label: 'Listeners', value: entry!.listeners.toString()),
            _InfoRow(label: 'Deps', value: entry!.dependencies.toString()),
            if (entry!.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry!.note,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EffectsPanel extends StatefulWidget {
  const _EffectsPanel();

  @override
  State<_EffectsPanel> createState() => _EffectsPanelState();
}

class _CollectionsPanel extends StatefulWidget {
  const _CollectionsPanel();

  @override
  State<_CollectionsPanel> createState() => _CollectionsPanelState();
}

class _CollectionsPanelState extends State<_CollectionsPanel> {
  final _searchController = TextEditingController();
  String _typeFilter = 'All';
  String _opFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final entries =
        controller.snapshot?.collections ?? const <OrefCollection>[];
    final typeFilters = _buildFilterOptions(entries.map((entry) => entry.type));
    final opFilters = _buildFilterOptions(
      entries.map((entry) => entry.operation),
    );
    final filtered = entries.where((entry) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty || entry.label.toLowerCase().contains(query);
      final matchesType = _typeFilter == 'All' || entry.type == _typeFilter;
      final matchesOp = _opFilter == 'All' || entry.operation == _opFilter;
      return matchesQuery && matchesType && matchesOp;
    }).toList();

    return _ConnectionGuard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CollectionsHeader(
            controller: _searchController,
            typeFilter: _typeFilter,
            opFilter: _opFilter,
            typeFilters: typeFilters,
            opFilters: opFilters,
            onTypeChange: (value) => setState(() => _typeFilter = value),
            onOpChange: (value) => setState(() => _opFilter = value),
            totalCount: entries.length,
            filteredCount: filtered.length,
            onExport: () => _exportData(
              context,
              'collections',
              filtered.map((entry) => entry.toJson()).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;
                return _CollectionsList(
                  entries: filtered,
                  isCompact: isCompact,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchingPanel extends StatelessWidget {
  const _BatchingPanel();

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final batches = controller.snapshot?.batches ?? const <OrefBatch>[];
    final latest = batches.isNotEmpty ? batches.last : null;
    final totalWrites = batches.fold<int>(
      0,
      (sum, batch) => sum + batch.writeCount,
    );
    final avgDuration = batches.isEmpty
        ? 0
        : (batches.fold<int>(0, (sum, batch) => sum + batch.durationMs) /
                  batches.length)
              .round();

    return _ConnectionGuard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Batching',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              const _GlassPill(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('Live'),
              ),
              const Spacer(),
              _GlassPill(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text('${batches.length} batches'),
              ),
              const SizedBox(width: 12),
              _ActionPill(
                label: 'Export',
                icon: Icons.download_rounded,
                onTap: () => _exportData(
                  context,
                  'batches',
                  batches.map((batch) => batch.toJson()).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Inspect batched writes and flush timing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 16),
          _AdaptiveWrap(
            children: [
              _MetricTile(
                label: 'Batches',
                value: _formatCount(batches.length),
                trend: _formatDelta(totalWrites, suffix: 'writes'),
                accent: OrefPalette.coral,
                icon: Icons.layers_rounded,
              ),
              _MetricTile(
                label: 'Avg duration',
                value: '${avgDuration}ms',
                trend: latest == null ? '—' : _formatAge(latest.endedAt),
                accent: OrefPalette.indigo,
                icon: Icons.timer_rounded,
              ),
              _MetricTile(
                label: 'Last batch',
                value: latest == null ? '—' : '${latest.durationMs}ms',
                trend: latest == null ? '—' : '${latest.writeCount} writes',
                accent: OrefPalette.teal,
                icon: Icons.bolt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 860;
                return _BatchList(batches: batches, isCompact: isCompact);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchList extends StatelessWidget {
  const _BatchList({required this.batches, required this.isCompact});

  final List<OrefBatch> batches;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact) const _BatchHeaderRow(),
          Expanded(
            child: batches.isEmpty
                ? Center(
                    child: Text(
                      'No batches recorded yet.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: batches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final batch = batches[index];
                      return _BatchRow(batch: batch, isCompact: isCompact);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BatchHeaderRow extends StatelessWidget {
  const _BatchHeaderRow();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 0.4,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Batch', style: labelStyle)),
          Expanded(flex: 2, child: Text('Depth', style: labelStyle)),
          Expanded(flex: 2, child: Text('Writes', style: labelStyle)),
          Expanded(flex: 2, child: Text('Duration', style: labelStyle)),
          Expanded(flex: 3, child: Text('Ended', style: labelStyle)),
        ],
      ),
    );
  }
}

class _BatchRow extends StatelessWidget {
  const _BatchRow({required this.batch, required this.isCompact});

  final OrefBatch batch;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final subdued = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch #${batch.id}'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text('Depth ${batch.depth}'),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text('${batch.writeCount} writes'),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text('${batch.durationMs}ms'),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(_formatAge(batch.endedAt)),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 2, child: Text('Batch #${batch.id}')),
                Expanded(flex: 2, child: Text('${batch.depth}')),
                Expanded(flex: 2, child: Text('${batch.writeCount}')),
                Expanded(flex: 2, child: Text('${batch.durationMs}ms')),
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatAge(batch.endedAt),
                    style: TextStyle(color: subdued),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TimelinePanel extends StatefulWidget {
  const _TimelinePanel();

  @override
  State<_TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends State<_TimelinePanel> {
  String _typeFilter = 'All';
  String _severityFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final events = controller.snapshot?.timeline ?? const <OrefTimelineEvent>[];
    final typeFilters = _buildFilterOptions(events.map((event) => event.type));
    final severityFilters = _buildFilterOptions(
      events.map((event) => event.severity),
    );
    final filtered = events.where((event) {
      final matchesType = _typeFilter == 'All' || event.type == _typeFilter;
      final matchesSeverity =
          _severityFilter == 'All' || event.severity == _severityFilter;
      return matchesType && matchesSeverity;
    }).toList();

    return _ConnectionGuard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              const _GlassPill(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('Live'),
              ),
              const Spacer(),
              _GlassPill(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text('${filtered.length} events'),
              ),
              const SizedBox(width: 12),
              _ActionPill(
                label: 'Export',
                icon: Icons.download_rounded,
                onTap: () => _exportData(
                  context,
                  'timeline',
                  filtered.map((event) => event.toJson()).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Correlate signal updates with effects, batches, and collections.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('Type', style: Theme.of(context).textTheme.labelMedium),
              for (final filter in typeFilters)
                _FilterChip(
                  label: filter,
                  isSelected: filter == _typeFilter,
                  onTap: () => setState(() => _typeFilter = filter),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Text('Severity', style: Theme.of(context).textTheme.labelMedium),
              for (final filter in severityFilters)
                _FilterChip(
                  label: filter,
                  isSelected: filter == _severityFilter,
                  onTap: () => setState(() => _severityFilter = filter),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _TimelineList(events: filtered)),
        ],
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({required this.events});

  final List<OrefTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: events.isEmpty
          ? Center(
              child: Text(
                'No timeline events yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = events[index];
                return _TimelineEventRow(event: event);
              },
            ),
    );
  }
}

class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({required this.event});

  final OrefTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final tone = _timelineColors[event.type] ?? OrefPalette.teal;
    final subdued = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  event.detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: subdued),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatAge(event.timestamp),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: subdued),
          ),
        ],
      ),
    );
  }
}

class _PerformancePanel extends StatelessWidget {
  const _PerformancePanel();

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final samples =
        controller.snapshot?.performance ?? const <OrefPerformanceSample>[];
    final latest = samples.isNotEmpty ? samples.last : null;

    return _ConnectionGuard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Performance',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              const _GlassPill(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text('Live'),
              ),
              const Spacer(),
              _GlassPill(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text('${samples.length} samples'),
              ),
              const SizedBox(width: 12),
              _ActionPill(
                label: 'Export',
                icon: Icons.download_rounded,
                onTap: () => _exportData(
                  context,
                  'performance',
                  samples.map((sample) => sample.toJson()).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sampled signal throughput and effect costs.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 16),
          _AdaptiveWrap(
            children: [
              _MetricTile(
                label: 'Effect avg',
                value: latest == null
                    ? '—'
                    : '${latest.avgEffectDurationMs.toStringAsFixed(1)}ms',
                trend: latest == null ? '—' : '${latest.effectRuns} runs',
                accent: OrefPalette.pink,
                icon: Icons.speed_rounded,
              ),
              _MetricTile(
                label: 'Signal writes',
                value: latest == null ? '—' : '${latest.signalWrites}',
                trend: latest == null
                    ? '—'
                    : '${latest.collectionMutations} mutations',
                accent: OrefPalette.teal,
                icon: Icons.bolt_rounded,
              ),
              _MetricTile(
                label: 'Collections',
                value: latest == null ? '—' : '${latest.collectionCount}',
                trend: latest == null ? '—' : '${latest.batchWrites} batched',
                accent: OrefPalette.indigo,
                icon: Icons.grid_view_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _PerformanceList(samples: samples)),
        ],
      ),
    );
  }
}

class _PerformanceList extends StatelessWidget {
  const _PerformanceList({required this.samples});

  final List<OrefPerformanceSample> samples;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: samples.isEmpty
          ? Center(
              child: Text(
                'No performance samples yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: samples.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sample = samples[index];
                return _PerformanceRow(sample: sample);
              },
            ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({required this.sample});

  final OrefPerformanceSample sample;

  @override
  Widget build(BuildContext context) {
    final subdued = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(_formatAge(sample.timestamp))),
          Expanded(flex: 2, child: Text('${sample.signalWrites} writes')),
          Expanded(flex: 2, child: Text('${sample.effectRuns} runs')),
          Expanded(
            flex: 2,
            child: Text(
              '${sample.avgEffectDurationMs.toStringAsFixed(1)}ms',
              style: TextStyle(color: subdued),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${sample.collectionMutations} mutations',
              style: TextStyle(color: subdued),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel();

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  bool _isEditing = false;
  OrefDevToolsSettings _draft = const OrefDevToolsSettings();

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final current =
        controller.snapshot?.settings ?? const OrefDevToolsSettings();
    if (!_isEditing) {
      _draft = current;
    }

    return _ConnectionGuard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              _ActionPill(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onTap: controller.refresh,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tune how diagnostics are collected.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sampling',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          value: _draft.enabled,
                          onChanged: (value) {
                            setState(() {
                              _isEditing = true;
                              _draft = _draft.copyWith(enabled: value);
                            });
                            controller.updateSettings(_draft);
                            _isEditing = false;
                          },
                          title: const Text('Enable sampling'),
                          subtitle: Text(
                            'Collect timeline and performance samples.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sample interval (${_draft.sampleIntervalMs}ms)',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Slider(
                          value: _draft.sampleIntervalMs.toDouble(),
                          min: 250,
                          max: 5000,
                          divisions: 19,
                          label: '${_draft.sampleIntervalMs}ms',
                          onChanged: (value) {
                            setState(() {
                              _isEditing = true;
                              _draft = _draft.copyWith(
                                sampleIntervalMs: value.round(),
                              );
                            });
                          },
                          onChangeEnd: (_) async {
                            await controller.updateSettings(_draft);
                            if (mounted) setState(() => _isEditing = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Retention',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Timeline limit (${_draft.timelineLimit})',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Slider(
                          value: _draft.timelineLimit.toDouble(),
                          min: 50,
                          max: 500,
                          divisions: 9,
                          label: _draft.timelineLimit.toString(),
                          onChanged: (value) {
                            setState(() {
                              _isEditing = true;
                              _draft = _draft.copyWith(
                                timelineLimit: value.round(),
                              );
                            });
                          },
                          onChangeEnd: (_) async {
                            await controller.updateSettings(_draft);
                            if (mounted) setState(() => _isEditing = false);
                          },
                        ),
                        Text(
                          'Batch limit (${_draft.batchLimit})',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Slider(
                          value: _draft.batchLimit.toDouble(),
                          min: 20,
                          max: 300,
                          divisions: 14,
                          label: _draft.batchLimit.toString(),
                          onChanged: (value) {
                            setState(() {
                              _isEditing = true;
                              _draft = _draft.copyWith(
                                batchLimit: value.round(),
                              );
                            });
                          },
                          onChangeEnd: (_) async {
                            await controller.updateSettings(_draft);
                            if (mounted) setState(() => _isEditing = false);
                          },
                        ),
                        Text(
                          'Performance samples (${_draft.performanceLimit})',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Slider(
                          value: _draft.performanceLimit.toDouble(),
                          min: 30,
                          max: 300,
                          divisions: 9,
                          label: _draft.performanceLimit.toString(),
                          onChanged: (value) {
                            setState(() {
                              _isEditing = true;
                              _draft = _draft.copyWith(
                                performanceLimit: value.round(),
                              );
                            });
                          },
                          onChangeEnd: (_) async {
                            await controller.updateSettings(_draft);
                            if (mounted) setState(() => _isEditing = false);
                          },
                        ),
                        Text(
                          'Value preview (${_draft.valuePreviewLength} chars)',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        Slider(
                          value: _draft.valuePreviewLength.toDouble(),
                          min: 40,
                          max: 240,
                          divisions: 10,
                          label: _draft.valuePreviewLength.toString(),
                          onChanged: (value) {
                            setState(() {
                              _isEditing = true;
                              _draft = _draft.copyWith(
                                valuePreviewLength: value.round(),
                              );
                            });
                          },
                          onChangeEnd: (_) async {
                            await controller.updateSettings(_draft);
                            if (mounted) setState(() => _isEditing = false);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Clear cached diagnostics and restart sampling.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        _ActionPill(
                          label: 'Clear history',
                          icon: Icons.delete_sweep_rounded,
                          onTap: controller.clearHistory,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({
    required this.controller,
    required this.typeFilter,
    required this.opFilter,
    required this.typeFilters,
    required this.opFilters,
    required this.onTypeChange,
    required this.onOpChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final TextEditingController controller;
  final String typeFilter;
  final String opFilter;
  final List<String> typeFilters;
  final List<String> opFilters;
  final ValueChanged<String> onTypeChange;
  final ValueChanged<String> onOpChange;
  final int totalCount;
  final int filteredCount;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Collections', style: textTheme.headlineSmall),
            const SizedBox(width: 12),
            const _GlassPill(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('Live'),
            ),
            const Spacer(),
            _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            _ActionPill(
              label: 'Export',
              icon: Icons.download_rounded,
              onTap: onExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Inspect reactive list, map, and set mutations.',
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 12),
        _GlassInput(controller: controller, hintText: 'Search collections...'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Type', style: textTheme.labelMedium),
            for (final filter in typeFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == typeFilter,
                onTap: () => onTypeChange(filter),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Op', style: textTheme.labelMedium),
            for (final filter in opFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == opFilter,
                onTap: () => onOpChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}

class _CollectionsList extends StatelessWidget {
  const _CollectionsList({required this.entries, required this.isCompact});

  final List<OrefCollection> entries;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact) const _CollectionsHeaderRow(),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'No collection mutations match the current filters.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      return _CollectionRow(
                        entry: entries[index],
                        isCompact: isCompact,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CollectionsHeaderRow extends StatelessWidget {
  const _CollectionsHeaderRow();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 0.4,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Collection', style: labelStyle)),
          Expanded(flex: 2, child: Text('Type', style: labelStyle)),
          Expanded(flex: 2, child: Text('Op', style: labelStyle)),
          Expanded(flex: 2, child: Text('Scope', style: labelStyle)),
          Expanded(flex: 2, child: Text('Updated', style: labelStyle)),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.entry, required this.isCompact});

  final OrefCollection entry;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final tone = _collectionOpColors[entry.operation] ?? OrefPalette.teal;
    final subdued = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(entry.type),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: tone.withOpacity(0.22),
                      child: Text(entry.operation),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(_formatAge(entry.updatedAt)),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.label),
                      const SizedBox(height: 4),
                      Text(entry.owner, style: TextStyle(color: subdued)),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text(entry.type)),
                Expanded(
                  flex: 2,
                  child: _GlassPill(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: tone.withOpacity(0.22),
                    child: Text(entry.operation),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(entry.scope, style: TextStyle(color: subdued)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatAge(entry.updatedAt),
                    style: TextStyle(color: subdued),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final delta in entry.deltas) _DiffToken(delta: delta),
            ],
          ),
          if (entry.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(entry.note, style: TextStyle(color: subdued)),
          ],
        ],
      ),
    );
  }
}

class _DiffToken extends StatelessWidget {
  const _DiffToken({required this.delta});

  final OrefCollectionDelta delta;

  @override
  Widget build(BuildContext context) {
    final style = _deltaStyles[delta.kind] ?? OrefPalette.indigo;
    final prefix = switch (delta.kind) {
      'add' => '+',
      'remove' => '-',
      _ => '±',
    };

    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: style.withOpacity(0.18),
      child: Text('$prefix ${delta.label}'),
    );
  }
}

class _EffectsPanelState extends State<_EffectsPanel> {
  String _typeFilter = 'All';
  String _scopeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    final entries = controller.snapshot?.effects ?? const <OrefEffect>[];
    final typeFilters = _buildFilterOptions(entries.map((entry) => entry.type));
    final scopeFilters = _buildFilterOptions(
      entries.map((entry) => entry.scope),
    );
    final filtered = entries.where((entry) {
      final matchesType = _typeFilter == 'All' || entry.type == _typeFilter;
      final matchesScope = _scopeFilter == 'All' || entry.scope == _scopeFilter;
      return matchesType && matchesScope;
    }).toList();

    return _ConnectionGuard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EffectsHeader(
            typeFilter: _typeFilter,
            scopeFilter: _scopeFilter,
            typeFilters: typeFilters,
            scopeFilters: scopeFilters,
            onTypeChange: (value) => setState(() => _typeFilter = value),
            onScopeChange: (value) => setState(() => _scopeFilter = value),
            totalCount: entries.length,
            filteredCount: filtered.length,
            onExport: () => _exportData(
              context,
              'effects',
              filtered.map((entry) => entry.toJson()).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _EffectsTimeline(entries: filtered)),
        ],
      ),
    );
  }
}

class _EffectsHeader extends StatelessWidget {
  const _EffectsHeader({
    required this.typeFilter,
    required this.scopeFilter,
    required this.typeFilters,
    required this.scopeFilters,
    required this.onTypeChange,
    required this.onScopeChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final String typeFilter;
  final String scopeFilter;
  final List<String> typeFilters;
  final List<String> scopeFilters;
  final ValueChanged<String> onTypeChange;
  final ValueChanged<String> onScopeChange;
  final int totalCount;
  final int filteredCount;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Effects', style: textTheme.headlineSmall),
            const SizedBox(width: 12),
            const _GlassPill(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('Live'),
            ),
            const Spacer(),
            _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            _ActionPill(
              label: 'Export',
              icon: Icons.download_rounded,
              onTap: onExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Monitor effect lifecycle, timings, and hot paths.',
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Type', style: textTheme.labelMedium),
            for (final filter in typeFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == typeFilter,
                onTap: () => onTypeChange(filter),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Scope', style: textTheme.labelMedium),
            for (final filter in scopeFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == scopeFilter,
                onTap: () => onScopeChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}

class _EffectsTimeline extends StatelessWidget {
  const _EffectsTimeline({required this.entries});

  final List<OrefEffect> entries;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Stack(
        children: [
          Positioned(
            left: 30,
            top: 0,
            bottom: 0,
            child: Container(
              width: 2,
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
          if (entries.isEmpty)
            Center(
              child: Text(
                'No effects match the current filters.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _EffectRow(entry: entries[index]);
              },
            ),
        ],
      ),
    );
  }
}

class _EffectRow extends StatelessWidget {
  const _EffectRow({required this.entry});

  final OrefEffect entry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tone = _effectColors[entry.type] ?? OrefPalette.teal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 18),
          decoration: BoxDecoration(
            color: tone,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: tone.withOpacity(0.4), blurRadius: 10),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (entry.isHot) const _HotBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.note.isEmpty
                      ? 'Last run ${_formatAge(entry.updatedAt)}'
                      : entry.note,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: tone.withOpacity(0.2),
                      child: Text(entry.type),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(entry.scope),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text('Runs ${entry.runs}'),
                    ),
                    _GlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      color: entry.lastDurationMs > 16
                          ? OrefPalette.coral.withOpacity(0.2)
                          : OrefPalette.lime.withOpacity(0.2),
                      child: Text('${entry.lastDurationMs}ms'),
                    ),
                    Text(
                      _formatAge(entry.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HotBadge extends StatelessWidget {
  const _HotBadge();

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: OrefPalette.coral.withOpacity(0.25),
      child: Text(
        'HOT',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: OrefPalette.coral),
      ),
    );
  }
}

class _SignalsHeader extends StatelessWidget {
  const _SignalsHeader({
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.totalCount,
    required this.filteredCount,
    required this.onExport,
  });

  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;
  final int totalCount;
  final int filteredCount;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Signals', style: textTheme.headlineSmall),
            const SizedBox(width: 12),
            const _GlassPill(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('Live'),
            ),
            const Spacer(),
            _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text('$filteredCount / $totalCount'),
            ),
            const SizedBox(width: 12),
            _ActionPill(
              label: 'Export',
              icon: Icons.download_rounded,
              onTap: onExport,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Inspect live signal values, owners, and update cadence.',
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 16),
        _GlassInput(controller: controller, hintText: 'Search signals...'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final filter in _signalFilters)
              _FilterChip(
                label: filter,
                isSelected: filter == selectedFilter,
                onTap: () => onFilterChange(filter),
              ),
          ],
        ),
      ],
    );
  }
}

class _SignalList extends StatelessWidget {
  const _SignalList({
    required this.entries,
    required this.selectedId,
    required this.isCompact,
    required this.onSelect,
  });

  final List<OrefSignal> entries;
  final int? selectedId;
  final bool isCompact;
  final ValueChanged<OrefSignal> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          if (!isCompact) const _SignalTableHeader(),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'No signals match the current filter.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final isSelected = selectedId == entry.id;
                      return _SignalRow(
                        entry: entry,
                        isSelected: isSelected,
                        isCompact: isCompact,
                        onTap: () => onSelect(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SignalTableHeader extends StatelessWidget {
  const _SignalTableHeader();

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      letterSpacing: 0.4,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Name', style: labelStyle)),
          Expanded(flex: 2, child: Text('Value', style: labelStyle)),
          Expanded(flex: 2, child: Text('Type', style: labelStyle)),
          Expanded(flex: 2, child: Text('Status', style: labelStyle)),
          Expanded(flex: 2, child: Text('Updated', style: labelStyle)),
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

  final OrefSignal entry;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = isSelected
        ? OrefPalette.teal.withOpacity(0.2)
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
                  ? OrefPalette.teal.withOpacity(0.4)
                  : colorScheme.onSurface.withOpacity(0.08),
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
                        _GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(entry.type),
                        ),
                        _StatusBadge(status: entry.status),
                        _GlassPill(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(_formatAge(entry.updatedAt)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.label),
                          const SizedBox(height: 4),
                          Text(
                            entry.owner,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.type,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _StatusBadge(status: entry.status),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _formatAge(entry.updatedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
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

  final OrefSignal? entry;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return _GlassCard(
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

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry!.label, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatusBadge(status: entry!.status),
            const SizedBox(height: 16),
            _InfoRow(label: 'Owner', value: entry!.owner),
            _InfoRow(label: 'Scope', value: entry!.scope),
            _InfoRow(label: 'Type', value: entry!.type),
            _InfoRow(label: 'Value', value: entry!.value),
            _InfoRow(label: 'Updated', value: _formatAge(entry!.updatedAt)),
            _InfoRow(label: 'Listeners', value: entry!.listeners.toString()),
            _InfoRow(label: 'Deps', value: entry!.dependencies.toString()),
            const SizedBox(height: 12),
            Text(
              entry!.note,
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyles[status] ?? _statusStyles['Active']!;
    return _GlassPill(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: style.color.withOpacity(0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(status),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? OrefPalette.indigo.withOpacity(0.35)
        : colorScheme.surface.withOpacity(0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected
                  ? OrefPalette.indigo.withOpacity(0.7)
                  : colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isSelected ? Colors.white : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassInput extends StatelessWidget {
  const _GlassInput({required this.controller, required this.hintText});

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelInfo {
  const _PanelInfo({
    required this.title,
    required this.description,
    required this.bullets,
  });

  final String title;
  final String description;
  final List<String> bullets;
}

class _PanelPlaceholder extends StatelessWidget {
  const _PanelPlaceholder({required this.info, required this.icon});

  final _PanelInfo info;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GlassPill(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: OrefPalette.indigo.withOpacity(0.2),
                child: const Text('UI in progress'),
              ),
              const Spacer(),
              Icon(icon, size: 28, color: OrefPalette.teal),
            ],
          ),
          const SizedBox(height: 16),
          Text(info.title, style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            info.description,
            style: textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 860;
              final bulletCard = _GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What you will get', style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    for (final bullet in info.bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.circle, size: 8),
                            const SizedBox(width: 8),
                            Expanded(child: Text(bullet)),
                          ],
                        ),
                      ),
                  ],
                ),
              );

              final previewCard = _GlassCard(
                padding: const EdgeInsets.all(20),
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x2222E3C4), Color(0x116C5CFF)],
                    ),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.grid_view_rounded, size: 48),
                  ),
                ),
              );

              return isStacked
                  ? Column(
                      children: [
                        bulletCard,
                        const SizedBox(height: 20),
                        previewCard,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: bulletCard),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: previewCard),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.trend,
    required this.accent,
    required this.icon,
    this.width,
  });

  final String label;
  final String value;
  final String trend;
  final Color accent;
  final IconData icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              _GlassPill(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                color: accent.withOpacity(0.18),
                child: Text(trend),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _Sparkline(color: accent),
        ],
      ),
    );
  }
}

class _AdaptiveWrap extends StatelessWidget {
  const _AdaptiveWrap({
    required this.children,
    this.minItemWidth = 220,
    this.maxColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final int maxColumns;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final rawColumns = (available / (minItemWidth + spacing)).floor();
        final columns = rawColumns.clamp(1, maxColumns);
        final width =
            (available - (columns - 1) * spacing) / columns.toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.subtitle,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String subtitle;
  final List<_InsightRow> primary;
  final List<_InsightRow> secondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 420;
              final primaryColumn = Column(
                children: [for (final row in primary) row],
              );
              final secondaryColumn = Column(
                children: [for (final row in secondary) row],
              );

              return isStacked
                  ? Column(
                      children: [
                        primaryColumn,
                        const SizedBox(height: 12),
                        secondaryColumn,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: primaryColumn),
                        const SizedBox(width: 16),
                        Expanded(child: secondaryColumn),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final subdued = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: subdued),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.activeNodes,
    required this.totalNodes,
    required this.watchedNodes,
    required this.activityRate,
    required this.activityProgress,
  });

  final int activeNodes;
  final int totalNodes;
  final int watchedNodes;
  final int activityRate;
  final double activityProgress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Health Snapshot', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Service health and steady-state metrics.',
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          _HealthBar(
            label: 'Active nodes',
            value: totalNodes == 0 ? '—' : '$activeNodes / $totalNodes',
            progress: totalNodes == 0 ? 0 : activeNodes / totalNodes,
            color: OrefPalette.teal,
          ),
          const SizedBox(height: 12),
          _HealthBar(
            label: 'Watched nodes',
            value: totalNodes == 0 ? '—' : '$watchedNodes watched',
            progress: totalNodes == 0 ? 0 : watchedNodes / totalNodes,
            color: OrefPalette.indigo,
          ),
          const SizedBox(height: 12),
          _HealthBar(
            label: 'Update rate',
            value: activityRate == 0 ? '—' : '$activityRate/min',
            progress: activityProgress,
            color: OrefPalette.coral,
          ),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });

  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final subdued = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: TextStyle(color: subdued)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * clamped,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(color: color.withOpacity(0.35), blurRadius: 8),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.icon, required this.caption});

  final IconData icon;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0x3322E3C4), Color(0x226C5CFF)],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 48),
          Positioned(
            bottom: 12,
            right: 12,
            child: _GlassPill(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text(caption),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({
    required this.values,
    required this.icon,
    required this.caption,
    required this.color,
  });

  final List<int> values;
  final IconData icon;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return _ChartPlaceholder(icon: icon, caption: caption);
    }
    final maxValue = values.fold<int>(1, (max, value) {
      return value > max ? value : max;
    });

    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.12), color.withOpacity(0.04)],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barMaxHeight = constraints.maxHeight;
                  final barCount = values.length;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var index = 0; index < barCount; index++) ...[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: barMaxHeight * (values[index] / maxValue),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        if (index != barCount - 1) const SizedBox(width: 6),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    caption,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const bars = [0.3, 0.5, 0.7, 0.4, 0.6, 0.8, 0.5, 0.9];
    return SizedBox(
      height: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in bars)
            Container(
              width: 10,
              height: 28 * value,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.4),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event});

  final OrefTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: _timelineColors[event.type] ?? OrefPalette.teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${event.detail} · ${_formatAge(event.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.padding, this.width});

  final Widget child;
  final EdgeInsets? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.7);

    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final tint =
        color ??
        (brightness == Brightness.dark
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.9));

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.5),
            ),
          ),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.labelMedium,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [OrefPalette.teal, OrefPalette.indigo],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6622E3C4),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = Theme.of(context).colorScheme.onSurface;
    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectionGuard extends StatelessWidget {
  const _ConnectionGuard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = OrefDevToolsScope.of(context);
    if (!controller.connected) {
      return const _PanelStateCard(
        icon: Icons.link_off_rounded,
        title: 'No app connected',
        message: 'Run your Flutter app and open DevTools to connect.',
      );
    }
    if (controller.isUnavailable) {
      return const _PanelStateCard(
        icon: Icons.extension_off_rounded,
        title: 'DevTools not enabled',
        message:
            'Call registerOrefDevToolsServiceExtensions() in main() and run '
            'a debug build to expose diagnostics.',
      );
    }
    if (controller.isConnecting && controller.snapshot == null) {
      return const _PanelLoadingCard();
    }
    if (controller.hasError && controller.snapshot == null) {
      return _PanelStateCard(
        icon: Icons.error_outline_rounded,
        title: 'Connection error',
        message: controller.errorMessage ?? 'Unable to reach the VM service.',
      );
    }
    return child;
  }
}

class _PanelStateCard extends StatelessWidget {
  const _PanelStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassCard(
        padding: const EdgeInsets.all(24),
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: OrefPalette.coral),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelLoadingCard extends StatelessWidget {
  const _PanelLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassCard(
        padding: const EdgeInsets.all(24),
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Connecting to Oref diagnostics...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.icon);

  final String label;
  final IconData icon;
}

const _navItems = [
  _NavItemData('Overview', Icons.dashboard_rounded),
  _NavItemData('Signals', Icons.bubble_chart_rounded),
  _NavItemData('Computed', Icons.schema_rounded),
  _NavItemData('Effects', Icons.auto_awesome_motion_rounded),
  _NavItemData('Collections', Icons.grid_view_rounded),
  _NavItemData('Batching', Icons.layers_rounded),
  _NavItemData('Timeline', Icons.timeline_rounded),
];

const _utilityItems = [
  _NavItemData('Performance', Icons.speed_rounded),
  _NavItemData('Settings', Icons.tune_rounded),
];

const _allNavItems = [..._navItems, ..._utilityItems];

const _panelInfo = {
  'Computed': _PanelInfo(
    title: 'Computed',
    description: 'Understand derived state and cache behavior.',
    bullets: [
      'Dependency graph preview',
      'Cache hit / miss ratio',
      'Invalidation cascade list',
    ],
  ),
  'Effects': _PanelInfo(
    title: 'Effects',
    description: 'Track effect execution and lifecycle changes.',
    bullets: [
      'Timeline with rerun counts',
      'Execution duration stats',
      'Dispose + scope diagnostics',
    ],
  ),
  'Collections': _PanelInfo(
    title: 'Collections',
    description: 'Audit reactive lists, maps, and sets.',
    bullets: [
      'Mutation history',
      'Diff view for changes',
      'Batch operations overview',
    ],
  ),
  'Batching': _PanelInfo(
    title: 'Batching',
    description: 'Inspect batched writes and flush timing.',
    bullets: [
      'Grouped updates per frame',
      'Longest batch duration',
      'Hot write sources',
    ],
  ),
  'Timeline': _PanelInfo(
    title: 'Timeline',
    description: 'Correlate signal updates with frame rendering.',
    bullets: [
      'Frame markers + signal spikes',
      'CPU / UI jank overlay',
      'Exportable diagnostics',
    ],
  ),
  'Performance': _PanelInfo(
    title: 'Performance',
    description: 'Track frame costs and signal churn hotspots.',
    bullets: [
      'Frame budget + jank markers',
      'Top signal recomputes',
      'Slow effects callouts',
    ],
  ),
  'Settings': _PanelInfo(
    title: 'Settings',
    description: 'Tune how diagnostics are collected.',
    bullets: [
      'Sampling frequency',
      'Auto capture thresholds',
      'Export + privacy controls',
    ],
  ),
};

class _StatusStyle {
  const _StatusStyle(this.color);

  final Color color;
}

const _signalFilters = ['All', 'Active', 'Dirty', 'Disposed'];

const _statusStyles = {
  'Active': _StatusStyle(OrefPalette.lime),
  'Dirty': _StatusStyle(OrefPalette.coral),
  'Disposed': _StatusStyle(Color(0xFF8B97A8)),
};

const _effectColors = {
  'UI': OrefPalette.teal,
  'Network': OrefPalette.indigo,
  'Persist': OrefPalette.coral,
  'Analytics': OrefPalette.pink,
  'Effect': OrefPalette.teal,
};

const _collectionOpColors = {
  'Add': OrefPalette.lime,
  'Remove': OrefPalette.coral,
  'Replace': OrefPalette.indigo,
  'Clear': OrefPalette.pink,
  'Resize': OrefPalette.indigo,
};

const _deltaStyles = {
  'add': OrefPalette.lime,
  'remove': OrefPalette.coral,
  'update': OrefPalette.indigo,
};

const _timelineColors = {
  'signal': OrefPalette.teal,
  'computed': OrefPalette.indigo,
  'effect': OrefPalette.pink,
  'collection': OrefPalette.coral,
  'batch': OrefPalette.lime,
};

String _formatAge(int? timestamp) {
  if (timestamp == null || timestamp == 0) return '—';
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  final diff = now - timestamp;
  if (diff < 0) return 'just now';
  if (diff < 1000) return '${diff}ms ago';
  final seconds = diff ~/ 1000;
  if (seconds < 60) return '${seconds}s ago';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m ago';
  final hours = minutes ~/ 60;
  if (hours < 24) return '${hours}h ago';
  final days = hours ~/ 24;
  return '${days}d ago';
}

String _formatCount(int? value) {
  if (value == null) return '—';
  return value.toString();
}

String _formatDelta(int? value, {String suffix = ''}) {
  if (value == null) return '—';
  if (value == 0) return 'idle';
  final label = value > 0 ? '+$value' : value.toString();
  return suffix.isEmpty ? label : '$label $suffix';
}

Future<void> _exportData(
  BuildContext context,
  String label,
  Object data,
) async {
  if (data is Iterable && data.isEmpty) {
    _showToast(context, 'No $label data to export.');
    return;
  }
  if (data is Map && data.isEmpty) {
    _showToast(context, 'No $label data to export.');
    return;
  }
  final payload = const JsonEncoder.withIndent('  ').convert(data);
  await Clipboard.setData(ClipboardData(text: payload));
  _showToast(context, 'Copied $label JSON to clipboard.');
}

void _showToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

List<String> _buildFilterOptions(Iterable<String> values) {
  final unique = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) unique.add(trimmed);
  }
  final sorted = unique.toList()..sort();
  return ['All', ...sorted];
}

extension _IterableX<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
