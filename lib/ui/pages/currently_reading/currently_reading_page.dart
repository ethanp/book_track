import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/supabase_service.dart';
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
        child: sessionUi(),
      ),
      floatingActionButton: AddABookButton(),
      bottomNavigationBar: MyBottomNavBar(),
    );
  }

  late final Future<List<BookProgress>> myBooks;

  @override
  void initState() {
    super.initState();
    myBooks = SupabaseLibraryService.myBooks();
  }

  @override
  void dispose() {
    myBooks.ignore();
    super.dispose();
  }

  Widget sessionUi() {
    return FutureBuilder(
        future: myBooks,
        builder: (context, AsyncSnapshot<List<BookProgress>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('Loading your library...', style: TextStyles().h1);
          } else if (snapshot.hasData && snapshot.data != null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume reading',
                  style: TextStyles().h1,
                ),
                Expanded(
                    child:
                        ListView(children: snapshot.data!.mapL(BookTile.new))),
              ],
            );
          } else {
            return Text('Could not load your library', style: TextStyles().h1);
          }
        });
  }
}
