import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/sign_out_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_tile.dart';
import 'dismissible_cupertino_bottom_sheet.dart';

class MyLibraryPage extends ConsumerStatefulWidget {
  const MyLibraryPage({super.key});

  @override
  ConsumerState createState() => _MyLibraryPageState();
}

class _MyLibraryPageState extends ConsumerState<MyLibraryPage> {
  static final SimpleLogger log = SimpleLogger(prefix: 'MyLibraryPage');

  bool _showingArchived = false;

  _LibraryOrder _libraryOrder = _LibraryOrder.progress;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: navigationBar(context),
      child: pageBody(),
    );
  }

  CupertinoNavigationBar navigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      leading: addABookButton(context),
      middle: const Text('My Library'),
      trailing: SignOutButton(),
    );
  }

  Widget pageBody() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ref.watch(userLibraryProvider).when(
                loading: loadingScreen,
                error: errorScreen,
                data: libraryScreen,
              ),
        ),
      ),
    );
  }

  Widget libraryScreen(List<LibraryBook> library) {
    _libraryOrder.sortDescending(library);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TODO(feature) add an indicator of pages read in the past week.
        sortSelector(),
        userLibraryByStatus(library),
        if (library.any((b) => b.archived)) archivedSection(library),
      ],
    );
  }

  Widget sortSelector() {
    return Center(
      child: CupertinoSegmentedControl<_LibraryOrder>(
        groupValue: _libraryOrder,
        children: {
          for (final value in _LibraryOrder.values)
            value: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(value.nameAsCapitalizedWords),
            ),
        },
        onValueChanged: (choice) => setState(() => _libraryOrder = choice),
      ),
    );
  }

  Widget archivedSection(List<LibraryBook> library) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        showArchivedToggleButton(),
        if (_showingArchived)
          bookSection('Archived', library.where((b) => b.archived).toList()),
      ],
    );
  }

  Widget showArchivedToggleButton() {
    return CupertinoButton(
      child: Text(
        '${_showingArchived ? 'Hide' : 'See'} archived books...',
        style: TextStyles.h3.copyWith(color: CupertinoColors.activeBlue),
      ),
      onPressed: () => setState(() => _showingArchived = !_showingArchived),
    );
  }

  Widget errorScreen(Object err, StackTrace stack) {
    final String errorMessage = 'Error loading your library $err $stack';
    log(errorMessage, error: true);
    return Text(errorMessage, style: TextStyles.h1);
  }

  Widget loadingScreen() =>
      Text('Loading your library...', style: TextStyles.h1);

  Widget addABookButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => DismissibleCupertinoBottomSheet.show(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.add, size: 20),
          Text('Add book', style: const TextStyle(fontSize: 13))
        ],
      ),
    );
  }

  Widget userLibraryByStatus(Iterable<LibraryBook> fullLibrary) {
    final liveBooks = fullLibrary.where((b) => !b.archived);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ReadingStatus.values.mapL(
        (readingStatus) => bookSection(readingStatus.name,
            liveBooks.where((b) => b.readingStatus == readingStatus).toList()),
      ),
    );
  }

  Widget bookSection(String name, List<LibraryBook> books) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statusTitle(name, books.length),
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

  Widget statusTitle(String name, int count) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        '${name.capitalize} ($count)',
        style: TextStyles.h1,
      ),
    );
  }
}

enum _LibraryOrder {
  progress(bookProgress),
  startDate(bookStartTime);

  final Comparable Function(LibraryBook) compareFn;

  const _LibraryOrder(this.compareFn);

  void sortDescending(List<LibraryBook> library) =>
      library.sort((a, b) => compareFn(b).compareTo(compareFn(a)));

  // Enum constructor can only take "constants" (probably means lvalue?)
  static Comparable bookProgress(LibraryBook book) => book.progressPercentage;

  // Enum constructor can only take "constants" (probably means lvalue?)
  static Comparable bookStartTime(LibraryBook book) => book.startTime;
}
