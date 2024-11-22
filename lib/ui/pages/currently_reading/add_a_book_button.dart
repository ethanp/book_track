import 'package:book_track/extensions.dart';
import 'package:book_track/ui/pages/add_a_book/add_book_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddABookButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => context.push(AddBookPage()),
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
}
