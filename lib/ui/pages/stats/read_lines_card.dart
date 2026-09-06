import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/app_card.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/material.dart';

class const ReadLinesCard({
  required final List<LibraryBook> books,
  required final DateTime? periodCutoff,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(),
          _chart(),
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

  Widget _chart() {
    return SizedBox(
      height: BooksProgressChart.height,
      child: Padding(
        padding: const EdgeInsets.only(left: 18, right: 35, top: 8, bottom: 14),
        child: BooksProgressChart(books: books, periodCutoff: periodCutoff),
      ),
    );
  }
}
