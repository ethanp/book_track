import 'package:book_track/ui/pages/add_a_book/add_book_page.dart';
import 'package:flutter/material.dart';

class AddABookButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AddBookPage()),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add),
            Text(
              'Add book',
              style: TextStyle(fontSize: 8),
            )
          ],
        ),
      ),
    );
  }
}
