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

  String get bookLengthString {
    final String suffix = switch (bookFormat) {
      null => '(unknown format)',
      BookFormat.audiobook => 'hrs:mins',
      _ => 'pgs'
    };
    return '${bookLengthCount ?? 'unknown'} $suffix';
  }

  String? get bookLengthCount => bookLength.map((a) => switch (bookFormat) {
        BookFormat.audiobook => '${(a / 60).floor()}:${a % 60}',
        _ => a.toString()
      });

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

  /// Eg. if the book is 50% complete, this method will return `50`.
  double? percentProgressAt(ProgressEvent p) {
    final double progress = p.progress.toDouble();
    if (p.format == ProgressEventFormat.percent) return progress;
    return bookLength.map((length) => 100 * progress / length);
  }

  int? parseLengthText(String text) => switch (bookFormat) {
        BookFormat.audiobook => tryParseAudiobookLength(text),
        _ => int.tryParse(text),
      };

  static int? tryParseAudiobookLength(String text) {
    final List<String> split = text.split(':');
    final int? hrs = int.tryParse(split[0]);
    final int? mins = int.tryParse(split[1]);
    if (hrs == null || mins == null) return null;
    return hrs * 60 + mins;
  }
}

abstract class ReadingEvent {
  const ReadingEvent();

  DateTime get dateTime;

  int get dateTimeMillis => dateTime.millisecondsSinceEpoch;
}

class StatusEvent extends ReadingEvent {
  const StatusEvent({required this.time, required this.status});

  final DateTime time;
  final ReadingStatus status;

  @override
  DateTime get dateTime => time;

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
  DateTime get dateTime => end;

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
