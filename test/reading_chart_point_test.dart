import 'package:book_track/data_model.dart';
import 'package:book_track/data_model/library_book_format.dart';
import 'package:book_track/ui/common/books_progress_chart/books_progress_chart.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReadingChartPoint equality is by book and event ids', () {
    final book = _book();
    final event = _event(id: 4);
    final first = ReadingChartPoint(book: book, event: event);
    final rebuilt = ReadingChartPoint(book: _book(), event: _event(id: 4));

    expect(first, rebuilt);
    expect(
      EChartSelectedPoint(
        seriesId: 'events-1',
        pointId: first,
        date: event.end,
        value: 10,
      ),
      EChartSelectedPoint(
        seriesId: 'events-1',
        pointId: rebuilt,
        date: event.end,
        value: 10,
      ),
    );
  });
}

LibraryBook _book() {
  return LibraryBook(
    1,
    const Book(1, 'Title', 'Author', 2020, null, null),
    const [],
    const [
      LibraryBookFormat(
        supaId: 9,
        libraryBookId: 1,
        format: BookFormat.paperback,
        length: 100,
      ),
    ],
    false,
    null,
  );
}

ProgressEvent _event({required int id}) {
  return ProgressEvent(
    supaId: id,
    formatId: 9,
    end: DateTime(2026, 3, 2),
    progress: 10,
    format: ProgressEventFormat.pageNum,
  );
}
