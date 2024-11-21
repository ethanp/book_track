import 'dart:convert';
import 'dart:typed_data';

import 'package:book_track/riverpods.dart';
import 'package:http/http.dart' as http;

class BookUniverseService {
  static final bookUniverseRepo = OpenLibraryBookUniverseRepository();

  static Future<void> search(
      String containing, BookSearchResults results) async {
    if (containing.isEmpty) {
      return results.update(BookSearchResult.empty);
    }
    results.update(await bookUniverseRepo.search(containing));
  }

  static Future<Uint8List?> downloadMedSizeCover(OpenLibraryBook book) =>
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

  Future<BookSearchResult> search(String containing) async {
    String safe(String str) => str.replaceAll(r'\S', '+');
    final Uri url = apiUrl.replace(queryParameters: {
      'q': safe(containing),
      'limit': '10',
    });
    print('apiUrl: $url');
    final http.Response response = await http.get(url);
    if (response.statusCode != 200) {
      print('search error: $response');
      return BookSearchResult.empty;
    }
    final dynamic bodyJson = jsonDecode(response.body);
    final results = bodyJson['docs'] as List<dynamic>;
    return BookSearchResult(
      fullResultCount: bodyJson['numFound'] ?? -777,
      books: await Future.wait(
        results.map(
          (openLibBookDoc) async {
            final List? authorNames = openLibBookDoc['author_name'];
            return OpenLibraryBook(
              openLibBookDoc['title'],
              authorNames?.first ?? 'Unknown',
              openLibBookDoc['first_publish_year'],
              openLibBookDoc['number_of_pages_median'],
              openLibBookDoc['cover_i'],
              await coverBytes(openLibBookDoc['cover_i'], 'S'),
            );
          },
        ),
      ),
    );
  }

  Future<Uint8List?> coverBytes(int? coverId, String size) async {
    if (coverId == null) return null;
    print('getting cover $coverId');
    final http.Response response = await http.get(coverUrl(coverId, size));
    return response.bodyBytes;
  }
}

class OpenLibraryBook {
  const OpenLibraryBook(
    this.title,
    this.firstAuthor,
    this.yearFirstPublished,
    this.numPagesMedian,
    this.openLibCoverId,
    this.coverArtS,
  );

  final String title;
  final String firstAuthor;
  final int? yearFirstPublished;
  final int? numPagesMedian;
  final int? openLibCoverId;
  final Uint8List? coverArtS;
}
