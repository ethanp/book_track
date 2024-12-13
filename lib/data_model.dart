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
    this.archived,
  );

  final int supaId;
  final Book book;
  final List<ProgressEvent> progressHistory;
  final List<StatusEvent> statusHistory;
  final BookFormat? bookFormat;

  /// Only if [bookFormat] is [BookFormat.audiobook], then this represents the
  /// number of minutes in the audiobook.
  final int? bookLength;

  final bool archived;

  ProgressEventFormat get defaultProgressFormat => switch (bookFormat) {
        null => ProgressEventFormat.percent,
        BookFormat.audiobook => ProgressEventFormat.minutes,
        _ => ProgressEventFormat.pageNum,
      };

  DateTime get startTime => progressHistory.first.end;

  String get _suffix => switch (bookFormat) {
        null => '(unknown format)',
        BookFormat.audiobook => 'hrs:mins',
        _ => 'pgs'
      };

  String bookProgressString(ProgressEvent ev) =>
      '${_format(ev.progress)} $_suffix';

  String get bookLengthString => '${bookLengthCount ?? 'unknown'} $_suffix';

  String? get bookLengthCount => bookLength.map(_format);

  String _format(int length) => bookFormat == BookFormat.audiobook
      ? length.minsToHhMm
      : length.toString();

  ReadingStatus get readingStatus =>
      statusHistory.lastOrNull?.status ?? ReadingStatus.reading;

  int? get progressPercentage {
    if (readingStatus == ReadingStatus.finished) return 100;
    if (progressHistory.lastOrNull == null) return null;
    return intPercentProgressAt(progressHistory.last);
  }

  int? intPercentProgressAt(ProgressEvent p) => percentProgressAt(p)?.floor();

  /// Eg. if the book is 50% complete, this method will return `50`.
  double? percentProgressAt(ProgressEvent p) {
    if (p.format == ProgressEventFormat.percent) return p.progress.toDouble();
    return bookLength.map((len) => 100.0 * p.progress / len);
  }

  int? parseLengthText(String text) {
    if (bookFormat == BookFormat.audiobook) {
      final int? hoursMins = _tryParseAudiobookLength(text);
      if (hoursMins != null) return hoursMins;
    }
    return int.tryParse(text);
  }

  static int? _tryParseAudiobookLength(String text) {
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
  finished,
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
