// One decent book api option is https://hardcover.app/account/api?referrer_id=15017
// The other decent one I've found is https://openlibrary.org/dev/docs/api/books
//    Nice thing about this one is it doesn't require any authentication
// Google would probably work fine too https://developers.google.com/books/docs/v1/using
import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';

class BookUniverseService {
  static final bookUniverseRepo = StaticBookUniverseRepository();

  static Future<void> search(
      String containing, BookSearchResults results) async {
    if (containing.isEmpty) {
      return results.update(BookSearchResult([]));
    }
    List<Book> books = await bookUniverseRepo.search(containing);
    results.update(BookSearchResult(books));
  }
}

abstract class BookUniverseRepository {
  Future<List<Book>> search(String containing);
}

class StaticBookUniverseRepository implements BookUniverseRepository {
  @override
  Future<List<Book>> search(String containing) async {
    return [
      Book('A chicken', 'Donald Duck', 1954, BookType.hardcover, 125, null),
      Book('Why buildings fall', 'Tony Archy Text', 1978, BookType.hardcover,
          225, null),
    ];
  }
}
