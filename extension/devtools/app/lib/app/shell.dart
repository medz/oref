import 'package:flutter/material.dart';
import 'package:oref/oref.dart' as oref;

import '../app/constants.dart';
import '../app/palette.dart';
import '../app/scopes.dart';
import '../app/widgets/panel_placeholder.dart';
import '../features/batching_page.dart';
import '../features/collections_page.dart';
import '../features/computed_page.dart';
import '../features/effects_page.dart';
import '../features/overview_page.dart';
import '../features/performance_page.dart';
import '../features/settings_page.dart';
import '../features/signals_page.dart';
import '../features/timeline_page.dart';
import '../services/oref_service.dart';
import '../shared/widgets/actions.dart';
import '../shared/widgets/glass.dart';

class DevToolsShell extends StatelessWidget {
  const DevToolsShell({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = oref.useMemoized(
      context,
      () => OrefDevToolsController(),
    );
    oref.onUnmounted(context, controller.dispose);
    final uiState = UiScope.of(context);

    return oref.SignalBuilder(
      builder: (context) {
        final selectedLabel = uiState.selectedNavLabel();
        final selectedItem = allNavItems.firstWhere(
          (item) => item.label == selectedLabel,
          orElse: () => navItems.first,
        );

        void handleSelect(NavItemData item) {
          if (item.label == selectedLabel) return;
          uiState.selectedNavLabel.set(item.label);
        }

        void openSettings() => handleSelect(settingsItem);

        return OrefDevToolsScope(
          controller: controller,
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
                          _TopBar(onOpenSettings: openSettings),
                          const SizedBox(height: 20),
                          Expanded(
                            child: isWide
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 240,
                                        child: _SideNav(
                                          selectedLabel: selectedLabel,
                                          onSelect: handleSelect,
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
                                    selectedLabel: selectedLabel,
                                    onSelect: handleSelect,
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
  final ValueChanged<NavItemData> onSelect;
  final NavItemData selectedItem;

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
      ActionPill(
        label: 'Refresh',
        icon: Icons.refresh_rounded,
        iconOnly: true,
        onTap: canInteract ? controller.refresh : null,
      ),
      ActionPill(
        label: 'Clear',
        icon: Icons.delete_sweep_rounded,
        iconOnly: true,
        onTap: canInteract ? controller.clearHistory : null,
      ),
      ActionPill(
        label: 'Settings',
        icon: Icons.tune_rounded,
        iconOnly: true,
        onTap: onOpenSettings,
      ),
    ];

    return GlassCard(
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
            Text('Signals • Effects • Collections', style: textTheme.bodySmall),
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
      .ready => OrefPalette.lime,
      .connecting => OrefPalette.teal,
      .unavailable => OrefPalette.coral,
      .error => OrefPalette.pink,
      .disconnected => const Color(0xFF8B97A8),
    };
    final label = switch (status) {
      .ready => 'Connected',
      .connecting => 'Connecting',
      .unavailable => 'Inactive',
      .error => 'Connection error',
      .disconnected => 'Disconnected',
    };

    return GlassPill(
      color: tone.withValues(alpha: 0.22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: tone),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.selectedLabel, required this.onSelect});

  final String selectedLabel;
  final ValueChanged<NavItemData> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Navigation', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Expanded(
              child: Scrollbar(
                thumbVisibility: false,
                interactive: true,
                child: ListView.builder(
                  padding: const EdgeInsets.only(right: 6),
                  itemCount: navDisplayItems.length,
                  itemBuilder: (context, index) {
                    final item = navDisplayItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _NavItem(
                        item: item,
                        isActive: item.label == selectedLabel,
                        onTap: () => onSelect(item),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactNav extends StatelessWidget {
  const _CompactNav({required this.selectedLabel, required this.onSelect});

  final String selectedLabel;
  final ValueChanged<NavItemData> onSelect;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in navDisplayItems)
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

  final NavItemData item;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeGradient = LinearGradient(
      colors: [
        OrefPalette.teal.withValues(alpha: 0.9),
        OrefPalette.indigo.withValues(alpha: 0.9),
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
            color: isActive
                ? null
                : colorScheme.surface.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : colorScheme.onSurface.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 18),
              const SizedBox(width: 8),
              Text(item.label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainPanel extends StatelessWidget {
  const _MainPanel({required this.selectedItem});

  final NavItemData selectedItem;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedItem.label) {
      case 'Overview':
        page = const OverviewPage();
        break;
      case 'Signals':
        page = const SignalsPage();
        break;
      case 'Computed':
        page = const ComputedPage();
        break;
      case 'Effects':
        page = const EffectsPage();
        break;
      case 'Collections':
        page = const CollectionsPage();
        break;
      case 'Batching':
        page = const BatchingPage();
        break;
      case 'Timeline':
        page = const TimelinePage();
        break;
      case 'Performance':
        page = const PerformancePage();
        break;
      case 'Settings':
        page = const SettingsPage();
        break;
      default:
        final info =
            panelInfo[selectedItem.label] ??
            PanelInfo(
              title: selectedItem.label,
              description: 'This panel will be wired to live Oref diagnostics.',
              bullets: const [
                'Live data stream',
                'Filters + search',
                'Batch insights',
              ],
            );

        page = PanelPlaceholder(info: info, icon: selectedItem.icon);
        break;
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(key: ValueKey(selectedItem.label), child: page),
    );
  }
}
