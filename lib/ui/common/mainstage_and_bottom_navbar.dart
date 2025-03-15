import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/my_library/my_library_page.dart';
import 'package:book_track/ui/pages/stats/stats_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavbarElement {
  BottomNavbarElement({required this.item, required this.page});

  final BottomNavigationBarItem item;
  final Widget page;
}

class MainstageAndBottomNavbar extends ConsumerWidget {
  static final List<BottomNavbarElement> elements = [
    BottomNavbarElement(
      page: MyLibraryPage(),
      item: BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Library',
      ),
    ),
    BottomNavbarElement(
      page: StatsPage(),
      item: BottomNavigationBarItem(
        icon: Icon(Icons.ssid_chart),
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
        items: elements.mapL((e) => e.item),
        currentIndex: curIdx,
        onTap: (idx) => idxSelector.update(idx),
      ),
      backgroundColor: Color.lerp(Colors.lightGreen, Colors.grey[100], .92),
      tabBuilder: (context, idx) => CupertinoTabView(
        builder: (context) => elements[idx].page,
      ),
    );
  }
}
