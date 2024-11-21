import 'package:book_track/data_model.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/services/supabase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'riverpods.g.dart';

/// During development, it is important to get the generators going via
/// `dart run build_runner watch` as recommended on the riverpod
/// getting-started docs: https://riverpod.dev/docs/introduction/getting_started.

/// Annotating a class by `@riverpod` defines shared state
/// accessible via `<className>Provider`.
///
/// This class is both responsible for initializing the state
/// (through the [build] method) and exposing ways to modify it (cf [update]).
@riverpod
class SelectedBottomBarIdx extends _$SelectedBottomBarIdx {
  /// Classes annotated by `@riverpod` **must** define a [build] function,
  /// which returns the initial state.
  ///
  /// It is acceptable to return a [Future] or [Stream] if you need to instead.
  ///
  /// You can also freely define parameters on this method.
  @override
  int build() => 0;

  void update(int idx) => state = idx;
}

// Why keepAlive? To keep the session alive even if all listeners have been
// disposed off-screen.
@Riverpod(keepAlive: true)
class SessionStartTime extends _$SessionStartTime {
  @override
  DateTime? build() => null;

  void start() => state = DateTime.now();
  void stop() => state = null;
  void toggle() => state == null ? start() : stop();
}

@riverpod
class BookSearchResults extends _$BookSearchResults {
  @override
  BookSearchResult? build() => BookSearchResult.empty;

  void update(BookSearchResult? searchResult) => state = searchResult;
}

class BookSearchResult {
  const BookSearchResult({
    required this.books,
    required this.fullResultCount,
  });

  final List<OpenLibraryBook> books;
  final int fullResultCount;

  static BookSearchResult get empty =>
      BookSearchResult(books: [], fullResultCount: 0);
}

@riverpod
Future<List<LibraryBook>> userLibrary(Ref ref) async {
  final results = await SupabaseLibraryService.myBooks();
  print('fetched ${results.length} books in library');
  return results;
}
