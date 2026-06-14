import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/sign_out_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
    library.sortOn(_libraryOrder.compareFn, descending: true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sortSelector(),
        userLibraryByStatus(library),
        if (library.any((b) => b.archived))
          ArchivedBooksSection(books: library.whereL((b) => b.archived)),
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

  Widget errorScreen(Object err, StackTrace stack) {
    final String errorMessage = 'Error loading your library $err $stack';
    _log.error(errorMessage);
    return SelectableText(errorMessage, style: TextStyles.h1);
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
            liveBooks.whereL((b) => b.readingStatus == readingStatus)),
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

  // Enum constructor can only take "constants" (probably means lvalue?)
  static Comparable bookProgress(LibraryBook book) => book.progressPercentage;

  // Enum constructor can only take "constants" (probably means lvalue?)
  static Comparable bookStartTime(LibraryBook book) => book.startTime;
}
