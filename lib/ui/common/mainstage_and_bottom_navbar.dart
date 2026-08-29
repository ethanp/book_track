import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/my_library/my_library_page.dart';
import 'package:book_track/ui/pages/stats/stats_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainTab {
  const MainTab({
    required this.icon,
    required this.label,
    required this.screen,
  });

  final IconData icon;
  final String label;
  final Widget screen;
}

const _mainTabs = <MainTab>[
  MainTab(
    icon: Icons.menu_book_outlined,
    label: 'Library',
    screen: MyLibraryPage(),
  ),
  MainTab(
    icon: Icons.bar_chart_outlined,
    label: 'Stats',
    screen: StatsPage(),
  ),
];

class MainstageAndBottomNavbar extends ConsumerStatefulWidget {
  @override
  ConsumerState<MainstageAndBottomNavbar> createState() =>
      _MainstageAndBottomNavbarState();
}

class _MainstageAndBottomNavbarState
    extends ConsumerState<MainstageAndBottomNavbar> {
  final _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(
    _mainTabs.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  Widget build(BuildContext context) {
    final int selectedTabIndex = ref.watch(selectedBottomBarIdxProvider);
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      bottomBar: ETabBar(
        selectedIndex: selectedTabIndex,
        tabs: [
          for (final tab in _mainTabs) ETab(icon: tab.icon, label: tab.label),
        ],
        onSelected: (index) {
          if (index == selectedTabIndex) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
            return;
          }
          ref.read(selectedBottomBarIdxProvider.notifier).update(index);
        },
      ),
      body: IndexedStack(
        index: selectedTabIndex,
        children: [
          for (var tabIndex = 0; tabIndex < _mainTabs.length; tabIndex++)
            Navigator(
              key: _navigatorKeys[tabIndex],
              onGenerateRoute: (settings) => MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => _mainTabs[tabIndex].screen,
              ),
            ),
        ],
      ),
    );
  }
}
