import 'package:book_track/extensions.dart';
import 'package:book_track/ui/pages/add_a_book/add_book_modal_body.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DismissibleCupertinoBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = .9;
    return GestureDetector(
      // Close when tapping outside
      onTap: context.pop,
      child: DraggableScrollableSheet(
        // Start at x% of screen height,
        initialChildSize: size,
        // Minimum height,
        minChildSize: size,
        // Maximum height.
        maxChildSize: size,
        builder: (BuildContext context, ScrollController scrollController) {
          return Container(
            decoration: roundedTopCorners(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                dragHandle(context),
                Expanded(child: AddBookModalBody()),
              ],
            ),
          );
        },
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

  BoxDecoration roundedTopCorners() {
    return BoxDecoration(
      color: CupertinoColors.systemBackground,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
    );
  }

  Padding dragHandle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey.resolveFrom(context),
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }
}
