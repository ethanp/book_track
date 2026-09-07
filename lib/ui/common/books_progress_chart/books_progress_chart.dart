import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:book_track/ui/common/books_progress_chart/smoothed_book_progress.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:book_track/ui/pages/library_book/library_book_page.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class const BooksProgressChart({
  required final List<LibraryBook> books,
  final DateTime? periodCutoff,
  final bool colorByFormat = false,
  final bool showSelectedBookCard = true,
  final bool smoothProgress = false,
  final bool showPaceProjection = false,
}) extends StatefulWidget {
  static const selectionSlotHeight = 64.0;
  static const plotHeight = 300.0;
  static const height = selectionSlotHeight + plotHeight;

  @override
  State<BooksProgressChart> createState() => _BooksProgressChartState();
}

class _SelectedReadingEvent({
  required final LibraryBook book,
  required final ProgressEvent event,
  required final double percent,
  required final EChartSelectedPoint chartPoint,
});

class _BookProgressLine({
  required final LibraryBook book,
  required final List<ProgressEvent> events,
  required final EChartLine trajectory,
  final EChartLine? eventDots,
  final EChartLine? paceProjection,
}) {
  List<EChartLine> get chartLines {
    final dots = eventDots;
    final projection = paceProjection;
    return [
      trajectory,
      if (dots != null) dots,
      if (projection != null) projection,
    ];
  }
}

class _BooksProgressChartState() extends State<BooksProgressChart> {
  _SelectedReadingEvent? _selectedEvent;

  @override
  Widget build(BuildContext context) {
    final filteredBooks = widget.periodCutoff == null
        ? widget.books
        : widget.books
              .where(
                (book) => book.progressHistory.any(
                  (event) => event.end.isAfter(widget.periodCutoff!),
                ),
              )
              .toList();

    if (filteredBooks.isEmpty ||
        filteredBooks.every((book) => !book.hasProgress)) {
      return const Center(child: Text('No reading data in this period'));
    }

    final eventTimes = filteredBooks
        .expand((book) => book.progressHistory)
        .where(
          (event) =>
              widget.periodCutoff == null ||
              event.end.isAfter(widget.periodCutoff!),
        )
        .mapL((event) => event.end);

    if (eventTimes.isEmpty) {
      return const Center(child: Text('No reading data in this period'));
    }

    final projectedCompletion = _projectedCompletion(filteredBooks);
    final chartEnd =
        projectedCompletion != null &&
            projectedCompletion.isAfter(eventTimes.max)
        ? projectedCompletion
        : eventTimes.max;
    final timespan = TimeSpan(beginning: eventTimes.min, end: chartEnd);
    final progressLines = _progressLines(filteredBooks, timespan);

    return Column(
      children: [
        if (widget.showSelectedBookCard)
          SizedBox(
            height: BooksProgressChart.selectionSlotHeight,
            child: _selectedEvent == null ? null : _selectedEventCard(),
          ),
        Expanded(
          child: EChart(
            lines: [
              for (final progressLine in progressLines)
                ...progressLine.chartLines,
            ],
            valueScale: EChartValueScale.fixed(
              min: 0,
              max: 100,
              ticks: const [0, 25, 50, 75, 100],
            ),
            start: timespan.beginning,
            end: timespan.end,
            selectedPoint: _selectedEvent?.chartPoint,
            onPointSelected: (selected) =>
                _showReadingEvent(progressLines, selected),
          ),
        ),
        if (widget.colorByFormat && _hasMultipleFormats(filteredBooks))
          _formatLegend(filteredBooks),
      ],
    );
  }

  void _clearSelectedReadingEvent() {
    if (_selectedEvent == null) return;
    setState(() => _selectedEvent = null);
  }

  void _showReadingEvent(
    List<_BookProgressLine> progressLines,
    EChartSelectedPoint? selected,
  ) {
    if (selected == null) {
      _clearSelectedReadingEvent();
      return;
    }
    final progressLine = progressLines
        .where((line) => line.chartLines.contains(selected.line))
        .firstOrNull;
    if (progressLine == null || progressLine.events.isEmpty) return;
    final event = progressLine.events.minBy(
      (candidate) =>
          (candidate.end.difference(selected.point.date).inMilliseconds).abs(),
    );
    final dotsLine = progressLine.eventDots ?? progressLine.trajectory;
    final pointIndex = progressLine.events.indexOf(event);
    if (pointIndex < 0 || pointIndex >= dotsLine.points.length) return;
    final allLines = [for (final line in progressLines) ...line.chartLines];
    setState(() {
      _selectedEvent = _SelectedReadingEvent(
        book: progressLine.book,
        event: event,
        percent: progressLine.book.progressPercentAt(event) ?? 0,
        chartPoint: EChartSelectedPoint(
          line: dotsLine,
          point: dotsLine.points[pointIndex],
          lineIndex: allLines.indexOf(dotsLine),
          pointIndex: pointIndex,
        ),
      );
    });
  }

  List<_BookProgressLine> _progressLines(
    List<LibraryBook> filteredBooks,
    TimeSpan timespan,
  ) {
    final spanMillis = timespan.end
        .difference(timespan.beginning)
        .inMilliseconds
        .toDouble();
    return [
          for (final book in filteredBooks)
            _lineForBook(book, timespan.beginning, spanMillis),
        ]
        .where((progressLine) => progressLine.trajectory.points.isNotEmpty)
        .toList();
  }

  _BookProgressLine _lineForBook(
    LibraryBook book,
    DateTime rangeStart,
    double spanMillis,
  ) {
    final bookEvents = book.progressHistory
        .where(
          (event) =>
              widget.periodCutoff == null ||
              event.end.isAfter(widget.periodCutoff!),
        )
        .toList();
    final events = _highestProgressPerDay(
      book,
      bookEvents,
    ).where((event) => book.progressPercentAt(event) != null).toList();
    final eventPoints = _eventPoints(book, events, rangeStart, spanMillis);
    return _BookProgressLine(
      book: book,
      events: events,
      trajectory: _trajectoryLine(book, events, eventPoints),
      eventDots: _eventDotsLine(eventPoints),
      paceProjection: _paceProjectionLine(book),
    );
  }

  DateTime? _projectedCompletion(List<LibraryBook> books) {
    if (!widget.showPaceProjection || books.length != 1) return null;
    return books.single.averageReadingPace?.eta;
  }

  List<EChartPoint> _eventPoints(
    LibraryBook book,
    List<ProgressEvent> events,
    DateTime rangeStart,
    double spanMillis,
  ) => [
    for (final event in events)
      EChartPoint(
        date: event.end,
        value: book.progressPercentAt(event) ?? 0,
        color: widget.colorByFormat ? _dotColor(book, event) : null,
        dotRadius: widget.colorByFormat
            ? _dotRadius(event.end, rangeStart, spanMillis)
            : null,
      ),
  ];

  EChartLine _trajectoryLine(
    LibraryBook book,
    List<ProgressEvent> events,
    List<EChartPoint> eventPoints,
  ) {
    return EChartLine(
      points: widget.smoothProgress
          ? _smoothedTrajectoryPoints(book, events)
          : eventPoints,
      showDots: widget.colorByFormat && !widget.smoothProgress,
      stroke: widget.smoothProgress || !widget.colorByFormat
          ? EChartLineStroke.alongIncreasingX
          : EChartLineStroke.polyline,
      color: _trajectoryColor(book),
      strokeWidth: _trajectoryWidth(book),
    );
  }

  EChartLine? _eventDotsLine(List<EChartPoint> eventPoints) {
    if (!widget.smoothProgress || !widget.colorByFormat) return null;
    if (eventPoints.isEmpty) return null;
    return EChartLine(points: eventPoints, showDots: true, showStroke: false);
  }

  EChartLine? _paceProjectionLine(LibraryBook book) {
    if (!widget.showPaceProjection) return null;
    final completionDate = book.averageReadingPace?.eta;
    final firstEvent = book.progressHistory.firstOrNull;
    if (completionDate == null || firstEvent == null) return null;
    final firstPercent = book.progressPercentAt(firstEvent);
    if (firstPercent == null || !completionDate.isAfter(firstEvent.end)) {
      return null;
    }
    return EChartLine(
      points: [
        EChartPoint(date: firstEvent.end, value: firstPercent),
        EChartPoint(date: completionDate, value: 100),
      ],
      color: EColors.success,
      strokeWidth: 2.2,
      showDots: false,
      pattern: EChartLinePattern.dotted,
      isInteractive: false,
    );
  }

  List<EChartPoint> _smoothedTrajectoryPoints(
    LibraryBook book,
    List<ProgressEvent> events,
  ) {
    final smoothed = SmoothedBookProgress.fromLoggedPercents([
      for (final event in events)
        BookProgressPoint(
          at: event.end,
          percent: book.progressPercentAt(event) ?? 0,
        ),
    ]);
    return [
      for (final point in smoothed.points)
        EChartPoint(date: point.at, value: point.percent),
    ];
  }

  Color _trajectoryColor(LibraryBook book) {
    if (widget.colorByFormat) return EColors.textSecondary;
    final isSelected = _selectedEvent?.book.supaId == book.supaId;
    if (isSelected) return EColors.textSecondary;
    return EColors.textMuted.withValues(alpha: 0.55);
  }

  double _trajectoryWidth(LibraryBook book) {
    if (widget.colorByFormat) return 2.6;
    final isSelected = _selectedEvent?.book.supaId == book.supaId;
    return isSelected ? 2.2 : 1.4;
  }

  Color _dotColor(LibraryBook book, ProgressEvent event) {
    if (widget.colorByFormat) {
      return book.formatById(event.formatId)?.format.color ?? EColors.textMuted;
    }
    final percent = book.progressPercentAt(event) ?? 0;
    return EHeatmapIntensity.colorAt((percent / 100).clamp(0.0, 1.0));
  }

  double _dotRadius(DateTime date, DateTime rangeStart, double spanMillis) {
    final alongRange = spanMillis > 0
        ? date.difference(rangeStart).inMilliseconds / spanMillis
        : 0.5;
    return alongRange / 1.2 + 2;
  }

  Widget _selectedEventCard() {
    if (_selectedEvent == null) return const SizedBox.shrink();
    final selected = _selectedEvent!;
    final dateStr = DateFormat('MMM d, yyyy').format(selected.event.end);

    return Material(
      color: EColors.background.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        onTap: () => context.push(LibraryBookPage(selected.book.supaId)),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              _bookCover(selected.book, size: 40),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  selected.book.book.title,
                  style: AppTextStyles.h5,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${selected.percent.round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: EHeatmapIntensity.colorAt(selected.percent / 100),
                    ),
                  ),
                  Text(dateStr, style: AppTextStyles.caption),
                ],
              ),
              IconButton(
                tooltip: 'Clear selection',
                onPressed: _clearSelectedReadingEvent,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookCover(LibraryBook book, {double size = 60}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BookCover(
        width: size * 0.75,
        height: size,
        bytes: book.book.coverArt,
      ),
    );
  }

  bool _hasMultipleFormats(List<LibraryBook> books) {
    return books
            .expand((book) => book.formats)
            .map((format) => format.format)
            .toSet()
            .length >
        1;
  }

  Widget _formatLegend(List<LibraryBook> books) {
    final allFormats =
        books
            .expand((book) => book.formats)
            .map((format) => format.format)
            .toSet()
            .toList()
          ..sortOn((format) => format.name);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: allFormats.mapL(
          (format) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: format.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(format.name, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<ProgressEvent> _highestProgressPerDay(
    LibraryBook book,
    List<ProgressEvent> events,
  ) {
    if (events.isEmpty) return [];
    final eventsByDate = <DateTime, ProgressEvent>{};
    for (final event in events) {
      final date = event.end.startOfDay;
      final existing = eventsByDate[date];
      if (existing == null) {
        eventsByDate[date] = event;
        continue;
      }
      final existingPercent = book.progressPercentAt(existing);
      final currentPercent = book.progressPercentAt(event);
      if (currentPercent != null &&
          (existingPercent == null || currentPercent > existingPercent)) {
        eventsByDate[date] = event;
      } else if (existingPercent == null && currentPercent == null) {
        if (event.end.isAfter(existing.end)) {
          eventsByDate[date] = event;
        }
      }
    }
    final sortedDates = eventsByDate.keys.toList()..sort();
    return sortedDates.mapL((date) => eventsByDate[date]!);
  }
}
