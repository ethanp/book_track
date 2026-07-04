import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/my_library/my_library_page.dart';
import 'package:book_track/ui/pages/stats/stats_page.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavbarElement {
  BottomNavbarElement({required this.item, required this.page});

  final BottomNavigationBarItem item;
  final Widget page;
}

class MainstageAndBottomNavbar extends ConsumerWidget {
  static final List<BottomNavbarElement> bottomNavbarElements = [
    BottomNavbarElement(
      page: MyLibraryPage(),
      item: BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.book),
        label: 'Library',
      ),
    ),
    BottomNavbarElement(
      page: StatsPage(),
      item: BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.chart_bar),
        label: 'Stats',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int curIdx = ref.watch(selectedBottomBarIdxProvider);
    final SelectedBottomBarIdx idxSelector =
        ref.read(selectedBottomBarIdxProvider.notifier);
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: bottomNavbarElements.mapL((element) => element.item),
        currentIndex: curIdx,
        onTap: (idx) => idxSelector.update(idx),
        activeColor: AppColors.tabBarActive,
        inactiveColor: AppColors.tabBarInactive,
        backgroundColor: AppColors.navBarBackground,
      ),
      backgroundColor: AppColors.background,
      tabBuilder: (context, idx) => CupertinoTabView(
        builder: (context) => bottomNavbarElements[idx].page,
      ),
    );
  }
}
