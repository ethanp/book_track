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

class const ReadingChartPoint({
  required final LibraryBook book,
  required final ProgressEvent event,
}) {
  @override
  bool operator ==(Object other) =>
      other is ReadingChartPoint &&
      other.book.supaId == book.supaId &&
      other.event.supaId == event.supaId;

  @override
  int get hashCode => Object.hash(book.supaId, event.supaId);
}

class _SelectedReadingEvent({
  required final LibraryBook book,
  required final ProgressEvent event,
  required final double percent,
  required final EChartSelectedPoint<ReadingChartPoint> chartPoint,
});

class _BookProgressLine({
  required final EChartSeries<ReadingChartPoint> trajectory,
  final EChartSeries<ReadingChartPoint>? eventDots,
  final EChartSeries<ReadingChartPoint>? paceProjection,
}) {
  List<EChartSeries<ReadingChartPoint>> get chartSeries {
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
          child: EChart<ReadingChartPoint>(
            series: [
              for (final progressLine in progressLines)
                ...progressLine.chartSeries,
            ],
            valueScale: EChartValueScale.fixed(
              min: 0,
              max: 100,
              ticks: const [0, 25, 50, 75, 100],
            ),
            start: timespan.beginning,
            end: timespan.end,
            selectedPoint: _selectedEvent?.chartPoint,
            onPointSelected: _showReadingEvent,
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

  void _showReadingEvent(EChartSelectedPoint<ReadingChartPoint>? selected) {
    if (selected == null) {
      _clearSelectedReadingEvent();
      return;
    }
    setState(() {
      _selectedEvent = _SelectedReadingEvent(
        book: selected.pointId.book,
        event: selected.pointId.event,
        percent:
            selected.pointId.book.progressPercentAt(selected.pointId.event) ??
            0,
        chartPoint: selected,
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
    final eventDots = _eventDotsSeries(book, eventPoints);
    return _BookProgressLine(
      trajectory: _trajectorySeries(book, events, eventPoints, eventDots),
      eventDots: eventDots,
      paceProjection: _paceProjectionSeries(book),
    );
  }

  DateTime? _projectedCompletion(List<LibraryBook> books) {
    if (!widget.showPaceProjection || books.length != 1) return null;
    return books.single.averageReadingPace?.eta;
  }

  List<EChartPoint<ReadingChartPoint>> _eventPoints(
    LibraryBook book,
    List<ProgressEvent> events,
    DateTime rangeStart,
    double spanMillis,
  ) => [
    for (final event in events)
      EChartPoint(
        date: event.end,
        value: book.progressPercentAt(event) ?? 0,
        id: ReadingChartPoint(book: book, event: event),
        color: widget.colorByFormat ? _dotColor(book, event) : null,
        dotRadius: widget.colorByFormat
            ? _dotRadius(event.end, rangeStart, spanMillis)
            : null,
      ),
  ];

  EChartSeries<ReadingChartPoint> _trajectorySeries(
    LibraryBook book,
    List<ProgressEvent> events,
    List<EChartPoint<ReadingChartPoint>> eventPoints,
    EChartSeries<ReadingChartPoint>? eventDots,
  ) {
    final points = widget.smoothProgress
        ? _smoothedTrajectoryPoints(book, events)
        : eventPoints;
    final interpolation = widget.smoothProgress || !widget.colorByFormat
        ? EChartInterpolation.alongIncreasingX
        : EChartInterpolation.polyline;
    if (widget.colorByFormat && !widget.smoothProgress) {
      return EChartSeries.lineAndDots(
        id: 'trajectory-${book.supaId}',
        points: points,
        interpolation: interpolation,
        color: _trajectoryColor(book),
        strokeWidth: _trajectoryWidth(book),
      );
    }
    return EChartSeries.line(
      id: 'trajectory-${book.supaId}',
      points: points,
      interpolation: interpolation,
      color: _trajectoryColor(book),
      strokeWidth: _trajectoryWidth(book),
      hits: eventDots == null
          ? EChartPointHits.include
          : EChartPointHits.ignore,
    );
  }

  EChartSeries<ReadingChartPoint>? _eventDotsSeries(
    LibraryBook book,
    List<EChartPoint<ReadingChartPoint>> eventPoints,
  ) {
    if (!widget.smoothProgress || !widget.colorByFormat) return null;
    if (eventPoints.isEmpty) return null;
    return EChartSeries.dots(id: 'events-${book.supaId}', points: eventPoints);
  }

  EChartSeries<ReadingChartPoint>? _paceProjectionSeries(LibraryBook book) {
    if (!widget.showPaceProjection) return null;
    final completionDate = book.averageReadingPace?.eta;
    final firstEvent = book.progressHistory.firstOrNull;
    if (completionDate == null || firstEvent == null) return null;
    final firstPercent = book.progressPercentAt(firstEvent);
    if (firstPercent == null || !completionDate.isAfter(firstEvent.end)) {
      return null;
    }
    final firstPoint = ReadingChartPoint(book: book, event: firstEvent);
    return EChartSeries.line(
      id: 'pace-${book.supaId}',
      points: [
        EChartPoint(date: firstEvent.end, value: firstPercent, id: firstPoint),
        EChartPoint(date: completionDate, value: 100, id: firstPoint),
      ],
      color: EColors.success,
      strokeWidth: 2.2,
      dash: EChartStrokeDash.dotted,
      hits: EChartPointHits.ignore,
    );
  }

  List<EChartPoint<ReadingChartPoint>> _smoothedTrajectoryPoints(
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
        EChartPoint(
          date: point.at,
          value: point.percent,
          id: ReadingChartPoint(
            book: book,
            event: _loggedEventNearest(events, point.at),
          ),
        ),
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

  ProgressEvent _loggedEventNearest(List<ProgressEvent> events, DateTime at) {
    return events.minBy(
      (candidate) => (candidate.end.difference(at).inMilliseconds).abs(),
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
