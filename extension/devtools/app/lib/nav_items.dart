part of 'main.dart';

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

const _utilityItems = [_NavItemData('Performance', Icons.speed_rounded)];

const _settingsItem = _NavItemData('Settings', Icons.tune_rounded);

const _navDisplayItems = [..._navItems, ..._utilityItems];

const _allNavItems = [..._navDisplayItems, _settingsItem];
