import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/app_bars.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/my_library/reading_progress_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_detail_buttons.dart';
import 'book_properties_editor.dart';
import 'event_timeline.dart';
import 'formats_section.dart';
import 'progress_chart/progress_chart.dart';

class LibraryBookPage extends ConsumerWidget {
  const LibraryBookPage(this.bookId);

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(userLibraryProvider);
    return libraryAsync.when(
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (error, _) => CupertinoPageScaffold(
        child: Center(
          child: Text(
            'Error: $error',
            style: AppTextStyles.body.copyWith(color: AppColors.destructive),
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
        return _buildPage(book);
      },
    );
  }

  Widget _buildPage(LibraryBook book) {
    return CupertinoPageScaffold(
      navigationBar: _navBar(book),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BookPropertiesEditor(book),
              BookDetailButtons(book),
              ProgressChart(book),
              FormatsSection(book),
              EventTimeline(book),
            ],
          ),
        ),
      ),
    );
  }

  ObstructingPreferredSizeWidget _navBar(LibraryBook book) {
    return AppNavigationBar(
      middle: Row(
        children: [
          Expanded(
            child: Text(
              '${book.book.title} (${book.readingStatus.name})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                inherit: false,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ReadingProgressIndicator(book),
        ],
      ),
    );
  }
}
