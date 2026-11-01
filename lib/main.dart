import 'package:book_track/app_identity.dart';
import 'package:book_track/sync/sync_config.dart';
import 'package:book_track/ui/pages/my_library/my_library_page.dart';
import 'package:book_track/ui/pages/stats/stats_page.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';

const _mainTabs = <EMainTab>[
  EMainTab(
    icon: Icons.menu_book_outlined,
    label: 'Library',
    screen: MyLibraryPage(),
  ),
  EMainTab(icon: Icons.bar_chart_outlined, label: 'Stats', screen: StatsPage()),
];

void main() {
  const SyncedAppLaunch(
    appName: AppIdentity.displayName,
    syncConfig: buildBookTrackSyncConfig,
    home: EMainTabScreen(tabs: _mainTabs),
  ).launch();
}
