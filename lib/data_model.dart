import 'dart:typed_data';

class BookProgress {
  BookProgress(
    this.book,
    this.percentComplete,
    this.startTime,
    this.progressHistory,
  );

  final Book book;
  final double percentComplete;
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
    this.yearPublished,
    this.bookType,
    this.bookLength,
    this.coverArt,
  );

  final String title;
  final String author;
  final int yearPublished;
  final BookType bookType;
  final int bookLength;
  final ByteData? coverArt;
}

enum BookType {
  audiobook,
  eBook,
  paperback,
  hardcover,
}
