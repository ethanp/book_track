import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/sign_out_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_tile.dart';
import 'dismissible_cupertino_bottom_sheet.dart';

class MyLibraryPage extends ConsumerStatefulWidget {
  const MyLibraryPage({super.key});

  @override
  ConsumerState createState() => _MyLibraryPageState();
}

class _MyLibraryPageState extends ConsumerState<MyLibraryPage> {
  // static final SimpleLogger log = SimpleLogger(prefix: 'MyLibraryPage');

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: navigationBar(context),
      child: pageBody(),
    );
  }

  Widget pageBody() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ref.watch(userLibraryProvider).when(
              loading: loadingScreen,
              error: errorScreen,
              data: userLibraryByStatus,
            ),
      ),
    );
  }

  CupertinoNavigationBar navigationBar(BuildContext context) {
    return CupertinoNavigationBar(
      leading: addABookButton(context),
      middle: Text('My Library'),
      trailing: SignOutButton(),
    );
  }

  Widget errorScreen(err, stack) =>
      Text('Error loading your library $err $stack', style: TextStyles().h1);

  Widget loadingScreen() =>
      Text('Loading your library...', style: TextStyles().h1);

  Widget addABookButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => DismissibleCupertinoBottomSheet.show(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 20),
          Text('Add book', style: TextStyle(fontSize: 13))
        ],
      ),
    );
  }

  Widget userLibraryByStatus(Iterable<LibraryBook> fullLibrary) {
    // TODO(feature) add a line chart with all the currently-reading books.
    // TODO(feature) add a line chart of the progress across all books in
    //   the past year (and varying and customizable periods).
    // TODO(feature) add an indicator of pages read in the past week, and a chart
    //  of pages read per week, across time.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: ReadingStatus.values.mapL(
        (readingStatus) => statusSection(readingStatus, fullLibrary),
      ),
    );
  }

  Widget statusSection(
    ReadingStatus readingStatus,
    Iterable<LibraryBook> fullLibrary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statusTitle(readingStatus),
          booksWithStatus(fullLibrary, readingStatus),
        ],
      ),
    );
  }

  Widget booksWithStatus(
    Iterable<LibraryBook> fullLibrary,
    ReadingStatus readingStatus,
  ) {
    return ListView(
      shrinkWrap: true,
      children: fullLibrary
          .where((book) => book.readingStatus == readingStatus)
          .mapL(BookTile.new),
    );
  }

  Widget statusTitle(ReadingStatus readingStatus) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        readingStatus.name.capitalize,
        style: TextStyles().h1,
      ),
    );
  }
}
