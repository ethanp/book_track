import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadLinesCard extends ConsumerWidget {
  const ReadLinesCard({required this.books, required this.periodCutoff});

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool currentlyReadingOnly =
        ref.watch(readLinesCurrentlyReadingOnlyProvider);

    final List<LibraryBook> chartBooks = currentlyReadingOnly
        ? books.whereL((book) => book.isReading)
        : books;

    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          _currentlyReadingToggle(ref, currentlyReadingOnly),
          _chart(chartBooks),
        ],
      ),
    );
  }

  Widget _header() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.xl,
          left: AppSpacing.lg,
        ),
        child: Text('Read Lines', style: AppTextStyles.h3),
      ),
    );
  }

  Widget _currentlyReadingToggle(WidgetRef ref, bool currentlyReadingOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Currently reading only', style: AppTextStyles.body),
          CupertinoSwitch(
            value: currentlyReadingOnly,
            activeTrackColor: AppColors.primary,
            onChanged: (switchValue) => ref
                .read(readLinesCurrentlyReadingOnlyProvider.notifier)
                .state = switchValue,
          ),
        ],
      ),
    );
  }

  Widget _chart(List<LibraryBook> chartBooks) {
    return SizedBox(
      height: 300,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 35, top: 8, bottom: 14),
        child: BooksProgressChart(
          books: chartBooks,
          periodCutoff: periodCutoff,
        ),
      ),
    );
  }
}
