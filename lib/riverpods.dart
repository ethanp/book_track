import 'package:book_track/data_model.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/services/supabase_library_service.dart';
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
class BookSearchResultsNotifier extends _$BookSearchResults {
  @override
  BookSearchResults build() => BookSearchResults.empty;

  void notify(BookSearchResults searchResult) => state = searchResult;
}

class BookSearchResults {
  const BookSearchResults({
    required this.books,
    required this.fullResultCount,
    this.isLoading = false,
    this.failure,
  });

  final bool isLoading;
  final Object? failure;
  final List<OpenLibraryBook> books;
  final int fullResultCount;

  static const BookSearchResults empty =
      BookSearchResults(books: [], fullResultCount: 0);

  static const BookSearchResults loading =
      BookSearchResults(books: [], fullResultCount: 0, isLoading: true);

  static BookSearchResults failed(Object? failure) =>
      BookSearchResults(books: [], fullResultCount: 0, failure: failure);
}

@riverpod
Future<List<LibraryBook>> userLibrary(Ref ref) async =>
    await SupabaseLibraryService.myBooks();
