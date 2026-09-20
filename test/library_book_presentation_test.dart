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

  group('LibraryBook progressSincePrevious', () {
    test('audiobook logs use hours:minutes and session deltas', () {
      final book = _audiobook(
        events: [
          _audioEvent(
            id: 'start',
            at: DateTime(2026, 9, 16, 23, 36),
            progress: 0,
            format: ProgressEventFormat.percent,
          ),
          _audioEvent(
            id: 'thirty',
            at: DateTime(2026, 9, 17, 22, 32),
            progress: 30,
          ),
          _audioEvent(
            id: 'one-thirty',
            at: DateTime(2026, 9, 18, 19, 58),
            progress: 130,
          ),
        ],
      );

      final ProgressSincePrevious? start = book.progressSincePrevious(
        book.progressHistory[0],
      );
      final ProgressSincePrevious? thirty = book.progressSincePrevious(
        book.progressHistory[1],
      );
      final ProgressSincePrevious? oneThirty = book.progressSincePrevious(
        book.progressHistory[2],
      );

      expect(book.bookProgressString(book.progressHistory[1]), '0:30');
      expect(book.bookProgressString(book.progressHistory[2]), '2:10');
      expect(start?.isZero, isTrue);
      expect(thirty?.plusCaption, '+0:30 +7%');
      expect(oneThirty?.plusCaption, '+1:40 +26%');
    });

    test('print logs use page deltas', () {
      final book = _book(
        events: [
          _event(id: 1, at: DateTime(2026, 9, 16), progress: 0),
          _event(id: 2, at: DateTime(2026, 9, 17), progress: 20),
          _event(id: 3, at: DateTime(2026, 9, 18), progress: 47),
        ],
      );

      expect(
        book.progressSincePrevious(book.progressHistory[0])?.isZero,
        isTrue,
      );
      expect(
        book.progressSincePrevious(book.progressHistory[1])?.plusCaption,
        '+20 pgs +20%',
      );
      expect(
        book.progressSincePrevious(book.progressHistory[2])?.plusCaption,
        '+27 pgs +27%',
      );
      expect(
        book.progressSincePrevious(book.progressHistory[2])?.plusUnitsCaption,
        '+27 pgs',
      );
      expect(
        book.progressSincePrevious(book.progressHistory[2])?.plusPercentCaption,
        '+27%',
      );
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
    '1',
    const Book('1', 'Title', 'Author', 2020, null, null),
    events,
    const [
      LibraryBookFormat(
        id: '9',
        libraryBookId: '1',
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
    id: '$id',
    formatId: '9',
    end: at,
    progress: progress,
    format: ProgressEventFormat.pageNum,
  );
}

LibraryBook _audiobook({required List<ProgressEvent> events}) {
  return LibraryBook(
    '1',
    const Book('1', 'Title', 'Author', 2020, null, null),
    events,
    const [
      LibraryBookFormat(
        id: 'audio',
        libraryBookId: '1',
        format: BookFormat.audiobook,
        length: 390,
      ),
    ],
    false,
    null,
  );
}

ProgressEvent _audioEvent({
  required String id,
  required DateTime at,
  required int progress,
  ProgressEventFormat format = ProgressEventFormat.minutes,
}) {
  return ProgressEvent(
    id: id,
    formatId: 'audio',
    end: at,
    progress: progress,
    format: format,
  );
}
