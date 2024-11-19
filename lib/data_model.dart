import 'dart:typed_data';

import 'package:book_track/extensions.dart';

class BookProgress {
  const BookProgress(
    this.book,
    this.startTime,
    this.progressHistory,
  );

  final Book book;
  final DateTime startTime;
  final ProgressHistory progressHistory;
}

class ProgressHistory {
  const ProgressHistory(this.progressEvents);

  final List<ProgressEvent> progressEvents;
}

class ProgressEvent {
  const ProgressEvent({
    required this.end,
    required this.progress,
    required this.format,
    this.start,
  });

  final int progress;
  final DateTime? start;
  final DateTime end;
  final ProgressEventFormat format;
}

enum ProgressEventFormat {
  pageNum,
  percent,
  minutes;

  static final map = {for (final v in ProgressEventFormat.values) v.name: v};
}

class Book {
  const Book(
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
