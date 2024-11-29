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

class CurrentlyReadingPage extends ConsumerStatefulWidget {
  const CurrentlyReadingPage({super.key});

  @override
  ConsumerState createState() => _CurrentlyReadingPageState();
}

class _CurrentlyReadingPageState extends ConsumerState<CurrentlyReadingPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    ref.watch(userLibraryProvider).whenData((items) => setState(() {
          print('currently reading: sourcing stored format');
        }));
  }

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
              data: userLibrary,
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

  Widget userLibrary(Iterable<LibraryBook> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        librarySection(items, 'Resume reading', ReadingStatus.reading),
        librarySection(items, 'Finished reading', ReadingStatus.completed),
        librarySection(items, 'Abandoned', ReadingStatus.abandoned),
        // TODO(feature) add a line chart with all the currently-reading books.
        // TODO(feature) add a line chart of the progress across all books in
        //   the past year (and varying and customizable periods).
        // TODO(feature) add an indicator of pages read in the past week, and a chart
        //  of pages read per week, across time.
      ],
    );
  }

  Widget librarySection(
    Iterable<LibraryBook> items,
    String title,
    ReadingStatus readingStatus,
  ) {
    final List<Widget> listTiles = items
        .where((book) => book.status == readingStatus)
        .map(BookTile.new)
        .mapL((tile) => Padding(
            padding: const EdgeInsets.all(6),
            child: SizedBox(height: 38, child: tile)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(title, style: TextStyles().h1),
          ),
          SizedBox(height: 4),
          ListView(shrinkWrap: true, children: listTiles),
        ],
      ),
    );
  }
}
