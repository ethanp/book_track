import 'dart:math' show max;

import 'package:ethan_utils/ethan_utils.dart';

import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:flutter/material.dart';

/// Progress made on a single book for a specific day.
class const DayProgressEntry({
  required final LibraryBook book,
  required final double percentDelta,
  required final double unitsDelta,
  required final bool isAudiobook,

  /// Book was added to reading list on this day but no progress made.
  final bool opened = false,

  /// Book was started on this day (first progress made).
  final bool started = false,
  final bool finished = false,
  final bool abandoned = false,
}) {
  String get progressLabel {
    final unitsStr = isAudiobook
        ? unitsDelta.round().minsToHhMm
        : '${unitsDelta.round()} pgs';
    return '+${percentDelta.round()}% · $unitsStr';
  }

  String? get statusLabel {
    if (started && finished) return 'Started & Finished';
    if (started) return 'Started';
    if (opened) return 'Opened';
    if (finished) return 'Finished';
    if (abandoned) return 'Abandoned';
    return null;
  }

  Widget buildTile(BuildContext context) {
    final status = statusLabel;
    return GestureDetector(
      onTap: () => context.push(LibraryBookPage(book.supaId)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            _bookCover(),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.book.title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: abandoned
                            ? AppColors.audiobook
                            : AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              progressLabel,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookCover() {
    return BookCover(
      width: 22.5,
      height: 30,
      bytes: book.book.coverArt,
      borderRadius: 3,
    );
  }

  /// Build tiles for all books with progress on a given date.
  static List<Widget> tilesForDate(
    DateTime date,
    List<LibraryBook> books,
    BuildContext context,
  ) => books
      .map((book) => DayProgressEntry.forBook(book, date)?.buildTile(context))
      .nonNulls
      .toList();

  /// Calculate progress entry for a single book on a given date.
  /// Returns null if no activity on that day.
  static DayProgressEntry? forBook(LibraryBook book, DateTime date) {
    final normalizedDate = date.startOfDay;
    final sorted = book.progressHistory.toList()
      ..sort((a, b) => a.end.compareTo(b.end));

    double totalPercentDelta = 0;
    double totalUnitsDelta = 0;
    bool? isAudiobook;
    bool isFirstEvent = false;
    bool finished = false;

    for (int i = 0; i < sorted.length; i++) {
      final event = sorted[i];
      if (!event.end.sameDayAs(normalizedDate)) continue;

      final format = book.formatById(event.formatId);
      if (format == null || !format.hasLength) continue;

      isAudiobook ??= format.isAudiobook;
      final currPercent = book.progressPercentAt(event) ?? 0;
      final prevPercent = i > 0
          ? (book.progressPercentAt(sorted[i - 1]) ?? 0)
          : 0.0;
      final percentDelta = max(0, currPercent - prevPercent);

      totalPercentDelta += percentDelta;
      totalUnitsDelta += (percentDelta / 100.0) * format.length!;

      if (i == 0) isFirstEvent = true;
      if (currPercent >= 100) finished = true;
    }

    final abandoned = book.abandonedAt?.sameDayAs(normalizedDate) == true;

    // opened = first event but no progress; started = first event with progress
    final opened = isFirstEvent && totalPercentDelta <= 0;
    final started = isFirstEvent && totalPercentDelta > 0;

    if (totalPercentDelta <= 0 && !abandoned && !isFirstEvent) return null;

    return DayProgressEntry(
      book: book,
      percentDelta: totalPercentDelta,
      unitsDelta: totalUnitsDelta,
      isAudiobook: isAudiobook ?? book.isAudiobook,
      opened: opened,
      started: started,
      finished: finished,
      abandoned: abandoned,
    );
  }
}
