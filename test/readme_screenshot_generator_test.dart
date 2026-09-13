import 'dart:io';
import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:book_track/ui/pages/my_library/my_library_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _phoneSize = Size(390, 844);

void main() {
  setUpAll(() async {
    await ETheme.loadFontsForWidgetTests();
    _OverviewJackets.load();
  });

  testWidgets('writes library overview for README', (tester) async {
    await _writeReadmeScreenshot(
      tester,
      home: const MyLibraryPage(),
      screenshotFilename: 'homescreen.png',
    );
  });

  testWidgets('writes book progress for README', (tester) async {
    await _writeReadmeScreenshot(
      tester,
      home: const LibraryBookPage(4),
      screenshotFilename: 'book-progress.png',
    );
  });
}

Future<void> _writeReadmeScreenshot(
  WidgetTester tester, {
  required Widget home,
  required String screenshotFilename,
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(_phoneSize);

  try {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userLibraryProvider.overrideWith((ref) async => _overviewLibrary()),
        ],
        child: MaterialApp(
          theme: ETheme.material3Dark,
          debugShowCheckedModeBanner: false,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final imageElement in find.byType(Image).evaluate()) {
        final Image image = imageElement.widget as Image;
        await precacheImage(image.image, imageElement);
      }
    });
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../screenshots/$screenshotFilename'),
    );
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

List<LibraryBook> _overviewLibrary() {
  return [
    LibraryBook(
      1,
      Book(1, 'The Left Hand of Darkness', 'Ursula K. Le Guin', 1969, null, _OverviewJackets.leftHandOfDarkness),
      [
        ProgressEvent(
          supaId: 11,
          formatId: 101,
          end: DateTime(2026, 6, 2),
          progress: 12,
          format: ProgressEventFormat.pageNum,
        ),
        ProgressEvent(
          supaId: 12,
          formatId: 101,
          end: DateTime(2026, 6, 20),
          progress: 88,
          format: ProgressEventFormat.pageNum,
        ),
        ProgressEvent(
          supaId: 13,
          formatId: 101,
          end: DateTime(2026, 7, 8),
          progress: 164,
          format: ProgressEventFormat.pageNum,
        ),
        ProgressEvent(
          supaId: 14,
          formatId: 101,
          end: DateTime(2026, 8, 1),
          progress: 210,
          format: ProgressEventFormat.pageNum,
        ),
      ],
      const [
        LibraryBookFormat(
          supaId: 101,
          libraryBookId: 1,
          format: BookFormat.paperback,
          length: 304,
        ),
      ],
      false,
      null,
    ),
    LibraryBook(
      2,
      Book(2, 'Project Hail Mary', 'Andy Weir', 2021, null, _OverviewJackets.projectHailMary),
      [
        ProgressEvent(
          supaId: 21,
          formatId: 201,
          end: DateTime(2026, 4, 10),
          progress: 40,
          format: ProgressEventFormat.pageNum,
        ),
        ProgressEvent(
          supaId: 22,
          formatId: 201,
          end: DateTime(2026, 5, 2),
          progress: 476,
          format: ProgressEventFormat.pageNum,
        ),
      ],
      const [
        LibraryBookFormat(
          supaId: 201,
          libraryBookId: 2,
          format: BookFormat.hardcover,
          length: 476,
        ),
      ],
      false,
      null,
    ),
    LibraryBook(
      3,
      Book(3, 'A Psalm for the Wild-Built', 'Becky Chambers', 2021, null, _OverviewJackets.psalmForTheWildBuilt),
      [
        ProgressEvent(
          supaId: 31,
          formatId: 301,
          end: DateTime(2026, 3, 1),
          progress: 10,
          format: ProgressEventFormat.pageNum,
        ),
        ProgressEvent(
          supaId: 32,
          formatId: 301,
          end: DateTime(2026, 3, 18),
          progress: 60,
          format: ProgressEventFormat.pageNum,
        ),
      ],
      const [
        LibraryBookFormat(
          supaId: 301,
          libraryBookId: 3,
          format: BookFormat.eBook,
          length: 160,
        ),
      ],
      false,
      DateTime(2026, 3, 18),
    ),
    LibraryBook(
      4,
      Book(4, 'Piranesi', 'Susanna Clarke', 2020, null, _OverviewJackets.piranesi),
      [
        ProgressEvent(
          supaId: 41,
          formatId: 401,
          end: DateTime(2026, 9, 1),
          progress: 30,
          format: ProgressEventFormat.minutes,
        ),
        ProgressEvent(
          supaId: 42,
          formatId: 401,
          end: DateTime(2026, 9, 10),
          progress: 180,
          format: ProgressEventFormat.minutes,
        ),
      ],
      const [
        LibraryBookFormat(
          supaId: 401,
          libraryBookId: 4,
          format: BookFormat.audiobook,
          length: 436,
        ),
      ],
      false,
      null,
    ),
  ];
}

abstract final class _OverviewJackets {
  static late final Uint8List leftHandOfDarkness;
  static late final Uint8List projectHailMary;
  static late final Uint8List psalmForTheWildBuilt;
  static late final Uint8List piranesi;

  static void load() {
    leftHandOfDarkness = _jpeg('left_hand_of_darkness.jpg');
    projectHailMary = _jpeg('project_hail_mary.jpg');
    psalmForTheWildBuilt = _jpeg('psalm_for_the_wild_built.jpg');
    piranesi = _jpeg('piranesi.jpg');
  }

  static Uint8List _jpeg(String filename) =>
      File('test/readme_screenshot_covers/$filename').readAsBytesSync();
}
