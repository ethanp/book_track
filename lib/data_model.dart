import 'dart:typed_data';

import 'package:book_track/extensions.dart';

class LibraryBook {
  LibraryBook(
    this.supaId,
    this.book,
    List<ProgressEvent> progressHistory,
    List<StatusEvent> statusHistory,
    this.bookFormat,
    this.bookLength,
    this.archived,
  )   : progressHistory = List.unmodifiable(progressHistory),
        statusHistory = List.unmodifiable(statusHistory);

  final int supaId;
  final Book book;
  final List<ProgressEvent> progressHistory;
  final List<StatusEvent> statusHistory;
  final BookFormat bookFormat;

  /// Only if [bookFormat] is [BookFormat.audiobook], then this represents the
  /// number of minutes in the audiobook.
  final int? bookLength;

  final bool archived;

  ProgressEventFormat get defaultProgressFormat => switch (bookFormat) {
        BookFormat.audiobook => ProgressEventFormat.minutes,
        _ => ProgressEventFormat.pageNum,
      };

  DateTime get startTime =>
      progressHistory.firstOrNull?.end ??
      DateTime.fromMillisecondsSinceEpoch(0);

  String get _suffix => isAudiobook ? 'h:m' : 'pgs';

  String? get currentBookProgressString {
    final progress =
        progressHistory.lastOrNull.map((ev) => bookProgressString(ev));
    final total = bookLength
        .map((length) => isAudiobook ? length.minsToHhMm : length.toString());
    return '$progress / $total';
  }

  String bookProgressString(ProgressEvent ev) =>
      _formatBookLengthString(ev.progress, ev.format);

  String get bookLengthStringWSuffix =>
      '${bookLengthString ?? 'unknown'} $_suffix';

  String? get bookLengthString => bookLength.map(_formatBookLengthString);

  String _formatBookLengthString(int length, [ProgressEventFormat? format]) {
    if (bookLength == null) {
      return format == ProgressEventFormat.minutes
          ? length.minsToHhMm
          : length.toString();
    }

    // When progress update was given in percentage,
    // still provide the length completed in terms of the actual book length.
    if (format == ProgressEventFormat.percent) {
      length = ((length / 100.0) * bookLength!).toInt();
    }

    return isAudiobook ? length.minsToHhMm : length.toString();
  }

  bool get isAudiobook => bookFormat == BookFormat.audiobook;

  ReadingStatus get readingStatus =>
      statusHistory.lastOrNull?.status ?? ReadingStatus.reading;

  int get progressPercentage {
    if (readingStatus == ReadingStatus.finished) return 100;
    if (progressHistory.lastOrNull == null) return 0;
    return intPercentProgressAt(progressHistory.last);
  }

  Iterable<MapEntry<DateTime, double>> get progressDiffs {
    return progressHistory.zipWithDiff(1, (prev, curr) {
      final double progressNow = percentProgressAt(curr)!;
      final double priorProgress = percentProgressAt(prev)!;
      final double progressDelta = progressNow - priorProgress;
      final DateTime progressTimestamp = curr.end;
      return MapEntry(progressTimestamp, progressDelta);
    });
  }

  Iterable<MapEntry<DateTime, double>> get pagesDiffs {
    if (bookFormat == BookFormat.audiobook) return [];
    if (bookLength == null) return [];

    return progressHistory.zipWithDiff(1, (prev, curr) {
      final double progressNow = pagesAt(curr);
      final double priorProgress = pagesAt(prev);
      final double progressDelta = progressNow - priorProgress;
      final DateTime progressTimestamp = curr.end;
      return MapEntry(progressTimestamp, progressDelta);
    });
  }

  Iterable<MapEntry<DateTime, double>> get fiveMinDiffs {
    if (bookFormat != BookFormat.audiobook) return [];
    if (bookLength == null) return [];

    return progressHistory.zipWithDiff(1, (prev, curr) {
      final double progressNow = minutesAt(curr);
      final double priorProgress = minutesAt(prev);
      final double progressDelta = progressNow - priorProgress;
      final DateTime progressTimestamp = curr.end;
      return MapEntry(progressTimestamp, progressDelta / 5);
    });
  }

  int intPercentProgressAt(ProgressEvent p) =>
      (percentProgressAt(p) ?? 0).floor();

  /// Eg. if the book is 50% complete, this method will return `50`.
  double? percentProgressAt(ProgressEvent p) {
    if (p.format == ProgressEventFormat.percent) return p.progress.toDouble();
    return bookLength.map((len) => 100.0 * p.progress / len);
  }

  int? parseLengthText(String text) {
    if (isAudiobook) {
      final int? hoursMins = _tryParseAudiobookLength(text);
      if (hoursMins != null) return hoursMins;
    }
    return int.tryParse(text);
  }

  static int? _tryParseAudiobookLength(String text) {
    final List<String> split = text.split(':');
    if (split.length < 2) return null;
    final int? hrs = int.tryParse(split[0]);
    final int? mins = int.tryParse(split[1]);
    if (hrs == null || mins == null) return null;
    return hrs * 60 + mins;
  }

  double pagesAt(ProgressEvent event) {
    if (bookLength == null) return 0;
    if (event.format == ProgressEventFormat.pageNum)
      return event.progress.toDouble();
    return event.progress / 100.0 * bookLength!;
  }

  double minutesAt(ProgressEvent event) {
    if (bookLength == null) return 0;
    if (event.format == ProgressEventFormat.minutes)
      return event.progress.toDouble();
    return event.progress / 100.0 * bookLength!;
  }
}

abstract class ReadingEvent {
  const ReadingEvent();

  DateTime get dateTime;

  int get dateTimeMillis => dateTime.millisecondsSinceEpoch;

  int get supaId;
}

class StatusEvent extends ReadingEvent {
  const StatusEvent({
    required this.supaId,
    required this.time,
    required this.status,
  });

  @override
  final int supaId;
  final DateTime time;
  final ReadingStatus status;

  @override
  DateTime get dateTime => time;

  @override
  String toString() => '{time: $time, status: $status}';
}

class ProgressEvent extends ReadingEvent {
  const ProgressEvent({
    required this.supaId,
    required this.end,
    required this.progress,
    required this.format,
    this.start,
  });

  @override
  final int supaId;
  final int progress;
  final DateTime? start;
  final DateTime end;
  final ProgressEventFormat format;

  @override
  DateTime get dateTime => end;

  @override
  String toString() =>
      '{progress: $progress, start: $start, end: $end, format: $format}';

  String get stringWSuffix => switch (format) {
        ProgressEventFormat.pageNum => '$progress pgs',
        ProgressEventFormat.percent => '$progress %',
        ProgressEventFormat.minutes =>
          '${progress.hours}:${progress.minutes} hh:mm',
      };
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
