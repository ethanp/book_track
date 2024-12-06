import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/my_library/my_library_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BottomNavBarElement {
  BottomNavBarElement({required this.item, required this.page});

  final BottomNavigationBarItem item;
  final Widget page;
}

class MyBottomNavBar extends ConsumerWidget {
  static final List<BottomNavBarElement> elements = [
    BottomNavBarElement(
      page: MyLibraryPage(),
      item: BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Library',
      ),
    ),
    BottomNavBarElement(
      page: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Stats'),
        ),
        // TODO make it cupertino style.
        // bottomNavigationBar: MyBottomNavBar(),
        child: Text('Stats page does not exist yet'),
      ),
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
    return BottomNavigationBar(
      onTap: (idx) => idxSelector.update(idx),
      currentIndex: curIdx,
      backgroundColor: Color.lerp(Colors.lightGreen, Colors.grey[100], .92),
      selectedItemColor: Colors.black,
      selectedFontSize: 18,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      items: elements.mapL((BottomNavBarElement elem) => elem.item),
    );
  }
}
