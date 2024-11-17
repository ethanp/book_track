import 'dart:typed_data';

import 'package:book_track/extensions.dart';

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
    this.openLibCoverId,
    this.coverArtS,
  );

  final String title;
  final String? author;
  final int? yearFirstPublished;
  final BookType? bookType;
  final int? bookLength;
  final int? openLibCoverId;
  final Uint8List? coverArtS;

  String? get bookLengthPgs => bookLength.ifExists((l) => '$l pgs');
}

enum BookType {
  audiobook,
  eBook,
  paperback,
  hardcover,
}
