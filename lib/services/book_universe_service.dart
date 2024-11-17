import 'dart:convert';
import 'dart:typed_data';

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

  static Future<Uint8List?> getCoverArtSizeM(Book book) =>
      bookUniverseRepo.coverBytes(book.openLibCoverId, 'M');
}

abstract class BookUniverseRepository {
  Future<List<Book>> search(String containing);
}

class StaticBookUniverseRepository implements BookUniverseRepository {
  @override
  Future<List<Book>> search(String containing) async {
    return [
      Book('A chicken', 'Donald Duck', 1954, BookType.hardcover, 125, null,
          null),
      Book('Why buildings fall', 'Tony Archy Text', 1978, BookType.hardcover,
          225, null, null),
    ];
  }
}

/// One decent book api option is https://hardcover.app/account/api?referrer_id=15017
/// The other decent one I've found is https://openlibrary.org/dev/docs/api/books
///    Nice thing about this one is it doesn't require any authentication.
///    I'm starting with this one for now.
/// Google would probably work fine too https://developers.google.com/books/docs/v1/using
class OpenLibraryBookUniverseRepository implements BookUniverseRepository {
  static final Uri apiUrl = Uri.parse('https://openlibrary.org/search.json');

  static Uri coverUrl(int coverId, String size) =>
      Uri.parse('https://covers.openlibrary.org/b/id/$coverId-$size.jpg');

  @override
  Future<List<Book>> search(String containing) async {
    String safe(String str) => str.replaceAll(r'\S', '+');
    final Uri url = apiUrl.replace(queryParameters: {
      'q': safe(containing),
      'limit': '10',
    });
    print('apiUrl: $url');
    final http.Response response = await http.get(url);
    if (response.statusCode != 200) {
      print('search error: $response');
      return [];
    }
    final dynamic bodyJson = jsonDecode(response.body);
    final results = bodyJson['docs'] as List<dynamic>;
    return Future.wait(
      results.mapL(
        (resultDoc) async {
          final List? authorNames = resultDoc['author_name'];
          return Book(
            resultDoc['title'],
            authorNames == null ? null : authorNames[0],
            resultDoc['first_publish_year'],
            null,
            resultDoc['number_of_pages_median'],
            resultDoc['cover_i'],
            await coverBytes(resultDoc['cover_i'], 'S'),
          );
        },
      ),
    );
  }

  Future<Uint8List?> coverBytes(int? coverId, String size) async {
    if (coverId == null) return null;
    final http.Response response = await http.get(coverUrl(coverId, size));
    return response.bodyBytes;
  }
}
