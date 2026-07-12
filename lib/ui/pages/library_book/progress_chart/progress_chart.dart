import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressChart extends ConsumerStatefulWidget {
  const ProgressChart(this.useOnlyForInitializing);

  final LibraryBook useOnlyForInitializing;

  @override
  ConsumerState createState() => _ProgressChartState();
}

class _ProgressChartState extends ConsumerState<ProgressChart> {
  late LibraryBook _latestBook;

  @override
  void initState() {
    super.initState();
    _latestBook = widget.useOnlyForInitializing;
  }

  @override
  Widget build(BuildContext context) {
    // Check if any format has a length set
    final hasAnyLength = _latestBook.formats.any((f) => f.hasLength);
    if (!hasAnyLength) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          "Set a length for at least one format to see progress chart.",
          style: AppTextStyles.bodySecondary,
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        boxShadow: const [AppShadows.card],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(children: [
          _header(),
          _latestBook.progressHistory.isEmpty
              ? const Text(
                  'No progress updates yet',
                  style: AppTextStyles.bodySecondary,
                )
              : SizedBox(height: 300, child: ref.userLibrary(body))
        ]),
      ),
    );
  }

  Widget _header() {
    final String? paceDisplay = _latestBook.averagePaceDisplay;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text('Progress', style: AppTextStyles.h3),
          if (paceDisplay != null) ...[
            const Spacer(),
            Text(
              paceDisplay,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.teal,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget body(List<LibraryBook> library) {
    final LibraryBook? updatedBook = library
        .where((book) => book.supaId == widget.useOnlyForInitializing.supaId)
        .singleOrNull;
    if (updatedBook == null) {
      return Text(
        'The book ${widget.useOnlyForInitializing.book.title} '
        'has been deleted from your library. '
        'We probably have to pop this screen now?',
      );
    }
    // I think I don't need to setState here since I'm already in the
    // `watch` callback.
    _latestBook = updatedBook;
    return Padding(
      padding: const EdgeInsets.only(right: 24, bottom: 12, left: 4, top: 8),
      child: BooksProgressChart(
        books: [_latestBook],
        colorByFormat: true, // Color-code by format on book detail page
      ),
    );
  }
}
