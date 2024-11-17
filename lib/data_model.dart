import 'dart:typed_data';

class BookProgress {
  BookProgress(
    this.book,
    this.startTime,
    this.progressHistory,
  );

  final Book book;
  final DateTime startTime;
  final ProgressHistory progressHistory;
}

class ProgressHistory {
  ProgressHistory(this.progressEvents);

  final List<ProgressEvent> progressEvents;
}

class ProgressEvent {
  ProgressEvent(
    this.dateTime,
    this.progress,
  );

  final DateTime dateTime;
  final int progress;
}

class Book {
  Book(
    this.title,
    this.author,
    this.yearFirstPublished,
    this.bookType,
    this.bookLength,
    this.coverArtS,
    this.coverArtM,
    this.coverArtL,
  );

  final String title;
  final String? author;
  final int? yearFirstPublished;
  final BookType? bookType;
  final int? bookLength;
  final Uint8List? coverArtS;
  final Uint8List? coverArtM;
  final Uint8List? coverArtL;

  String? get bookLengthPgs => bookLength == null ? null : '$bookLength pgs';
}

enum BookType {
  audiobook,
  eBook,
  paperback,
  hardcover,
}
