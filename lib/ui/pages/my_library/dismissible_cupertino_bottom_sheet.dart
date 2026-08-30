import 'package:book_track/ui/pages/add_a_book/add_book_modal_body.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const DismissibleCupertinoBottomSheet() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ninetyPercent = .9;
    return SizedBox(
      height: MediaQuery.of(context).size.height * ninetyPercent,
      child: Container(
        decoration: roundedTopCorners(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            dragHandle(),
            Expanded(child: AddBookModalBody()),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => DismissibleCupertinoBottomSheet(),
    );
  }

  Decoration roundedTopCorners() {
    return BoxDecoration(
      color: EColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
    );
  }

  Widget dragHandle() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: EColors.borderStrong,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}
