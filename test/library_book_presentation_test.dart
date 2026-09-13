import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/ui/library_book_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LibraryBook progress times', () {
    test(
      'firstLoggedProgressAt is the first event time, not a started flag',
      () {
        final book = _book(
          events: [
            _event(id: 1, at: DateTime(2026, 3, 2), progress: 10),
            _event(id: 2, at: DateTime(2026, 4, 8), progress: 40),
          ],
        );

        expect(book.firstLoggedProgressAt, DateTime(2026, 3, 2));
        expect(book.lastLoggedProgressAt, DateTime(2026, 4, 8));
        expect(book.startedOn, book.firstLoggedProgressAt);
        expect(book.readingEndedAt, isNull);
      },
    );

    test('readingEndedAt is the last log when the book is finished', () {
      final book = _book(
        events: [
          _event(id: 1, at: DateTime(2026, 1, 1), progress: 10),
          _event(id: 2, at: DateTime(2026, 2, 1), progress: 100),
        ],
      );

      expect(book.isFinished, isTrue);
      expect(book.readingEndedAt, DateTime(2026, 2, 1));
    });

    test('readingEndedAt is abandonedAt when abandoned', () {
      final abandonedAt = DateTime(2026, 5, 1);
      final book = _book(
        abandonedAt: abandonedAt,
        events: [_event(id: 1, at: DateTime(2026, 3, 2), progress: 47)],
      );

      expect(book.isAbandoned, isTrue);
      expect(book.readingEndedAt, abandonedAt);
    });
  });

  group('LibraryBookPresentation', () {
    test('formats a first-log to ended date range', () {
      final book = _book(
        events: [
          _event(id: 1, at: DateTime(2026, 3, 2), progress: 10),
          _event(id: 2, at: DateTime(2026, 4, 8), progress: 100),
        ],
      );

      expect(book.startedAndFinishedCaption, contains('–'));
      expect(book.progressStatusCaption, 'finished');
    });

    test('abandoned caption includes percent', () {
      final book = _book(
        abandonedAt: DateTime(2026, 5, 1),
        events: [_event(id: 1, at: DateTime(2026, 3, 2), progress: 47)],
      );

      expect(book.progressStatusCaption, 'abandoned 47%');
    });

    test('reading caption includes percent', () {
      final book = _book(
        events: [_event(id: 1, at: DateTime(2026, 3, 2), progress: 20)],
      );

      expect(book.progressStatusCaption, 'reading 20%');
    });
  });
}

LibraryBook _book({
  List<ProgressEvent> events = const [],
  DateTime? abandonedAt,
}) {
  return LibraryBook(
    1,
    const Book(1, 'Title', 'Author', 2020, null, null),
    events,
    const [
      LibraryBookFormat(
        supaId: 9,
        libraryBookId: 1,
        format: BookFormat.paperback,
        length: 100,
      ),
    ],
    false,
    abandonedAt,
  );
}

ProgressEvent _event({
  required int id,
  required DateTime at,
  required int progress,
}) {
  return ProgressEvent(
    supaId: id,
    formatId: 9,
    end: at,
    progress: progress,
    format: ProgressEventFormat.pageNum,
  );
}
