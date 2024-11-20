import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/session_timer/session_timer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_properties_editor.dart';
import 'progress_history_view.dart';

class LibraryBookPage extends ConsumerWidget {
  const LibraryBookPage(this.libraryBook);

  final LibraryBook libraryBook;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPalette().appBarColor,
        title: Text(libraryBook.book.title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            BookPropertiesEditor(libraryBook),
            buttons(context),
            historyChart(),
          ],
        ),
      ),
    );
  }

  Widget historyChart() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ProgressHistoryView(libraryBook),
      ),
    );
  }

  Widget buttons(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          outlinedButton(
            text: 'Update progress',
            backgroundColor: Colors.pink[100]!.withOpacity(0.5),
            onPressed: () =>
                // TODO show the update progress modal.
                context.push(SessionTimerPage(libraryBook)),
          ),
          outlinedButton(
            text: '🧑‍🎓 Start session',
            backgroundColor: Colors.blue[100]!.withOpacity(0.5),
            onPressed: () => context.push(SessionTimerPage(libraryBook)),
          ),
        ],
      ),
    );
  }

  Widget outlinedButton({
    required String text,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        visualDensity: VisualDensity.compact,
        side: BorderSide(width: 1.5),
        backgroundColor: backgroundColor,
        elevation: 4,
      ),
      child: Text(text, style: TextStyles().h1),
    );
  }
}
