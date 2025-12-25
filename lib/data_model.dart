import 'dart:math';
import 'dart:typed_data';

import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/extensions.dart';

class LibraryBook {
  LibraryBook(
    this.supaId,
    this.book,
    List<ProgressEvent> progressHistory,
    this.formats,
    this.archived,
    this.abandonedAt,
  ) : progressHistory = List.unmodifiable(progressHistory);

  final int supaId;
  final Book book;
  final List<ProgressEvent> progressHistory;
  final DateTime? abandonedAt;

  /// All formats (editions) of this book the user owns.
  /// Sorted alphabetically by format name.
  final List<LibraryBookFormat> formats;

  final bool archived;

  /// Get format by ID.
  LibraryBookFormat? formatById(int formatId) =>
      formats.where((f) => f.supaId == formatId).firstOrNull;

  /// Primary format (first alphabetically, or first added).
  LibraryBookFormat? get primaryFormat => formats.firstOrNull;

  /// Check if this is primarily an audiobook (based on primary format).
  bool get isAudiobook => primaryFormat?.isAudiobook ?? false;

  /// Get the format used by a specific progress event.
  LibraryBookFormat? formatForEvent(ProgressEvent event) =>
      formatById(event.formatId);

  /// Default progress event format based on the primary book format.
  ProgressEventFormat get defaultProgressFormat =>
      primaryFormat?.isAudiobook == true
          ? ProgressEventFormat.minutes
          : ProgressEventFormat.pageNum;

  /// Get the last-used format (from most recent progress event).
  LibraryBookFormat? get lastUsedFormat {
    if (progressHistory.isEmpty) return primaryFormat;
    return formatById(progressHistory.last.formatId) ?? primaryFormat;
  }

  DateTime get startTime =>
      progressHistory.firstOrNull?.end ??
      DateTime.fromMillisecondsSinceEpoch(0);

  /// Calculate book progress percentage from an event.
  double? progressPercentAt(ProgressEvent event) {
    final format = formatById(event.formatId);
    if (format == null) return null;
    if (event.format == ProgressEventFormat.percent) {
      return event.progress.toDouble();
    }
    return format.progressToPercent(event.progress);
  }

  int intPercentProgressAt(ProgressEvent p) =>
      (progressPercentAt(p) ?? 0).floor();

  /// Overall book progress (max % across all events with known lengths).
  double? get overallProgressPercent {
    double? maxPercent;
    for (final event in progressHistory) {
      final percent = progressPercentAt(event);
      if (percent != null) {
        maxPercent = maxPercent == null ? percent : max(maxPercent, percent);
      }
    }
    return maxPercent;
  }

  int get progressPercentage => (overallProgressPercent ?? 0).floor();

  /// Get last event's percentage (for "continue from" calculation).
  double? get lastProgressPercent {
    if (progressHistory.isEmpty) return null;
    final lastEvent = progressHistory.last;
    return progressPercentAt(lastEvent);
  }

  /// Suggest starting position in a different format.
  int? suggestPositionIn(LibraryBookFormat targetFormat) {
    final percent = lastProgressPercent;
    if (percent == null) return null;
    return targetFormat.percentToProgress(percent);
  }

  /// Derives reading status from progress and abandonedAt field.
  ReadingStatus get readingStatus {
    if (abandonedAt != null) return ReadingStatus.abandoned;
    final percent = overallProgressPercent;
    if (percent != null && percent >= 100) return ReadingStatus.finished;
    return ReadingStatus.reading;
  }

  /// Get progress events for a specific format.
  List<ProgressEvent> progressForFormat(LibraryBookFormat format) =>
      progressHistory.where((e) => e.formatId == format.supaId).toList();

  /// Format the current book progress as a string.
  String? get currentBookProgressString {
    if (progressHistory.isEmpty || primaryFormat == null) return null;
    final lastEvent = progressHistory.last;
    final format = formatById(lastEvent.formatId);
    if (format == null) return null;

    final progressStr = bookProgressString(lastEvent);
    final totalStr = format.hasLength ? format.lengthDisplay : 'unknown';
    return '$progressStr / $totalStr';
  }

  String bookProgressString(ProgressEvent ev) {
    final format = formatById(ev.formatId);
    if (format == null) return '${ev.progress}';

    if (ev.format == ProgressEventFormat.percent && format.hasLength) {
      final actualProgress = (ev.progress / 100.0 * format.length!).toInt();
      return format.isAudiobook
          ? actualProgress.minsToHhMm
          : actualProgress.toString();
    }

    return format.isAudiobook ? ev.progress.minsToHhMm : ev.progress.toString();
  }

  String get bookLengthStringWSuffix {
    final format = primaryFormat;
    if (format == null || !format.hasLength) return 'unknown';
    final suffix = format.isAudiobook ? 'h:m' : 'pgs';
    return '${format.lengthDisplay} $suffix';
  }

  int? parseLengthText(String text) {
    if (primaryFormat?.isAudiobook == true) {
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

  /// At each progress event, how many pages/minutes were read; sorted by date.
  /// Handles format switches by converting via percentage.
  Iterable<MapEntry<DateTime, double>> pagesDiffs({bool percentage = false}) {
    if (formats.isEmpty) return [];
    return progressHistory.zipWithDiff(1, (prev, curr) {
      double value;
      if (percentage) {
        final prevPercent = progressPercentAt(prev) ?? 0;
        final currPercent = progressPercentAt(curr) ?? 0;
        value = currPercent - prevPercent;
      } else {
        final currFormat = formatById(curr.formatId);
        if (currFormat == null || !currFormat.hasLength) {
          return MapEntry(curr.end, 0.0);
        }

        // Convert both events to percentages, then calculate delta in current format's units
        final prevPercent = progressPercentAt(prev);
        final currPercent = progressPercentAt(curr);

        if (prevPercent == null || currPercent == null) {
          return MapEntry(curr.end, 0.0);
        }

        // Calculate delta as percentage change
        final percentDelta = currPercent - prevPercent;

        // Clamp to non-negative (progress shouldn't go backwards)
        if (percentDelta < 0) {
          return MapEntry(curr.end, 0.0);
        }

        // Convert percentage delta to current format's units
        if (currFormat.isAudiobook) {
          // Convert percentage to minutes
          value = (percentDelta / 100.0) * currFormat.length!;
        } else {
          // Convert percentage to pages
          value = (percentDelta / 100.0) * currFormat.length!;
        }
      }
      return MapEntry(curr.end, value);
    });
  }

  double pagesAt(ProgressEvent event) {
    final format = formatById(event.formatId);
    if (format == null || !format.hasLength) return 0;
    if (event.format == ProgressEventFormat.pageNum) {
      return event.progress.toDouble();
    }
    if (event.format == ProgressEventFormat.percent) {
      return event.progress / 100.0 * format.length!;
    }
    // Minutes to pages doesn't make sense, return 0
    return 0;
  }

  double minutesAt(ProgressEvent event) {
    final format = formatById(event.formatId);
    if (format == null || !format.hasLength) return 0;
    if (event.format == ProgressEventFormat.minutes) {
      return event.progress.toDouble();
    }
    if (event.format == ProgressEventFormat.percent) {
      return event.progress / 100.0 * format.length!;
    }
    // Pages to minutes doesn't make sense, return 0
    return 0;
  }
}

class ProgressEvent {
  const ProgressEvent({
    required this.supaId,
    required this.formatId,
    required this.end,
    required this.progress,
    required this.format,
    this.start,
  });

  final int supaId;

  /// FK to LibraryBookFormat - identifies which format this progress was logged in.
  final int formatId;

  final int progress;
  final DateTime? start;
  final DateTime end;

  /// How the progress value should be interpreted (pages, minutes, or percent).
  final ProgressEventFormat format;

  DateTime get dateTime => end;

  int get dateTimeMillis => dateTime.millisecondsSinceEpoch;

  @override
  String toString() =>
      '{progress: $progress, formatId: $formatId, start: $start, end: $end, format: $format}';

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
