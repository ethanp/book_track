import 'dart:convert';
import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/extensions.dart';
import 'package:book_track/riverpods.dart';
import 'package:http/http.dart' as http;

class BookUniverseService {
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

  static Future<Uint8List?> downloadMedSizeCover(Book book) =>
      bookUniverseRepo.coverBytes(book.openLibCoverId, 'M');
}

/// One decent book api option is https://hardcover.app/account/api?referrer_id=15017
/// The other decent one I've found is https://openlibrary.org/dev/docs/api/books
///    Nice thing about this one is it doesn't require any authentication.
///    I'm starting with this one for now.
/// Google would probably work fine too https://developers.google.com/books/docs/v1/using
class OpenLibraryBookUniverseRepository {
  static final Uri apiUrl = Uri.parse('https://openlibrary.org/search.json');

  static Uri coverUrl(int coverId, String size) =>
      Uri.parse('https://covers.openlibrary.org/b/id/$coverId-$size.jpg');

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
      results.map(
        (openLibBookDoc) async {
          final List? authorNames = openLibBookDoc['author_name'];
          return Book(
            null,
            openLibBookDoc['title'],
            authorNames.ifExists((n) => n.first),
            openLibBookDoc['first_publish_year'],
            null,
            openLibBookDoc['number_of_pages_median'],
            openLibBookDoc['cover_i'],
            await coverBytes(openLibBookDoc['cover_i'], 'S'),
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
