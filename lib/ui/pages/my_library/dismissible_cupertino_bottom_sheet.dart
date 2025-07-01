
import 'package:book_track/ui/pages/add_a_book/add_book_modal_body.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DismissibleCupertinoBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ninetyPercent = .9;
    return SizedBox(
      height: MediaQuery.of(context).size.height * ninetyPercent,
      child: Container(
        decoration: roundedTopCorners(),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          dragHandle(),
          Expanded(child: AddBookModalBody()),
        ]),
      ),
    );
  }

  static void show(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => DismissibleCupertinoBottomSheet(),
    );
  }

  Decoration roundedTopCorners() {
    return BoxDecoration(
      color: CupertinoColors.systemBackground,
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
          color: CupertinoColors.systemGrey,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}
