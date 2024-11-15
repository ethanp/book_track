import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/services/my_books_service.dart';
import 'package:book_track/ui/add_a_book_button.dart';
import 'package:book_track/ui/book_tile.dart';
import 'package:book_track/ui/my_bottom_nav_bar.dart';
import 'package:book_track/ui/sign_out_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('= Book = Track ='),
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        Expanded(child: ListView(children: books.mapL(BookTile.new))),
      ],
    );
  }
}
