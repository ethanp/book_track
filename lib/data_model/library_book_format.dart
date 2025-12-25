import 'dart:math';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';

/// Represents a specific format (edition) of a book in the user's library.
/// A LibraryBook can have multiple formats (e.g., hardcover + audiobook).
class LibraryBookFormat {
  const LibraryBookFormat({
    required this.supaId,
    required this.libraryBookId,
    required this.format,
    this.length,
  });

  final int supaId;
  final int libraryBookId;
  final BookFormat format;

  /// Length in pages (physical/ebook) or minutes (audiobook).
  /// Null if user hasn't set it yet.
  final int? length;

  bool get isAudiobook => format == BookFormat.audiobook;

  bool get hasLength => length != null && length! > 0;

  /// Convert raw progress value to percentage (null if length unknown).
  double? progressToPercent(int rawProgress) {
    if (!hasLength) return null;
    return (rawProgress / length! * 100).clamp(0.0, 100.0);
  }

  /// Convert percentage to raw progress in this format's units.
  int percentToProgress(double percent) {
    if (!hasLength) return 0;
    return (percent / 100 * length!).round();
  }

  String get unitLabel => isAudiobook ? 'minutes' : 'pages';

  String get lengthDisplay {
    if (!hasLength) return 'Set length';
    return isAudiobook ? length!.minsToHhMm : '$length pages';
  }

  /// Compare by format name for alphabetical sorting.
  int compareTo(LibraryBookFormat other) =>
      format.name.compareTo(other.format.name);

  @override
  String toString() =>
      'LibraryBookFormat(id: $supaId, format: ${format.name}, length: $length)';
}
