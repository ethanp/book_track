import 'package:book_track/data_model.dart';
import 'package:book_track/ui/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'progress_view.dart';

class SessionStartPage extends ConsumerWidget {
  const SessionStartPage(this.book);

  final BookProgress book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: Text(book.book.title),
      ),
      body: Column(
        children: [
          ProgressView(book),
          ElevatedButton(
            onPressed: () {},
            child: Text('Start Session'),
          ),
        ],
      ),
    );
  }
}
