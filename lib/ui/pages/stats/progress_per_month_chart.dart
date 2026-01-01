import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/helpers.dart';
import 'package:book_track/ui/common/books_progress_chart/timespan.dart';
import 'package:book_track/ui/common/design.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressPerMonthChart extends StatelessWidget {
  ProgressPerMonthChart({
    required this.books,
    this.periodCutoff,
    super.key,
  })  : totalByMonth = _progressByMonth(
          books,
          periodCutoff,
          'Total',
          CupertinoColors.systemGreen,
        ),
        audiobookByMonth = _progressByMonth(
          books.where((b) => b.isAudiobook).toList(),
          periodCutoff,
          'Audio',
          CupertinoColors.systemOrange,
        ),
        visualByMonth = _progressByMonth(
          books.where((b) => !b.isAudiobook).toList(),
          periodCutoff,
          'Visual',
          CupertinoColors.systemBlue,
        );

  final List<LibraryBook> books;
  final DateTime? periodCutoff;

  final ProgressLine totalByMonth;
  final ProgressLine audiobookByMonth;
  final ProgressLine visualByMonth;

  List<ProgressLine> get lines =>
      [totalByMonth, audiobookByMonth, visualByMonth];

  static final yyyyMM = DateFormat('yyyy-MM');

  static ProgressLine _progressByMonth(
    List<LibraryBook> books,
    DateTime? periodCutoff,
    String name,
    Color color,
  ) {
    final byMonth = <String, double>{};

    for (final book in books) {
      for (final diff in book.progressDiffs) {
        if (periodCutoff != null && diff.key.isBefore(periodCutoff)) continue;
        final key = yyyyMM.format(diff.key);
        if (diff.value > 0) {
          byMonth[key] = (byMonth[key] ?? 0) + diff.value;
        }
      }
    }

    return ProgressLine(
      data: byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
      name: name,
      color: color,
    );
  }

  static const noAxisTitles =
      AxisTitles(sideTitles: SideTitles(showTitles: false));
  static const double horizontalInterval = 100;

  @override
  Widget build(BuildContext context) {
    if (totalByMonth.data.isEmpty) {
      return const Center(child: Text('No reading data in this period'));
    }
    return Stack(children: [
      lineChart(),
      chartLegend(),
    ]);
  }

  Widget lineChart() {
    final eventTimes =
        lines.expand((l) => l.data).mapL((e) => yyyyMM.parse(e.key));
    final timespan = TimeSpan(beginning: eventTimes.min, end: eventTimes.max);
    final maxY = lines.expand((l) => l.data).map((e) => e.value).max;
    const borderSide = BorderSide(color: CupertinoColors.black, width: 2);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        minX: timespan.beginning.millisSinceEpoch,
        maxX: timespan.end.millisSinceEpoch,
        gridData: FlGridData(
          horizontalInterval: horizontalInterval,
          drawVerticalLine: false,
        ),
        titlesData: labelAxes(timespan),
        lineTouchData: touchData,
        lineBarsData: lines.mapL(_buildLine),
        borderData: FlBorderData(
          show: true,
          border: const Border(left: borderSide, bottom: borderSide),
        ),
      ),
    );
  }

  LineChartBarData _buildLine(ProgressLine line) {
    final now = DateTime.now();
    final currMonth = yyyyMM.format(now);

    return LineChartBarData(
      spots: line.data.mapL((monthVal) {
        final dateAsMillis = yyyyMM.parse(monthVal.key).millisecondsSinceEpoch;
        final isCurrMonth = monthVal.key == currMonth;
        return FlSpot(
          dateAsMillis.toDouble(),
          isCurrMonth ? _scaleEstimate(monthVal.value, now) : monthVal.value,
        );
      }),
      isCurved: true,
      curveSmoothness: .05,
      belowBarData:
          line == totalByMonth ? gradientFill() : BarAreaData(show: false),
      color: line.color.withOpacity(0.7),
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, xPercentage, bar, index) => FlDotCirclePainter(
          radius: 2,
          color: line.color.withOpacity(0.8),
          strokeColor: CupertinoColors.black,
        ),
      ),
    );
  }

  LineTouchData get touchData => LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) {
            if (spots.isEmpty) return [];
            final date =
                DateTime.fromMillisecondsSinceEpoch(spots.first.x.toInt());
            final monthStr = DateFormat('MMM yyyy').format(date);
            return spots.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              final spot = entry.value;
              final line = lines[spot.barIndex];
              final lineColor =
                  Color.lerp(line.color, CupertinoColors.white, 0.5)!;
              final prefix = isFirst ? '$monthStr\n' : '';
              return LineTooltipItem(
                prefix,
                const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: '${line.name}: ${spot.y.round()}%',
                    style: TextStyle(color: lineColor),
                  ),
                ],
              );
            }).toList();
          },
        ),
      );

  Widget chartLegend() {
    return Positioned(
      top: 0,
      right: 0,
      child: Card(
        elevation: 2,
        color: Colors.yellow[100]!.withValues(alpha: .7),
        shadowColor: Colors.green[100]!.withValues(alpha: .5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines.mapL((l) => _legendItem(l.color, l.name)),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              color: color,
              margin: const EdgeInsets.only(right: 6)),
          Text(label, style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  double _scaleEstimate(double x, DateTime now) =>
      x / now.day * monthLength(now.month, now.year);

  static FlTitlesData labelAxes(TimeSpan timespan) {
    return FlTitlesData(
      leftTitles: progressAxisTitles(shiftTitle: const Offset(20, -10)),
      rightTitles: noAxisTitles,
      bottomTitles: _MonthAxis(timespan).titles(),
      topTitles: noAxisTitles,
    );
  }

  static BarAreaData gradientFill() {
    return BarAreaData(
      show: true,
      gradient: LinearGradient(
        colors: [
          CupertinoColors.systemGreen.withOpacity(0.15),
          CupertinoColors.systemGreen.withOpacity(0.04),
        ],
        stops: const [.4, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    );
  }

  static AxisTitles progressAxisTitles({required Offset shiftTitle}) {
    return AxisTitles(
      axisNameSize: 20,
      axisNameWidget: Transform.translate(
        offset: shiftTitle,
        child: Text('Progress %', style: TextStyles.sideAxisLabel),
      ),
      sideTitles: SideTitles(
        interval: horizontalInterval,
        reservedSize: 26,
        showTitles: true,
        maxIncluded: false,
        getTitlesWidget: (double value, TitleMeta meta) => Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Text(
            '${value.floor()}',
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.right,
          ),
        ),
      ),
    );
  }

  static num monthLength(int month, int year) => month == 2
      ? year % 4 == 0
          ? 29
          : 28
      : {9, 4, 6, 11}.contains(month)
          ? 30
          : 31;
}

class ProgressLine {
  const ProgressLine({
    required this.data,
    required this.name,
    required this.color,
  });

  final List<MapEntry<String, double>> data;
  final String name;
  final Color color;
}

class _MonthAxis {
  const _MonthAxis(this.timespan);

  final TimeSpan timespan;

  AxisTitles titles() {
    return AxisTitles(
      axisNameWidget: monthAxisName(),
      sideTitles: monthTextLabels(),
      axisNameSize: 24,
    );
  }

  Widget monthAxisName() {
    return FlutterHelpers.transform(
      shift: const Offset(20, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Month', style: TextStyles.sideAxisLabel),
          Padding(
            padding: const EdgeInsets.only(top: 1, left: 10),
            child: Text(
              'Starting ${TimeHelpers.monthDayYear(timespan.beginning)}',
              style: TextStyles.sideAxisLabelThin,
            ),
          ),
        ],
      ),
    );
  }

  SideTitles monthTextLabels() {
    return SideTitles(
      showTitles: true,
      minIncluded: false,
      maxIncluded: true,
      reservedSize: 26,
      interval: const Duration(days: 1).inMilliseconds.toDouble(),
      getTitlesWidget: (double value, TitleMeta c) {
        if (DateTime.fromMillisecondsSinceEpoch(value.toInt()).day == 1) {
          return FlutterHelpers.transform(
            shift: const Offset(2, 2),
            angleDegrees: 40,
            child: dateText(value),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget dateText(double value) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(value.toInt());
    if (dateTime.month == 1) {
      return Text(
        DateFormat('MMM yy').format(dateTime),
        style: const TextStyle(letterSpacing: -.4, fontSize: 10),
      );
    } else {
      return Text(
        DateFormat('MMM').format(dateTime),
        style: const TextStyle(letterSpacing: -.4, fontSize: 10),
      );
    }
  }
}
