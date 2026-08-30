class TimeSpan({
  required final DateTime beginning,
  required final DateTime end,
}) {
  final Duration duration = end.difference(beginning);
}
