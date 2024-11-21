import 'dart:typed_data';

import 'package:book_track/extensions.dart';

class LibraryBook {
  const LibraryBook(
    this.supaId,
    this.book,
    this.startTime,
    this.progressHistory,
    this.bookFormat,
    this.bookLength,
  );

  final int supaId;
  final Book book;
  final DateTime startTime;
  final ProgressHistory progressHistory;
  final BookFormat? bookFormat;
  final int? bookLength;

  String? get bookLengthPgs => bookLength.ifExists((l) => '$l pgs');
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
    this.openLibCoverId,
    this.coverArtS,
  );

  final int? supaId;
  final String title;
  final String? author;
  final int? yearFirstPublished;
  final int? openLibCoverId;
  final Uint8List? coverArtS;
}

enum BookFormat {
  audiobook,
  eBook,
  paperback,
  hardcover,
}

/// Special handling for no known book format
class RenderableFormat {
  const RenderableFormat(this.bookFormat);

  final BookFormat? bookFormat;

  @override
  String toString() => bookFormat?.name ?? 'not selected';

  @override
  bool operator ==(Object other) =>
      other is RenderableFormat && bookFormat == other.bookFormat;

  @override
  int get hashCode => bookFormat?.hashCode ?? 0;
}
