import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/stats/stats_providers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReadLinesCard extends ConsumerWidget {
  const ReadLinesCard({
    required this.books,
    required this.periodCutoff,
    super.key,
  });

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool currentlyReadingOnly =
        ref.watch(readLinesCurrentlyReadingOnlyProvider);

    final List<LibraryBook> chartBooks = currentlyReadingOnly
        ? books.whereL((book) => book.readingStatus == ReadingStatus.reading)
        : books;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
        padding: const EdgeInsets.only(top: 18, bottom: 20, left: 16),
        child: Text('Read Lines', style: TextStyles.h3),
      ),
    );
  }

  Widget _currentlyReadingToggle(WidgetRef ref, bool currentlyReadingOnly) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Currently reading only'),
          CupertinoSwitch(
            value: currentlyReadingOnly,
            onChanged: (value) => ref
                .read(readLinesCurrentlyReadingOnlyProvider.notifier)
                .state = value,
          ),
        ],
      ),
    );
  }

  Widget _chart(List<LibraryBook> chartBooks) {
    return SizedBox(
      height: 300,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 18, right: 35, top: 8, bottom: 14),
        child: BooksProgressChart(
          books: chartBooks,
          periodCutoff: periodCutoff,
        ),
      ),
    );
  }
}
