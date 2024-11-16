import 'dart:convert';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:http/http.dart' as http;

class BookUniverseService {
  // static final bookUniverseRepo = StaticBookUniverseRepository();
  static final bookUniverseRepo = OpenLibraryBookUniverseRepository();

  static Future<void> search(
      String containing, BookSearchResults results) async {
    if (containing.isEmpty) {
      return results.update(BookSearchResult([]));
    }
    results.update(null);
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

/// One decent book api option is https://hardcover.app/account/api?referrer_id=15017
/// The other decent one I've found is https://openlibrary.org/dev/docs/api/books
///    Nice thing about this one is it doesn't require any authentication.
///    I'm starting with this one for now.
/// Google would probably work fine too https://developers.google.com/books/docs/v1/using
class OpenLibraryBookUniverseRepository implements BookUniverseRepository {
  final Uri apiUrl = Uri.parse('https://openlibrary.org/search.json');

  @override
  Future<List<Book>> search(String containing) async {
    final Uri url = apiUrl.replace(queryParameters: {'q': safe(containing)});
    print('apiUrl: $url');
    final http.Response response = await http.get(url);
    if (response.statusCode != 200) {
      print('search error: $response');
      return [];
    }
    final dynamic bodyJson = jsonDecode(response.body);
    final results = bodyJson['docs'] as List<dynamic>;
    return results.mapL(
      (resultDoc) {
        List? authorName = resultDoc['author_name'];
        return Book(
          resultDoc['title'],
          authorName == null ? null : authorName[0],
          resultDoc['first_publish_year'],
          null,
          resultDoc['number_of_pages_median'],
          null,
        );
      },
    );
  }

  String safe(String str) => str.replaceAll(r'\S', '+');
}
