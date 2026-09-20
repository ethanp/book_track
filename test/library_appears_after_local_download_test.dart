import 'dart:async';

import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/sync/library_providers.dart';
import 'package:book_track/sync/library_repository.dart';
import 'package:book_track/ui/pages/my_library/my_library_page.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _downloadedTitle = 'The Integration Test';

void main() {
  test(
    'userLibrary re-reads after a local revision even if the first read was empty',
    () async {
      final laterRevisions = StreamController<int>();
      addTearDown(laterRevisions.close);
      final catalog = _ScriptedLibraryCatalog();
      final container = ProviderContainer(
        overrides: [
          localDataRevisionProvider.overrideWith((ref) async* {
            yield 0;
            yield* laterRevisions.stream;
          }),
          libraryCatalogProvider.overrideWith((ref) async => catalog),
        ],
      );
      addTearDown(container.dispose);
      container.listen(userLibraryProvider, (_, _) {});

      expect(await container.read(userLibraryProvider.future), isEmpty);

      catalog.books = [_downloadedLibraryBook()];
      laterRevisions.add(1);

      final library = await _libraryAfterRevision(container);
      expect(library, hasLength(1));
      expect(library.single.book.title, _downloadedTitle);
    },
  );

  testWidgets(
    'library page shows a downloaded book without reopen or refresh',
    (tester) async {
      final laterRevisions = StreamController<int>();
      addTearDown(laterRevisions.close);
      final catalog = _ScriptedLibraryCatalog();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localDataRevisionProvider.overrideWith((ref) async* {
              yield 0;
              yield* laterRevisions.stream;
            }),
            libraryCatalogProvider.overrideWith((ref) async => catalog),
            hasCompletedFirstDownloadProvider.overrideWithValue(false),
            syncStatusCaptionProvider.overrideWithValue(
              'Downloading library...',
            ),
            syncStatusDetailsProvider.overrideWithValue(
              SyncStatusDetails(
                phase: SyncPhase.downloading,
                caption: 'Downloading library...',
                connected: true,
              ),
            ),
          ],
          child: MaterialApp(
            theme: ETheme.material3Dark,
            home: const MyLibraryPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Downloading library...'), findsWidgets);

      catalog.books = [_downloadedLibraryBook()];
      laterRevisions.add(1);
      await tester.pump();
      await tester.pump();

      expect(find.text(_downloadedTitle), findsOneWidget);
    },
  );
}

class _ScriptedLibraryCatalog() implements LibraryCatalog {
  List<LibraryBook> books = [];

  @override
  Future<List<LibraryBook>> myBooks() async => List.of(books);
}

LibraryBook _downloadedLibraryBook() {
  return LibraryBook(
    'lib-1',
    const Book('book-1', _downloadedTitle, 'Ada', null, null, null),
    const [],
    const [],
    false,
    null,
  );
}

Future<List<LibraryBook>> _libraryAfterRevision(
  ProviderContainer container,
) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final library = await container.read(userLibraryProvider.future);
    if (library.isNotEmpty) return library;
  }
  return container.read(userLibraryProvider.future);
}
