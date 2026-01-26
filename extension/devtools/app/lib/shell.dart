part of 'main.dart';

class _DevToolsShell extends StatelessWidget {
  const _DevToolsShell();

  @override
  Widget build(BuildContext context) {
    final controller = oref.useMemoized(
      context,
      () => OrefDevToolsController(),
    );
    oref.onUnmounted(context, controller.dispose);
    final uiState = _UiScope.of(context);

    return oref.SignalBuilder(
      builder: (context) {
        final selectedLabel = uiState.selectedNavLabel();
        final selectedItem = _allNavItems.firstWhere(
          (item) => item.label == selectedLabel,
          orElse: () => _navItems.first,
        );

        void handleSelect(_NavItemData item) {
          if (item.label == selectedLabel) return;
          uiState.selectedNavLabel.set(item.label);
        }

        void openSettings() => handleSelect(_settingsItem);

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
        iconOnly: true,
        onTap: canInteract ? controller.refresh : null,
      ),
      _ActionPill(
        label: 'Clear',
        icon: Icons.delete_sweep_rounded,
        iconOnly: true,
        onTap: canInteract ? controller.clearHistory : null,
      ),
      _ActionPill(
        label: 'Settings',
        icon: Icons.tune_rounded,
        iconOnly: true,
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
      OrefServiceStatus.ready => OrefPalette.lime,
      OrefServiceStatus.connecting => OrefPalette.teal,
      OrefServiceStatus.unavailable => OrefPalette.coral,
      OrefServiceStatus.error => OrefPalette.pink,
      OrefServiceStatus.disconnected => const Color(0xFF8B97A8),
    };
    final label = switch (status) {
      OrefServiceStatus.ready => 'Connected',
      OrefServiceStatus.connecting => 'Connecting',
      OrefServiceStatus.unavailable => 'Inactive',
      OrefServiceStatus.error => 'Connection error',
      OrefServiceStatus.disconnected => 'Disconnected',
    };

    return _GlassPill(
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

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    this.iconOnly = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool iconOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final content = _GlassPill(
      padding: iconOnly ? const EdgeInsets.all(10) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          if (!iconOnly) ...[
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ],
      ),
    );

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: iconOnly ? Tooltip(message: label, child: content) : content,
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
    return SizedBox.expand(
      child: _GlassCard(
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
                  itemCount: _navDisplayItems.length,
                  itemBuilder: (context, index) {
                    final item = _navDisplayItems[index];
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
  final ValueChanged<_NavItemData> onSelect;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in _navDisplayItems)
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
