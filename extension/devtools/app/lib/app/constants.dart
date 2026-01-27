import 'package:flutter/material.dart';

import 'palette.dart';

class NavItemData {
  const NavItemData(this.label, this.icon);

  final String label;
  final IconData icon;
}

const navItems = [
  NavItemData('Overview', Icons.dashboard_rounded),
  NavItemData('Signals', Icons.bubble_chart_rounded),
  NavItemData('Computed', Icons.schema_rounded),
  NavItemData('Effects', Icons.auto_awesome_motion_rounded),
  NavItemData('Collections', Icons.grid_view_rounded),
  NavItemData('Batching', Icons.layers_rounded),
  NavItemData('Timeline', Icons.timeline_rounded),
];

const utilityItems = [NavItemData('Performance', Icons.speed_rounded)];

const settingsItem = NavItemData('Settings', Icons.tune_rounded);

const navDisplayItems = [...navItems, ...utilityItems];

const allNavItems = [...navDisplayItems, settingsItem];

class PanelInfo {
  const PanelInfo({
    required this.title,
    required this.description,
    required this.bullets,
  });

  final String title;
  final String description;
  final List<String> bullets;
}

const panelInfo = {
  'Computed': PanelInfo(
    title: 'Computed',
    description: 'Understand derived state and cache behavior.',
    bullets: [
      'Dependency graph preview',
      'Cache hit / miss ratio',
      'Invalidation cascade list',
    ],
  ),
  'Effects': PanelInfo(
    title: 'Effects',
    description: 'Track effect execution and lifecycle changes.',
    bullets: [
      'Timeline with rerun counts',
      'Execution duration stats',
      'Dispose + scope diagnostics',
    ],
  ),
  'Collections': PanelInfo(
    title: 'Collections',
    description: 'Audit reactive lists, maps, and sets.',
    bullets: [
      'Mutation history',
      'Diff view for changes',
      'Batch operations overview',
    ],
  ),
  'Batching': PanelInfo(
    title: 'Batching',
    description: 'Inspect batched writes and flush timing.',
    bullets: [
      'Grouped updates per frame',
      'Longest batch duration',
      'Hot write sources',
    ],
  ),
  'Timeline': PanelInfo(
    title: 'Timeline',
    description: 'Correlate signal updates with frame rendering.',
    bullets: [
      'Frame markers + signal spikes',
      'CPU / UI jank overlay',
      'Exportable diagnostics',
    ],
  ),
  'Performance': PanelInfo(
    title: 'Performance',
    description: 'Track frame costs and signal churn hotspots.',
    bullets: [
      'Frame budget + jank markers',
      'Top signal recomputes',
      'Slow effects callouts',
    ],
  ),
  'Settings': PanelInfo(
    title: 'Settings',
    description: 'Tune how diagnostics are collected.',
    bullets: [
      'Sampling frequency',
      'Auto capture thresholds',
      'Export + privacy controls',
    ],
  ),
};

enum SortKey { name, updated }

const signalFilters = ['All', 'Active', 'Dirty', 'Disposed'];

class StatusStyle {
  const StatusStyle(this.color);

  final Color color;
}

const statusStyles = {
  'Active': StatusStyle(OrefPalette.lime),
  'Dirty': StatusStyle(OrefPalette.coral),
  'Disposed': StatusStyle(Color(0xFF8B97A8)),
};

const effectColors = {
  'UI': OrefPalette.teal,
  'Network': OrefPalette.indigo,
  'Persist': OrefPalette.coral,
  'Analytics': OrefPalette.pink,
  'Effect': OrefPalette.teal,
};

const collectionOpColors = {
  'Add': OrefPalette.lime,
  'Remove': OrefPalette.coral,
  'Replace': OrefPalette.indigo,
  'Clear': OrefPalette.pink,
  'Resize': OrefPalette.indigo,
};

const deltaStyles = {
  'add': OrefPalette.lime,
  'remove': OrefPalette.coral,
  'update': OrefPalette.indigo,
};

const timelineColors = {
  'signal': OrefPalette.teal,
  'computed': OrefPalette.indigo,
  'effect': OrefPalette.pink,
  'collection': OrefPalette.coral,
  'batch': OrefPalette.lime,
};

const double effectsTimelineDotSize = 14;
const double effectsTimelineLineWidth = 2;
const double effectsTimelineHorizontalPadding = 16;
const double effectsTimelineLineLeft =
    effectsTimelineHorizontalPadding +
    effectsTimelineDotSize / 2 -
    effectsTimelineLineWidth / 2;
