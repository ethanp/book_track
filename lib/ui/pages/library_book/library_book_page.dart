import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/my_library/reading_progress_indicator.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_buttons.dart';
import 'book_properties_editor.dart';
import 'event_timeline.dart';
import 'formats_section.dart';
import 'progress_chart/progress_chart.dart';

class const LibraryBookPage(final int bookId) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(userLibraryProvider);
    return libraryAsync.when(
      loading: () => const EScaffoldShell(
        contentMaxWidth: double.infinity,
        appBar: EAppHeader(title: 'Book'),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => EScaffoldShell(
        contentMaxWidth: double.infinity,
        appBar: const EAppHeader(title: 'Book'),
        body: Center(
          child: Text(
            'Error: $error',
            style: AppTextStyles.body.copyWith(color: EColors.danger),
          ),
        ),
      ),
      data: (books) {
        final book = books.where((book) => book.supaId == bookId).firstOrNull;
        if (book == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }
        return _bookPage(context, book);
      },
    );
  }

  Widget _bookPage(BuildContext context, LibraryBook book) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(
        title: book.book.title,
        subtitle: book.readingStatus.name,
        actions: [ReadingProgressIndicator(book)],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero.withOverlaidTabBar(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookPropertiesEditor(book),
              FormatsSection(book),
              BookDetailButtons(book),
              ProgressChart(book),
              EventTimeline(book),
            ],
          ),
        ),
      ),
    );
  }
}
