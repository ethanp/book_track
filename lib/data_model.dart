import 'dart:typed_data';

import 'package:book_track/extensions.dart';

class LibraryBook {
  const LibraryBook(
    this.supaId,
    this.book,
    this.progressHistory,
    this.statusHistory,
    this.bookFormat,
    this.bookLength,
  );

  final int supaId;
  final Book book;
  final List<ProgressEvent> progressHistory;
  final List<StatusEvent> statusHistory;
  final BookFormat? bookFormat;

  /// Only if [bookFormat] is [BookFormat.audiobook], then this represents the
  /// number of minutes in the audiobook.
  final int? bookLength;

  DateTime get startTime => progressHistory.first.end;

  String? get bookLengthPgs => bookLength.map((l) => '$l pgs');

  ReadingStatus get status =>
      statusHistory.lastOrNull?.status ?? ReadingStatus.reading;

  double? get progressPercentage {
    if (status == ReadingStatus.completed) return 100;
    if (progressHistory.lastOrNull == null) return null;
    final latestProgress = progressHistory.last;
    final double progress = latestProgress.progress.toDouble();
    if (latestProgress.format == ProgressEventFormat.percent) return progress;
    return bookLength.map((length) => progress / length);
  }

  double? progressAt(ProgressEvent p) {
    final double progress = p.progress.toDouble();
    if (p.format == ProgressEventFormat.percent) return progress;
    return bookLength.map((length) => progress / length);
  }
}

abstract class ReadingEvent {
  const ReadingEvent();
  int get sortKey;
}

class StatusEvent extends ReadingEvent {
  const StatusEvent({required this.time, required this.status});

  final DateTime time;
  final ReadingStatus status;

  @override
  int get sortKey => time.millisecondsSinceEpoch;

  @override
  String toString() => '{time: $time, status: $status}';
}

class ProgressEvent extends ReadingEvent {
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

  @override
  int get sortKey => end.millisecondsSinceEpoch;

  @override
  String toString() =>
      '{progress: $progress, start: $start, end: $end, format: $format}';
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
