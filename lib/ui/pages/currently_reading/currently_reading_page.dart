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
      navigationBar: CupertinoNavigationBar(
        leading: addABookButton(context),
        middle: Text('Currently Reading'),
        trailing: SignOutButton(),
      ),
      // TODO use the CupertinoNavigationBar up top? Ask chatGpt.
      // bottomNavigationBar: MyBottomNavBar(),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Color.lerp(Colors.yellow, Colors.grey[100], .98),
                // TODO(feature) add a line chart with all the currently-reading books.
                // TODO(feature) add a line chart of the progress across all books in
                //   the past year (and varying and customizable periods).
                child: ref
                    .watch(userLibraryProvider)
                    .when(loading: loadingText, error: errorText, data: body),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CupertinoButton addABookButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => DismissibleCupertinoBottomSheet.show(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 20),
          Text(
            'Add book',
            style: TextStyle(fontSize: 13),
          )
        ],
      ),
    );
  }

  Widget loadingText() =>
      Text('Loading your library...', style: TextStyles().h1);

  Widget errorText(err, stack) => Text(
        'Error loading your library $err $stack',
        style: TextStyles().h1,
      );

  Widget body(Iterable<LibraryBook> items) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tiles(items, 'Resume reading', ReadingStatus.reading),
        tiles(items, 'Finished reading', ReadingStatus.completed),
        tiles(items, 'Abandoned', ReadingStatus.abandoned),
      ],
    );
  }

  Widget tiles(
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
      padding: const EdgeInsets.all(8.0),
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
