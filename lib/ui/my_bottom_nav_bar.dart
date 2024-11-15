import 'package:book_track/riverpods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyBottomNavBar extends ConsumerWidget {
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
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Session',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.ssid_chart),
          label: 'Progress',
        ),
      ],
    );
  }
}
