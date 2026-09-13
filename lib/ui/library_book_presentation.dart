import 'package:book_track/data_model.dart';
import 'package:ethan_utils/ethan_utils.dart';

/// UI copy derived from [LibraryBook]. The model only knows logged progress.
extension LibraryBookPresentation on LibraryBook {
  /// Product rule: a book "starts" when the first progress event is logged.
  DateTime? get startedOn => firstLoggedProgressAt;

  String get startedAndFinishedCaption {
    final DateTime? startedOn = this.startedOn;
    final DateTime? endedOn = readingEndedAt;
    if (startedOn == null) return endedOn?.monthDayCaption ?? '';
    if (endedOn == null) return startedOn.monthDayCaption;
    return '${startedOn.monthDayCaption} – ${endedOn.monthDayCaption}';
  }

  String get progressStatusCaption => switch (readingStatus) {
    ReadingStatus.finished => 'finished',
    ReadingStatus.abandoned => 'abandoned $progressPercentage%',
    ReadingStatus.reading => 'reading $progressPercentage%',
  };
}
