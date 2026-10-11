import 'package:book_track/ui/common/design.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';

class const DayOfWeekChart({required final Map<int, double> activityByDay})
    extends StatelessWidget {
  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const double barWidth = 30.0;
  static const double maxBarHeight = 120.0;
  static const double labelBlockHeight = 42.0;

  @override
  Widget build(BuildContext context) {
    final maxValue = activityByDay.values.isEmpty
        ? 1.0
        : activityByDay.values.max;

    return SizedBox(
      height: maxBarHeight + labelBlockHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final weekday = index + 1;
          final dayValue = activityByDay[weekday] ?? 0;
          return _dayBar(dayNames[index], dayValue, maxValue);
        }),
      ),
    );
  }

  Widget _dayBar(String day, double dayValue, double maxValue) {
    final fraction = maxValue > 0 ? dayValue / maxValue : 0.0;
    final barHeight = maxBarHeight * fraction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: barWidth,
          height: barHeight > 0 ? barHeight : 0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                EColors.success.withValues(alpha: 0.4),
                EColors.success.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
              bottom: Radius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(day, style: AppTextStyles.caption.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          '${dayValue.round()}%',
          style: AppTextStyles.caption.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
