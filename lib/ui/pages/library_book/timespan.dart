class TimeSpan {
  TimeSpan({
    required this.beginning,
    required this.end,
  }) : duration = beginning.difference(end);

  final DateTime beginning;
  final DateTime end;
  final Duration duration;
}
