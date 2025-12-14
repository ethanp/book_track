import 'dart:math' as math;

import 'package:book_track/data_model.dart';
import 'package:intl/intl.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/books_progress_chart/date_axis.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BooksProgressChart extends StatefulWidget {
  const BooksProgressChart({
    required this.books,
    this.periodCutoff,
    this.colorByFormat = false,
    super.key,
  });

  final List<LibraryBook> books;

  /// If provided, only show events after this date.
  final DateTime? periodCutoff;

  /// If true, color dots by which format was used for each event.
  final bool colorByFormat;

  @override
  State<BooksProgressChart> createState() => _BooksProgressChartState();
}

class _BooksProgressChartState extends State<BooksProgressChart> {
  /// Holds selected event info: (book, event, percent)
  (LibraryBook, ProgressEvent, double)? _selectedEvent;

  /// Holds selected spot indices for highlighting: (barIndex, spotIndex)
  (int, int)? _selectedSpotIndices;

  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  static final double horizontalInterval = 25;

  /// Get color for a format type (as decided in the plan).
  static Color colorForFormat(BookFormat? format) => switch (format) {
        BookFormat.audiobook => CupertinoColors.systemOrange,
        BookFormat.eBook => CupertinoColors.systemBlue,
        BookFormat.paperback => CupertinoColors.systemGreen,
        BookFormat.hardcover => CupertinoColors.systemIndigo,
        null => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    // Filter books to those with events in the period
    final filteredBooks = widget.periodCutoff == null
        ? widget.books
        : widget.books
            .where((b) => b.progressHistory
                .any((e) => e.end.isAfter(widget.periodCutoff!)))
            .toList();

    if (filteredBooks.isEmpty ||
        filteredBooks.every((b) => b.progressHistory.isEmpty)) {
      return const Center(
        child: Text('No reading data in this period'),
      );
    }

    final List<DateTime> eventTimes = filteredBooks
        .expand((b) => b.progressHistory)
        .where((e) =>
            widget.periodCutoff == null || e.end.isAfter(widget.periodCutoff!))
        .mapL((e) => e.end);

    if (eventTimes.isEmpty) {
      return const Center(
        child: Text('No reading data in this period'),
      );
    }

    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    return Column(
      children: [
        _buildSelectedEventInfo(),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              minX: timespan.beginning.millisSinceEpoch,
              maxX: timespan.end.millisSinceEpoch,
              gridData: grid(),
              titlesData: labelAxes(timespan),
              lineBarsData: _plotLines(filteredBooks),
              borderData: border(),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: false, // We handle selection ourselves
                touchSpotThreshold: 20,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => Colors.transparent,
                  tooltipPadding: EdgeInsets.zero,
                  tooltipMargin: 0,
                  getTooltipItems: (spots) => spots.map((_) => null).toList(),
                ),
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? response) {
                  if (event is FlTapUpEvent &&
                      response != null &&
                      response.lineBarSpots != null &&
                      response.lineBarSpots!.isNotEmpty) {
                    _handleSpotTap(
                        filteredBooks, response, event.localPosition, timespan);
                  }
                },
              ),
            ),
          ),
        ),
        if (widget.colorByFormat && _hasMultipleFormats(filteredBooks))
          _formatLegend(filteredBooks),
      ],
    );
  }

  void _handleSpotTap(List<LibraryBook> filteredBooks,
      LineTouchResponse response, Offset? touchPos, TimeSpan timespan) {
    // Find the closest spot to the touch position
    final spots = response.lineBarSpots!;
    LineBarSpot closestSpot = spots.first;

    if (touchPos != null && spots.length > 1) {
      // fl_chart returns spots with similar X values, so compare Y distance.
      // touchPos.dy is pixels from top; spot.y is percentage (0=bottom, 100=top)
      // Convert touch Y to percentage: top of chart = 100%, bottom = 0%
      // Assuming ~200px chart height after accounting for info bar
      const chartHeight = 200.0;
      final touchYPercent = 100.0 - (touchPos.dy / chartHeight * 100.0);

      double minDistance = double.infinity;
      for (final spot in spots) {
        final yDiff = (spot.y - touchYPercent).abs();
        if (yDiff < minDistance) {
          minDistance = yDiff;
          closestSpot = spot;
        }
      }
    }

    final barIndex = closestSpot.barIndex;
    final spotIndex = closestSpot.spotIndex;

    if (barIndex < 0 || barIndex >= filteredBooks.length) return;

    final book = filteredBooks[barIndex];
    final bookEvents = book.progressHistory
        .where((e) =>
            widget.periodCutoff == null || e.end.isAfter(widget.periodCutoff!))
        .toList();

    final filteredEvents = _filterToLastEventPerDay(book, bookEvents)
        .where((ev) => book.progressPercentAt(ev) != null)
        .toList();

    if (spotIndex < 0 || spotIndex >= filteredEvents.length) return;

    final event = filteredEvents[spotIndex];
    final percent = book.progressPercentAt(event) ?? 0;

    setState(() {
      _selectedEvent = (book, event, percent);
      _selectedSpotIndices = (barIndex, spotIndex);
    });
  }

  Widget _buildSelectedEventInfo() {
    if (_selectedEvent == null) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: Text(
            'Tap a point to see details',
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final (book, event, percent) = _selectedEvent!;
    final dateStr = DateFormat('MMM d, yyyy').format(event.end);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _bookCover(book, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              book.book.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percent.round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGreen,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bookCover(LibraryBook book, {double size = 60}) {
    final double height = size;
    final double width = size * 0.75;

    Widget bookArt = SizedBox(
      height: height,
      width: width,
      child: const Icon(CupertinoIcons.book,
          size: 30, color: CupertinoColors.systemGrey),
    );

    if (book.book.coverArtS != null) {
      final bool validCover = (book.book.coverArtS!.length >= 4 &&
          book.book.coverArtS![0] == 255 &&
          book.book.coverArtS![1] == 216 &&
          book.book.coverArtS![2] == 255 &&
          book.book.coverArtS![3] == 224);
      if (validCover) {
        bookArt = SizedBox(
          height: height,
          width: width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.memory(
              fit: BoxFit.cover,
              book.book.coverArtS!,
            ),
          ),
        );
      }
    }

    return Container(
      height: height,
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: bookArt,
    );
  }

  bool _hasMultipleFormats(List<LibraryBook> books) {
    final allFormats =
        books.expand((b) => b.formats).map((f) => f.format).toSet();
    return allFormats.length > 1;
  }

  Widget _formatLegend(List<LibraryBook> books) {
    final allFormats = books
        .expand((b) => b.formats)
        .map((f) => f.format)
        .toSet()
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: allFormats.mapL((format) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorForFormat(format),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    format.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  FlBorderData border() {
    final borderSide = BorderSide(color: Colors.black, width: 2);
    return FlBorderData(
      show: true,
      border: Border(
        left: borderSide,
        bottom: borderSide,
      ),
    );
  }

  FlGridData grid() {
    return FlGridData(
      horizontalInterval: horizontalInterval,
      drawVerticalLine: false,
    );
  }

  FlTitlesData labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: percentageAxisTitles(shiftTitle: Offset(20, -10)),
      rightTitles: noAxisTitles,
      bottomTitles: DateAxis(timespan).titles(),
      topTitles: noAxisTitles,
    );
  }

  List<LineChartBarData> _plotLines(List<LibraryBook> filteredBooks) {
    final allProgressEvents = filteredBooks
        .expand((b) => b.progressHistory)
        .where((e) =>
            widget.periodCutoff == null || e.end.isAfter(widget.periodCutoff!))
        .toList();

    if (allProgressEvents.isEmpty) return [];

    int firstDate = allProgressEvents.first.dateTime.millisecondsSinceEpoch;
    int lastDate = allProgressEvents.first.dateTime.millisecondsSinceEpoch;
    for (final b in allProgressEvents) {
      final t = b.dateTime.millisecondsSinceEpoch;
      firstDate = math.min(firstDate, t);
      lastDate = math.max(lastDate, t);
    }
    final double xRange = lastDate.toDouble() - firstDate;

    final result = <LineChartBarData>[];
    for (int barIndex = 0; barIndex < filteredBooks.length; barIndex++) {
      final book = filteredBooks[barIndex];
      final bookEvents = book.progressHistory
          .where((e) =>
              widget.periodCutoff == null ||
              e.end.isAfter(widget.periodCutoff!))
          .toList();

      // Filter to show only the last event per day to avoid vertical blips
      final filteredEvents = _filterToLastEventPerDay(book, bookEvents);

      result.add(LineChartBarData(
        spots: filteredEvents
            .where((ev) => book.progressPercentAt(ev) != null)
            .mapL((curr) => eventToSpot(book, curr)),
        isCurved: true,
        curveSmoothness: .05,
        belowBarData: gradientFill(),
        color: Colors.grey[700]!.withValues(alpha: .7),
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, xPercentage, bar, spotIndex) {
            // Check if this is the selected spot
            final isSelected = _selectedSpotIndices != null &&
                _selectedSpotIndices!.$1 == barIndex &&
                _selectedSpotIndices!.$2 == spotIndex;

            // Get the event at this index to determine format
            final event = filteredEvents[spotIndex];
            final format = book.formatById(event.formatId);

            // Calculate proper x percentage
            xPercentage = xRange > 0 ? (spot.x - firstDate) / xRange * 100 : 50;
            final double baseRadius = xPercentage / 100 / 1.2 + 2;
            final double radius = isSelected ? baseRadius + 3 : baseRadius;

            // Use format-based color if enabled
            final Color dotColor = widget.colorByFormat
                ? colorForFormat(format?.format)
                : Color.lerp(
                    Colors.blue.withValues(alpha: .7),
                    Colors.blueGrey.withValues(alpha: .8),
                    xPercentage / 100,
                  )!;

            return FlDotCirclePainter(
              radius: radius,
              color: isSelected ? CupertinoColors.systemRed : dotColor,
              strokeColor: isSelected ? Colors.white : Colors.black,
              strokeWidth: isSelected ? 2 : 0,
            );
          },
        ),
      ));
    }
    return result;
  }

  static BarAreaData gradientFill() {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [
          Colors.teal[400]!.withValues(alpha: .15),
          Colors.blue.withValues(alpha: .04)
        ],
        stops: [.4, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static AxisTitles percentageAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameWidget: FlutterHelpers.transform(
        shift: shiftTitle,
        child: Text(
          'Percentage',
          style: TextStyles.sideAxisLabel,
        ),
      ),
      sideTitles: SideTitles(
        interval: horizontalInterval,
        reservedSize: 30,
        showTitles: true,
        getTitlesWidget: (double value, TitleMeta meta) =>
            Text(value.floor().toString()),
      ),
      axisNameSize: 22,
    );
  }

  /// Filter events to show only the last event per day (by date, not time).
  /// This prevents vertical blips when multiple updates occur on the same day.
  List<ProgressEvent> _filterToLastEventPerDay(
    LibraryBook book,
    List<ProgressEvent> events,
  ) {
    if (events.isEmpty) return [];

    // Group events by date (normalized to midnight)
    final eventsByDate = <DateTime, ProgressEvent>{};

    for (final event in events) {
      final date = DateUtils.dateOnly(event.end);
      final existing = eventsByDate[date];

      // Keep the event with the highest progress for each day
      if (existing == null) {
        eventsByDate[date] = event;
      } else {
        final existingPercent = book.progressPercentAt(existing);
        final currentPercent = book.progressPercentAt(event);

        // If current event has higher progress, or if existing has no valid percent, use current
        if (currentPercent != null &&
            (existingPercent == null || currentPercent > existingPercent)) {
          eventsByDate[date] = event;
        } else if (existingPercent == null && currentPercent == null) {
          // If both are null, use the later one
          if (event.end.isAfter(existing.end)) {
            eventsByDate[date] = event;
          }
        }
      }
    }

    // Return events sorted by date
    final sortedDates = eventsByDate.keys.toList()..sort();
    return sortedDates.map((date) => eventsByDate[date]!).toList();
  }

  FlSpot eventToSpot(LibraryBook book, ProgressEvent ev) {
    return FlSpot(
      ev.end.millisecondsSinceEpoch.toDouble(),
      book.progressPercentAt(ev) ?? 0,
    );
  }
}
