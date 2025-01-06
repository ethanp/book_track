class TimeSpan {
  TimeSpan({
    required this.beginning,
    required this.end,
  }) : duration = end.difference(beginning);

  final DateTime beginning;
  final DateTime end;
  final Duration duration;
}
