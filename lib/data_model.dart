import 'dart:typed_data';

import 'package:book_track/extensions.dart';

class LibraryBook {
  const LibraryBook(
    this.supaId,
    this.book,
    this.startTime,
    this.progressHistory,
    this.statusHistory,
    this.bookFormat,
    this.bookLength,
  );

  final int supaId;
  final Book book;
  final DateTime startTime;
  final List<ProgressEvent> progressHistory;
  final List<StatusEvent> statusHistory;
  final BookFormat? bookFormat;
  final int? bookLength;

  String? get bookLengthPgs => bookLength.map((l) => '$l pgs');
}

class StatusEvent {
  const StatusEvent({required this.time, required this.status});

  final DateTime time;
  final ReadingStatus status;

  @override
  String toString() {
    return 'StatusEvent{time: $time, status: $status}';
  }
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

enum ReadingStatus {
  reading,
  abandoned,
  completed,
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
