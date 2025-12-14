import 'dart:math' as math;

import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
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
  LineTouchResponse? _touchedSpot;
  Offset? _touchPosition;

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
    return GestureDetector(
      onTapDown: (details) {
        // Store tap position for tooltip placement
        setState(() {
          _touchPosition = details.localPosition;
        });
      },
      onTapUp: (_) {
        // Don't dismiss on tap up - let the chart's touch callback handle it
      },
      child: Stack(
        children: [
          Column(
            children: [
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
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem('', const TextStyle());
                          }).toList();
                        },
                      ),
                      touchCallback:
                          (FlTouchEvent event, LineTouchResponse? response) {
                        if (event is FlTapUpEvent) {
                          // Keep tooltip visible on tap up if there's a valid response
                          if (response != null &&
                              response.lineBarSpots != null &&
                              response.lineBarSpots!.isNotEmpty) {
                            setState(() {
                              _touchedSpot = response;
                            });
                          } else {
                            // Dismiss if tapping empty area
                            setState(() {
                              _touchedSpot = null;
                              _touchPosition = null;
                            });
                          }
                        } else if (response != null &&
                            response.lineBarSpots != null &&
                            response.lineBarSpots!.isNotEmpty) {
                          // Show tooltip on touch down
                          setState(() {
                            _touchedSpot = response;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              if (widget.colorByFormat && _hasMultipleFormats(filteredBooks))
                _formatLegend(filteredBooks),
            ],
          ),
          if (_touchedSpot != null &&
              _touchedSpot!.lineBarSpots != null &&
              _touchedSpot!.lineBarSpots!.isNotEmpty &&
              _touchPosition != null)
            _buildTooltip(context, filteredBooks, _touchedSpot!) ??
                const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget? _buildTooltip(BuildContext context, List<LibraryBook> filteredBooks,
      LineTouchResponse response) {
    if (response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
      return null;
    }

    final spot = response.lineBarSpots!.first;
    final barIndex = spot.barIndex;
    final spotIndex = spot.spotIndex;

    if (barIndex < 0 || barIndex >= filteredBooks.length) {
      return null;
    }

    final book = filteredBooks[barIndex];
    final bookEvents = book.progressHistory
        .where((e) =>
            widget.periodCutoff == null || e.end.isAfter(widget.periodCutoff!))
        .where((ev) => book.progressPercentAt(ev) != null)
        .toList();

    if (spotIndex < 0 || spotIndex >= bookEvents.length) {
      return null;
    }

    final event = bookEvents[spotIndex];
    final percent = book.progressPercentAt(event) ?? 0;

    // Position tooltip near the touch point
    if (_touchPosition == null) return null;
    return Positioned(
      left: _touchPosition!.dx - 120, // Offset to center tooltip
      top: _touchPosition!.dy - 100, // Offset above touch point
      child: GestureDetector(
        onTap: () => setState(() => _touchedSpot = null),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bookCover(book),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percent.round()}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.systemGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookCover(LibraryBook book) {
    final double height = 60;
    final double width = 45;

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

    return filteredBooks.mapL(
      (LibraryBook book) {
        final bookEvents = book.progressHistory
            .where((e) =>
                widget.periodCutoff == null ||
                e.end.isAfter(widget.periodCutoff!))
            .toList();
        return LineChartBarData(
          spots: bookEvents
              .where((ev) => book.progressPercentAt(ev) != null)
              .mapL((curr) => eventToSpot(book, curr)),
          isCurved: true,
          curveSmoothness: .05,
          belowBarData: gradientFill(),
          color: Colors.grey[700]!.withValues(alpha: .7),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, xPercentage, bar, index) {
              // Get the event at this index to determine format
              final event = bookEvents[index];
              final format = book.formatById(event.formatId);

              // Calculate proper x percentage
              xPercentage =
                  xRange > 0 ? (spot.x - firstDate) / xRange * 100 : 50;
              final double radius = xPercentage / 100 / 1.2 + 2;

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
                color: dotColor,
                strokeColor: Colors.black,
              );
            },
          ),
        );
      },
    );
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

  FlSpot eventToSpot(LibraryBook book, ProgressEvent ev) {
    return FlSpot(
      ev.end.millisecondsSinceEpoch.toDouble(),
      book.progressPercentAt(ev) ?? 0,
    );
  }
}
