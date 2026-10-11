import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'archived_book_row.dart';

class const ArchivedBooksPage() extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EScaffoldShell(
      contentMaxWidth: double.infinity,
      appBar: const EAppHeader(title: 'Archived'),
      body: SafeArea(
        bottom: false,
        child: ref
            .watch(userLibraryProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (library) => _pageBody(context, library),
            ),
      ),
    );
  }

  Widget _pageBody(BuildContext context, List<LibraryBook> library) {
    final archivedBooks = library.whereL((book) => book.archived);
    archivedBooks.sortOn((book) => book.book.title.toLowerCase());
    if (archivedBooks.isEmpty) {
      return Center(
        child: Text('No archived books.', style: AppTextStyles.body),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg).withOverlaidTabBar(context),
      itemCount: archivedBooks.length,
      itemBuilder: (context, index) => ArchivedBookRow(archivedBooks[index]),
    );
  }
}
