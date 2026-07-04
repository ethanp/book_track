import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/sign_out_button.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:book_track/ui/pages/my_library/archived_books_section.dart';
import 'package:book_track/ui/pages/my_library/book_tile.dart';
import 'dismissible_cupertino_bottom_sheet.dart';

const _log = ELogger('MyLibraryPage');

class MyLibraryPage extends ConsumerStatefulWidget {
  const MyLibraryPage({super.key});

  @override
  ConsumerState createState() => _MyLibraryPageState();
}

class _MyLibraryPageState extends ConsumerState<MyLibraryPage> {
  _LibraryOrder _libraryOrder = _LibraryOrder.progress;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _navigationBar(context),
      child: _pageBody(),
    );
  }

  CupertinoNavigationBar _navigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      leading: _addABookButton(context),
      middle: const Text('My Library'),
      trailing: SignOutButton(),
    );
  }

  Widget _pageBody() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ref.watch(userLibraryProvider).when(
                loading: _loadingScreen,
                error: _errorScreen,
                data: _libraryScreen,
              ),
        ),
      ),
    );
  }

  Widget _libraryScreen(List<LibraryBook> library) {
    library.sortOn(_libraryOrder.compareFn, descending: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sortSelector(),
        _userLibraryByStatus(library),
        if (library.any((book) => book.archived))
          ArchivedBooksSection(
              books: library.whereL((book) => book.archived)),
      ],
    );
  }

  Widget _sortSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: CupertinoSlidingSegmentedControl<_LibraryOrder>(
          groupValue: _libraryOrder,
          children: {
            for (final orderValue in _LibraryOrder.values)
              orderValue: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  orderValue.nameAsCapitalizedWords,
                  style: AppTextStyles.label,
                ),
              ),
          },
          onValueChanged: (choice) => setState(() => _libraryOrder = choice!),
        ),
      ),
    );
  }

  Widget _errorScreen(Object err, StackTrace stack) {
    _log.error('Error loading your library $err $stack');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              color: AppColors.destructive,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong loading your library.',
              style: AppTextStyles.body.copyWith(color: AppColors.destructive),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingScreen() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            CupertinoActivityIndicator(radius: 14),
            SizedBox(height: AppSpacing.md),
            Text('Loading your library...', style: AppTextStyles.bodySecondary),
          ],
        ),
      ),
    );
  }

  Widget _addABookButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => DismissibleCupertinoBottomSheet.show(context),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.add, size: 20, color: AppColors.primary),
          Text(
            'Add book',
            style: TextStyle(fontSize: 12, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _userLibraryByStatus(Iterable<LibraryBook> fullLibrary) {
    final liveBooks = fullLibrary.where((book) => !book.archived);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ReadingStatus.values.mapL(
        (readingStatus) => _bookSection(readingStatus.name,
            liveBooks.whereL((book) => book.readingStatus == readingStatus)),
      ),
    );
  }

  Widget _bookSection(String name, List<LibraryBook> books) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusTitle(name, books.length),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: books.length,
            itemBuilder: (ctx, idx) => BookTile(books[idx], idx),
          ),
        ],
      ),
    );
  }

  Widget _statusTitle(String name, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Text(
        '${name.capitalize} ($count)',
        style: AppTextStyles.h2.copyWith(color: AppColors.burgundy),
      ),
    );
  }
}

enum _LibraryOrder {
  progress(bookProgress),
  startDate(bookStartTime);

  final Comparable Function(LibraryBook) compareFn;

  const _LibraryOrder(this.compareFn);

  static Comparable bookProgress(LibraryBook book) => book.progressPercentage;

  static Comparable bookStartTime(LibraryBook book) => book.startTime;
}
