import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session_timer/session_timer_page.dart';
import 'progress_history_view.dart';

class SessionStartPage extends ConsumerWidget {
  const SessionStartPage(this.book);

  final BookProgress book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorPalette().appBarColor,
        title: Text(book.book.title),
      ),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ProgressHistoryView(book),
            ),
          ),
          startSessionButton(context)
        ],
      ),
    );
  }

  Widget startSessionButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: ElevatedButton(
        onPressed: () => context.push(SessionTimerPage(book)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.green[100],
          elevation: 4,
        ),
        child: Text('🧑‍🎓 Start session', style: TextStyles().h1),
      ),
    );
  }
}
