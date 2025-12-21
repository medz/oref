import 'dart:ui';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _handleSelect(_NavItemData item) {
    if (item.label == _selectedLabel) return;
    setState(() => _selectedLabel = item.label);
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

    return LayoutBuilder(
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
                    const _TopBar(),
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
                                  child: _MainPanel(selectedItem: selectedItem),
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
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 900;
    final children = <Widget>[
      const _BrandMark(),
      const SizedBox(width: 16),
      const _StatusPill(),
      const Spacer(),
      const _ActionPill(label: 'Watch', icon: Icons.visibility_rounded),
      const SizedBox(width: 12),
      const _ActionPill(label: 'Record', icon: Icons.fiber_manual_record),
      const SizedBox(width: 12),
      const _IconAction(icon: Icons.more_horiz),
    ];

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: isCompact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: children.take(2).toList()),
                const SizedBox(height: 12),
                Row(children: children.skip(2).toList()),
              ],
            )
          : Row(children: children),
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
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      color: OrefPalette.lime.withOpacity(0.22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: OrefPalette.lime,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Connected',
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
  const _ActionPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 8), Text(label)],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _GlassPill(
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 18),
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
    if (selectedItem.label == 'Effects') {
      return const _EffectsPanel();
    }
    if (selectedItem.label == 'Collections') {
      return const _CollectionsPanel();
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
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: const [
              _MetricTile(
                label: 'Signals',
                value: '128',
                trend: '+12%',
                accent: OrefPalette.teal,
                icon: Icons.bubble_chart_rounded,
              ),
              _MetricTile(
                label: 'Computed',
                value: '42',
                trend: 'stable',
                accent: OrefPalette.indigo,
                icon: Icons.schema_rounded,
              ),
              _MetricTile(
                label: 'Effects',
                value: '17',
                trend: '+3',
                accent: OrefPalette.pink,
                icon: Icons.auto_awesome_motion_rounded,
              ),
              _MetricTile(
                label: 'Batch Writes',
                value: '9',
                trend: 'hot',
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
                primary: const [
                  _InsightRow('Top signals', 'cartTotal · userLocale'),
                  _InsightRow('Hot effects', 'refreshShippingRates'),
                  _InsightRow('Muted', 'promoBannerVisible'),
                ],
                secondary: const [
                  _InsightRow('High churn', 'cartItems (12)'),
                  _InsightRow('Stable', 'shippingQuote'),
                  _InsightRow('Idle', 'syncQueueSize'),
                ],
              );
              const healthCard = _HealthCard();

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
                      'You can pin a session or start a capture.',
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
                      children: const [
                        _GradientButton(label: 'Start Capture'),
                        _OutlineButton(label: 'Pin Session'),
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
                      _InfoRow(label: 'App', value: 'Oref Showcase'),
                      _InfoRow(label: 'Isolate', value: 'main'),
                      _InfoRow(label: 'Frame time', value: '7.3ms'),
                      _InfoRow(label: 'Updates', value: '1.2k'),
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
                        const _ChartPlaceholder(
                          icon: Icons.stacked_line_chart_rounded,
                          caption: 'Awaiting samples',
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
                        const _ChartPlaceholder(
                          icon: Icons.grid_view_rounded,
                          caption: 'No batches recorded',
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
                    if (_activityItems.isEmpty)
                      Text(
                        'No recent activity yet.',
                        style: textTheme.bodyMedium,
                      )
                    else
                      for (final item in _activityItems)
                        _TimelineRow(item: item),
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
  _SignalEntry? _selected;

  @override
  void initState() {
    super.initState();
    _selected = _signalEntries.first;
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSplit = constraints.maxWidth >= 980;
        final filtered = _filterSignals();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SignalsHeader(
              controller: _searchController,
              selectedFilter: _statusFilter,
              onFilterChange: (value) => setState(() => _statusFilter = value),
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
                            selected: _selected,
                            onSelect: (entry) =>
                                setState(() => _selected = entry),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 320,
                          child: _SignalDetail(entry: _selected),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: _SignalList(
                            entries: filtered,
                            selected: _selected,
                            onSelect: (entry) =>
                                setState(() => _selected = entry),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: _SignalDetail(entry: _selected),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  List<_SignalEntry> _filterSignals() {
    final query = _searchController.text.trim().toLowerCase();
    return _signalEntries.where((entry) {
      final matchesQuery =
          query.isEmpty || entry.name.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All' || entry.status == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
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
    final filtered = _collectionEntries.where((entry) {
      final query = _searchController.text.trim().toLowerCase();
      final matchesQuery =
          query.isEmpty || entry.name.toLowerCase().contains(query);
      final matchesType = _typeFilter == 'All' || entry.type == _typeFilter;
      final matchesOp = _opFilter == 'All' || entry.operation == _opFilter;
      return matchesQuery && matchesType && matchesOp;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CollectionsHeader(
          controller: _searchController,
          typeFilter: _typeFilter,
          opFilter: _opFilter,
          onTypeChange: (value) => setState(() => _typeFilter = value),
          onOpChange: (value) => setState(() => _opFilter = value),
        ),
        const SizedBox(height: 16),
        Expanded(child: _CollectionsList(entries: filtered)),
      ],
    );
  }
}

class _CollectionsHeader extends StatelessWidget {
  const _CollectionsHeader({
    required this.controller,
    required this.typeFilter,
    required this.opFilter,
    required this.onTypeChange,
    required this.onOpChange,
  });

  final TextEditingController controller;
  final String typeFilter;
  final String opFilter;
  final ValueChanged<String> onTypeChange;
  final ValueChanged<String> onOpChange;

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
            const _ActionPill(label: 'Export', icon: Icons.download_rounded),
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
            for (final filter in _collectionTypeFilters)
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
            for (final filter in _collectionOpFilters)
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
  const _CollectionsList({required this.entries});

  final List<_CollectionEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          const _CollectionsHeaderRow(),
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
                      return _CollectionRow(entry: entries[index]);
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
  const _CollectionRow({required this.entry});

  final _CollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final tone = _collectionOpColors[entry.operation] ?? OrefPalette.teal;
    final subdued = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name),
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
                child: Text(entry.updated, style: TextStyle(color: subdued)),
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

  final _CollectionDelta delta;

  @override
  Widget build(BuildContext context) {
    final style = _deltaStyles[delta.kind]!;
    final prefix = switch (delta.kind) {
      _DeltaKind.add => '+',
      _DeltaKind.remove => '-',
      _DeltaKind.update => '±',
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
    final filtered = _effectEntries.where((entry) {
      final matchesType = _typeFilter == 'All' || entry.type == _typeFilter;
      final matchesScope = _scopeFilter == 'All' || entry.scope == _scopeFilter;
      return matchesType && matchesScope;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EffectsHeader(
          typeFilter: _typeFilter,
          scopeFilter: _scopeFilter,
          onTypeChange: (value) => setState(() => _typeFilter = value),
          onScopeChange: (value) => setState(() => _scopeFilter = value),
        ),
        const SizedBox(height: 16),
        Expanded(child: _EffectsTimeline(entries: filtered)),
      ],
    );
  }
}

class _EffectsHeader extends StatelessWidget {
  const _EffectsHeader({
    required this.typeFilter,
    required this.scopeFilter,
    required this.onTypeChange,
    required this.onScopeChange,
  });

  final String typeFilter;
  final String scopeFilter;
  final ValueChanged<String> onTypeChange;
  final ValueChanged<String> onScopeChange;

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
            const _ActionPill(
              label: 'Capture',
              icon: Icons.fiber_manual_record,
            ),
            const SizedBox(width: 8),
            const _ActionPill(label: 'Export', icon: Icons.download_rounded),
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
            for (final filter in _effectTypeFilters)
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
            for (final filter in _effectScopeFilters)
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

  final List<_EffectEntry> entries;

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

  final _EffectEntry entry;

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
                        entry.name,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    if (entry.isHot) const _HotBadge(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.description,
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
                      color: entry.durationMs > 16
                          ? OrefPalette.coral.withOpacity(0.2)
                          : OrefPalette.lime.withOpacity(0.2),
                      child: Text('${entry.durationMs}ms'),
                    ),
                    Text(
                      entry.lastRun,
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
  });

  final TextEditingController controller;
  final String selectedFilter;
  final ValueChanged<String> onFilterChange;

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
            const _ActionPill(label: 'Export', icon: Icons.download_rounded),
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
    required this.selected,
    required this.onSelect,
  });

  final List<_SignalEntry> entries;
  final _SignalEntry? selected;
  final ValueChanged<_SignalEntry> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          const _SignalTableHeader(),
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
                      final isSelected = selected?.id == entry.id;
                      return _SignalRow(
                        entry: entry,
                        isSelected: isSelected,
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
    required this.onTap,
  });

  final _SignalEntry entry;
  final bool isSelected;
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
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name),
                    const SizedBox(height: 4),
                    Text(
                      entry.owner,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(flex: 2, child: Text(entry.value)),
              Expanded(
                flex: 2,
                child: Text(
                  entry.type,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(flex: 2, child: _StatusBadge(status: entry.status)),
              Expanded(
                flex: 2,
                child: Text(
                  entry.updated,
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

  final _SignalEntry? entry;

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
            Text(entry!.name, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            _StatusBadge(status: entry!.status),
            const SizedBox(height: 16),
            _InfoRow(label: 'Owner', value: entry!.owner),
            _InfoRow(label: 'Scope', value: entry!.scope),
            _InfoRow(label: 'Type', value: entry!.type),
            _InfoRow(label: 'Value', value: entry!.value),
            _InfoRow(label: 'Updated', value: entry!.updated),
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
                border: InputBorder.none,
                isDense: true,
              ),
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
  });

  final String label;
  final String value;
  final String trend;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      width: 230,
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
  const _HealthCard();

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
          const _HealthBar(
            label: 'Memory',
            value: '68%',
            progress: 0.68,
            color: OrefPalette.teal,
          ),
          const SizedBox(height: 12),
          const _HealthBar(
            label: 'Listeners',
            value: '42 active',
            progress: 0.52,
            color: OrefPalette.indigo,
          ),
          const SizedBox(height: 12),
          const _HealthBar(
            label: 'Update rate',
            value: '1.2k/min',
            progress: 0.78,
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
                  width: constraints.maxWidth * progress,
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
  const _TimelineRow({required this.item});

  final _ActivityItem item;

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
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  item.subtitle,
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
  const _GradientButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
        ),
      ),
      child: Text(label),
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

class _ActivityItem {
  const _ActivityItem(this.title, this.subtitle, this.color);

  final String title;
  final String subtitle;
  final Color color;
}

const _activityItems = [
  _ActivityItem(
    'Effect #18 re-run',
    'cartTotal recomputed • 120ms ago',
    OrefPalette.teal,
  ),
  _ActivityItem(
    'Batch write',
    'orderItems updated (6 signals)',
    OrefPalette.indigo,
  ),
  _ActivityItem(
    'Computed invalidated',
    'checkoutSummary dirty',
    OrefPalette.coral,
  ),
  _ActivityItem(
    'Collection mutation',
    'ReactiveList.append x3',
    OrefPalette.pink,
  ),
];

class _SignalEntry {
  const _SignalEntry({
    required this.id,
    required this.name,
    required this.value,
    required this.type,
    required this.status,
    required this.owner,
    required this.updated,
    required this.scope,
    required this.listeners,
    required this.dependencies,
    required this.note,
  });

  final String id;
  final String name;
  final String value;
  final String type;
  final String status;
  final String owner;
  final String updated;
  final String scope;
  final int listeners;
  final int dependencies;
  final String note;
}

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

const _signalEntries = [
  _SignalEntry(
    id: 'sig-01',
    name: 'cartTotal',
    value: '\$128.40',
    type: 'Signal<double>',
    status: 'Active',
    owner: 'CheckoutViewModel',
    updated: '80ms ago',
    scope: 'CheckoutFlow',
    listeners: 3,
    dependencies: 4,
    note: 'Derived from item subtotals + discount.',
  ),
  _SignalEntry(
    id: 'sig-02',
    name: 'userLocale',
    value: 'en_US',
    type: 'Signal<String>',
    status: 'Active',
    owner: 'AppSettings',
    updated: '2m ago',
    scope: 'Root',
    listeners: 6,
    dependencies: 0,
    note: 'Persisted preference synchronized on boot.',
  ),
  _SignalEntry(
    id: 'sig-03',
    name: 'cartItemCount',
    value: '5',
    type: 'Signal<int>',
    status: 'Dirty',
    owner: 'CartStore',
    updated: '120ms ago',
    scope: 'CartFlow',
    listeners: 5,
    dependencies: 2,
    note: 'Pending recompute after last batch.',
  ),
  _SignalEntry(
    id: 'sig-04',
    name: 'shippingQuote',
    value: '\$12.90',
    type: 'Computed<double>',
    status: 'Active',
    owner: 'ShippingService',
    updated: '12s ago',
    scope: 'CheckoutFlow',
    listeners: 2,
    dependencies: 3,
    note: 'Computed from address + rate table.',
  ),
  _SignalEntry(
    id: 'sig-05',
    name: 'promoBannerVisible',
    value: 'false',
    type: 'Signal<bool>',
    status: 'Disposed',
    owner: 'MarketingOverlay',
    updated: '18m ago',
    scope: 'PromoCampaign',
    listeners: 0,
    dependencies: 1,
    note: 'Disposed after campaign ended.',
  ),
  _SignalEntry(
    id: 'sig-06',
    name: 'formValidationState',
    value: 'valid',
    type: 'Signal<FormState>',
    status: 'Active',
    owner: 'CheckoutForm',
    updated: '260ms ago',
    scope: 'CheckoutFlow',
    listeners: 4,
    dependencies: 5,
    note: 'Last validation run passed.',
  ),
  _SignalEntry(
    id: 'sig-07',
    name: 'paymentMethod',
    value: 'Visa •••• 4242',
    type: 'Signal<PaymentCard>',
    status: 'Active',
    owner: 'PaymentStore',
    updated: '6m ago',
    scope: 'CheckoutFlow',
    listeners: 3,
    dependencies: 1,
    note: 'Default card selected for this session.',
  ),
  _SignalEntry(
    id: 'sig-08',
    name: 'syncQueueSize',
    value: '0',
    type: 'Signal<int>',
    status: 'Active',
    owner: 'SyncManager',
    updated: '1s ago',
    scope: 'Background',
    listeners: 1,
    dependencies: 0,
    note: 'Queue drained successfully.',
  ),
];

class _EffectEntry {
  const _EffectEntry({
    required this.name,
    required this.description,
    required this.type,
    required this.scope,
    required this.lastRun,
    required this.durationMs,
    required this.runs,
    required this.isHot,
  });

  final String name;
  final String description;
  final String type;
  final String scope;
  final String lastRun;
  final int durationMs;
  final int runs;
  final bool isHot;
}

const _effectTypeFilters = ['All', 'UI', 'Network', 'Persist', 'Analytics'];
const _effectScopeFilters = ['All', 'CheckoutFlow', 'AppShell', 'Background'];

const _effectColors = {
  'UI': OrefPalette.teal,
  'Network': OrefPalette.indigo,
  'Persist': OrefPalette.coral,
  'Analytics': OrefPalette.pink,
};

const _effectEntries = [
  _EffectEntry(
    name: 'syncCartTotals',
    description: 'Recompute totals after cart mutation batch.',
    type: 'UI',
    scope: 'CheckoutFlow',
    lastRun: '120ms ago',
    durationMs: 6,
    runs: 12,
    isHot: false,
  ),
  _EffectEntry(
    name: 'refreshShippingRates',
    description: 'Fetch shipping quote from remote service.',
    type: 'Network',
    scope: 'CheckoutFlow',
    lastRun: '320ms ago',
    durationMs: 42,
    runs: 5,
    isHot: true,
  ),
  _EffectEntry(
    name: 'persistPaymentMethod',
    description: 'Write selected payment method to secure storage.',
    type: 'Persist',
    scope: 'AppShell',
    lastRun: '2m ago',
    durationMs: 18,
    runs: 3,
    isHot: false,
  ),
  _EffectEntry(
    name: 'logCheckoutStep',
    description: 'Send analytics event for funnel tracking.',
    type: 'Analytics',
    scope: 'CheckoutFlow',
    lastRun: '5s ago',
    durationMs: 12,
    runs: 9,
    isHot: false,
  ),
  _EffectEntry(
    name: 'flushSyncQueue',
    description: 'Persist background sync queue to disk.',
    type: 'Persist',
    scope: 'Background',
    lastRun: '12s ago',
    durationMs: 28,
    runs: 2,
    isHot: true,
  ),
  _EffectEntry(
    name: 'hydrateProfile',
    description: 'Fetch profile metadata for the session.',
    type: 'Network',
    scope: 'AppShell',
    lastRun: '8m ago',
    durationMs: 36,
    runs: 4,
    isHot: false,
  ),
];

enum _DeltaKind { add, remove, update }

class _CollectionDelta {
  const _CollectionDelta({required this.label, required this.kind});

  final String label;
  final _DeltaKind kind;
}

class _CollectionEntry {
  const _CollectionEntry({
    required this.name,
    required this.type,
    required this.operation,
    required this.owner,
    required this.scope,
    required this.updated,
    required this.deltas,
    required this.note,
  });

  final String name;
  final String type;
  final String operation;
  final String owner;
  final String scope;
  final String updated;
  final List<_CollectionDelta> deltas;
  final String note;
}

const _collectionTypeFilters = ['All', 'List', 'Map', 'Set'];
const _collectionOpFilters = ['All', 'Add', 'Remove', 'Replace'];

const _collectionOpColors = {
  'Add': OrefPalette.lime,
  'Remove': OrefPalette.coral,
  'Replace': OrefPalette.indigo,
};

const _deltaStyles = {
  _DeltaKind.add: OrefPalette.lime,
  _DeltaKind.remove: OrefPalette.coral,
  _DeltaKind.update: OrefPalette.indigo,
};

const _collectionEntries = [
  _CollectionEntry(
    name: 'cartItems',
    type: 'List',
    operation: 'Add',
    owner: 'CartStore',
    scope: 'CheckoutFlow',
    updated: '90ms ago',
    deltas: [
      _CollectionDelta(label: 'SKU-421 x1', kind: _DeltaKind.add),
      _CollectionDelta(label: 'SKU-008 x2', kind: _DeltaKind.add),
    ],
    note: 'Batch append triggered by add-to-cart.',
  ),
  _CollectionEntry(
    name: 'favoriteIds',
    type: 'Set',
    operation: 'Remove',
    owner: 'FavoritesStore',
    scope: 'AppShell',
    updated: '2m ago',
    deltas: [_CollectionDelta(label: 'item_882', kind: _DeltaKind.remove)],
    note: 'User removed a saved item.',
  ),
  _CollectionEntry(
    name: 'shippingRates',
    type: 'Map',
    operation: 'Replace',
    owner: 'ShippingService',
    scope: 'CheckoutFlow',
    updated: '420ms ago',
    deltas: [
      _CollectionDelta(label: 'CA: 12.90 → 10.50', kind: _DeltaKind.update),
      _CollectionDelta(label: 'NY: 14.20 → 13.10', kind: _DeltaKind.update),
    ],
    note: 'Remote quote refresh.',
  ),
  _CollectionEntry(
    name: 'activeCoupons',
    type: 'Set',
    operation: 'Add',
    owner: 'PromoEngine',
    scope: 'CheckoutFlow',
    updated: '4s ago',
    deltas: [_CollectionDelta(label: 'SAVE10', kind: _DeltaKind.add)],
    note: 'Promo banner applied.',
  ),
  _CollectionEntry(
    name: 'recentSearches',
    type: 'List',
    operation: 'Remove',
    owner: 'SearchStore',
    scope: 'AppShell',
    updated: '18m ago',
    deltas: [_CollectionDelta(label: '"wallet case"', kind: _DeltaKind.remove)],
    note: 'Trimmed for privacy.',
  ),
  _CollectionEntry(
    name: 'profileCache',
    type: 'Map',
    operation: 'Replace',
    owner: 'ProfileService',
    scope: 'Background',
    updated: '32s ago',
    deltas: [
      _CollectionDelta(label: 'user_109: v12 → v13', kind: _DeltaKind.update),
    ],
    note: 'Background sync refresh.',
  ),
];
