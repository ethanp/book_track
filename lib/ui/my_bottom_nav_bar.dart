import 'package:book_track/extensions.dart';
import 'package:book_track/pages/session_page.dart';
import 'package:book_track/riverpods.dart';
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
      item: BottomNavigationBarItem(
        icon: Icon(Icons.book),
        label: 'Session',
      ),
      page: SessionPage(),
    ),
    BottomNavBarElement(
      item: BottomNavigationBarItem(
        icon: Icon(Icons.ssid_chart),
        label: 'Progress',
      ),
      page: Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          backgroundColor: Color.lerp(Colors.lightGreen, Colors.grey[300], 0.8),
        ),
        body: Text('Progress page does not exist yet'),
        bottomNavigationBar: MyBottomNavBar(),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int curIdx = ref.watch(selectedBottomBarIdxProvider);
    final SelectedBottomBarIdx idxBox =
        ref.read(selectedBottomBarIdxProvider.notifier);
    return BottomNavigationBar(
      onTap: (idx) => idxBox.set(idx),
      currentIndex: curIdx,
      backgroundColor: Color.lerp(Colors.lightGreen, Colors.grey[100], .92),
      selectedItemColor: Colors.black,
      selectedFontSize: 18,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700),
      items: elements.mapL((i) => i.item),
    );
  }
}
