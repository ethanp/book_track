import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/sign_out_button.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_book_sheet.dart';
import 'archived_books_page.dart';
import 'archived_books_section.dart';
import 'book_tile.dart';

const _log = ELogger('MyLibraryPage');

class const MyLibraryPage() extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _MyLibraryPageState();
}

class _MyLibraryPageState() extends ConsumerState<MyLibraryPage> {
  _LibraryOrder _libraryOrder = _LibraryOrder.eta;

  @override
  Widget build(BuildContext context) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: EAppHeader(
        title: 'Library',
        leading: IconButton(
          tooltip: 'Add book',
          onPressed: () => AddBookSheet.show(context),
          icon: const Icon(Icons.add),
        ),
        actions: [SignOutButton()],
      ),
      body: _pageBody(),
    );
  }

  Widget _pageBody() {
    return SafeArea(
      bottom: false,
      child: ref
          .watch(userLibraryProvider)
          .when(
            loading: _loadingScreen,
            error: _errorScreen,
            data: _libraryScreen,
          ),
    );
  }

  Widget _libraryScreen(List<LibraryBook> library) {
    library.sortOn(
      _libraryOrder.compareFn,
      descending: _libraryOrder.descending,
    );
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg).withOverlaidTabBar(context),
          sliver: SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _sortSelector()),
              ..._liveStatusSlivers(library.where((book) => !book.archived)),
              ..._archivedSlivers(library.whereL((book) => book.archived)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _liveStatusSlivers(Iterable<LibraryBook> liveBooks) {
    return [
      for (final readingStatus in ReadingStatus.values)
        ..._statusSlivers(
          readingStatus.name,
          liveBooks.whereL((book) => book.readingStatus == readingStatus),
        ),
    ];
  }

  List<Widget> _statusSlivers(String name, List<LibraryBook> books) {
    if (books.isEmpty) return [];
    return [
      SliverToBoxAdapter(child: _statusTitle(name, books.length)),
      SliverList.builder(
        itemCount: books.length,
        itemBuilder: (context, index) => BookTile(books[index]),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
    ];
  }

  List<Widget> _archivedSlivers(List<LibraryBook> archivedBooks) {
    if (archivedBooks.isEmpty) return [];
    return [
      SliverToBoxAdapter(
        child: ArchivedBooksSection(
          onActivated: () => context.push(const ArchivedBooksPage()),
        ),
      ),
    ];
  }

  Widget _sortSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final orderValue in _LibraryOrder.values)
              EFilterChip(
                label: orderValue.label,
                color: EColors.accentGlow,
                selected: _libraryOrder == orderValue,
                onActivated: () => setState(() => _libraryOrder = orderValue),
              ),
          ],
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
              Icons.warning_amber_rounded,
              color: EColors.danger,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Something went wrong loading your library.',
              style: AppTextStyles.body.copyWith(color: EColors.danger),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.md),
            Text('Loading your library...', style: AppTextStyles.bodySecondary),
          ],
        ),
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
        style: AppTextStyles.h2.copyWith(color: EColors.accent),
      ),
    );
  }
}

enum _LibraryOrder(
  final Comparable Function(LibraryBook) compareFn, {
  required final bool descending,
  final String? _label,
}) {
  eta(bookEta, descending: false, label: 'ETA'),
  pace(bookPace, descending: true),
  progress(bookProgress, descending: true),
  startDate(bookStartTime, descending: true);

  String get label => _label ?? nameAsCapitalizedWords;

  static Comparable bookProgress(LibraryBook book) => book.progressPercentage;

  static Comparable bookStartTime(LibraryBook book) =>
      book.firstLoggedProgressAtOrEpoch;

  static Comparable bookPace(LibraryBook book) =>
      book.averageReadingPace?.unitsPerDay ?? 0;

  /// Soonest ETA first; books without an ETA sort last.
  static Comparable bookEta(LibraryBook book) =>
      book.averageReadingPace?.eta ??
      DateTime.fromMillisecondsSinceEpoch(8640000000000000);
}
