import 'package:book_track/data_model.dart';
import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/sync/library_providers.dart';
import 'package:ethan_sync/ethan_sync.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'riverpods.g.dart';

@riverpod
class BookSearchResultsNotifier() extends _$BookSearchResultsNotifier {
  @override
  BookSearchResults build() => BookSearchResults.empty;

  void notify(BookSearchResults searchResult) => state = searchResult;
}

class const BookSearchResults({
  required final List<OpenLibraryBook> books,
  required final int fullResultCount,
  final bool isLoading = false,
  final Object? failure,
}) {
  static const BookSearchResults empty = BookSearchResults(
    books: [],
    fullResultCount: 0,
  );

  static const BookSearchResults loading = BookSearchResults(
    books: [],
    fullResultCount: 0,
    isLoading: true,
  );

  static BookSearchResults failed(Object? failure) =>
      BookSearchResults(books: [], fullResultCount: 0, failure: failure);
}

@riverpod
Future<List<LibraryBook>> userLibrary(Ref ref) async {
  ref.watch(localDataRevisionProvider);
  final libraryCatalog = await ref.watch(libraryCatalogProvider.future);
  return libraryCatalog.myBooks();
}
