import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/my_books_service.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/common/my_bottom_nav_bar.dart';
import 'package:book_track/ui/common/sign_out_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_a_book_button.dart';
import 'book_tile.dart';

class CurrentlyReadingPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

  Widget sessionUi() {
    final List<BookProgress> books = MyBooksService.all();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resume reading',
          style: TextStyles().h1,
        ),
        Expanded(child: ListView(children: books.mapL(BookTile.new))),
      ],
    );
  }
}
