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
    this.format,
  );

  final DateTime dateTime;
  final int progress;
  final ProgressEventFormat format;
}

enum ProgressEventFormat {
  pageNum,
  percent,
  minutes;

  static final map = {for (final v in ProgressEventFormat.values) v.name: v};
}

class Book {
  Book(
    this.supaId,
    this.title,
    this.author,
    this.yearFirstPublished,
    this.bookType,
    this.bookLength,
    this.openLibCoverId,
    this.coverArtS,
  );

  final int? supaId;
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
