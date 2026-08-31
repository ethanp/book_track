import 'package:intl/intl.dart';

extension ProgressEventDateCaption on DateTime {
  String get slashMonthDayYear =>
      _ProgressEventDateFormats.slashMonthDayYear.format(this);

  String get hourMinuteAmPm =>
      _ProgressEventDateFormats.hourMinuteAmPm.format(this);

  String get slashMonthDayYearAtTime =>
      _ProgressEventDateFormats.slashMonthDayYearAtTime.format(this);
}

abstract final class _ProgressEventDateFormats() {
  static final slashMonthDayYear = DateFormat('MM/dd/yy');
  static final hourMinuteAmPm = DateFormat('h:mma');
  static final slashMonthDayYearAtTime = DateFormat('MM/dd/yy h:mma');
}
