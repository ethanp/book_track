import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/my_bottom_nav_bar.dart';
import 'package:book_track/ui/common/sign_out_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_a_book_button.dart';
import 'book_tile.dart';

class CurrentlyReadingPage extends ConsumerStatefulWidget {
  const CurrentlyReadingPage({super.key});

  @override
  ConsumerState createState() => _CurrentlyReadingPageState();
}

class _CurrentlyReadingPageState extends ConsumerState<CurrentlyReadingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currently Reading'),
        backgroundColor: Color.lerp(Colors.lightGreen, Colors.grey[300], 0.8),
        actions: [SignOutButton()],
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        color: Color.lerp(Colors.yellow, Colors.grey[100], .98),
        // TODO add a line chart with all the currently-reading books.
        // TODO add a line chart of the progress across all books in
        //  the past year (and varying and customizable periods)
        child: sessionUi(),
      ),
      floatingActionButton: AddABookButton(),
      bottomNavigationBar: MyBottomNavBar(),
    );
  }

  Widget sessionUi() {
    var userLibraryAsyncValue = ref.watch(userLibraryProvider);
    return userLibraryAsyncValue.when(
      loading: () => Text('Loading your library...', style: TextStyles().h1),
      error: (err, stack) => Text(
        'Error loading your library $err $stack',
        style: TextStyles().h1,
      ),
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resume reading', style: TextStyles().h1),
          Expanded(child: ListView(children: items.mapL(BookTile.new))),
        ],
      ),
    );
  }
}
