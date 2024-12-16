import 'dart:convert';
import 'dart:typed_data';

import 'package:book_track/helpers.dart';
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
      bookUniverseRepo._coverBytes(book.openLibCoverId, 'M');
}

/// Open Library has a simple HTTP search endpoint for books and covers:
///     https://openlibrary.org/dev/docs/api/books
///    It doesn't require any authentication or setup.
///    ***I'm starting with this one for now.***
/// Google would probably work better/faster, but more difficult to use:
///     https://developers.google.com/books/docs/v1/using
/// Another one to check out is:
///     https://hardcover.app/account/api?referrer_id=15017
class OpenLibraryBookUniverseRepository {
  static final SimpleLogger log =
      SimpleLogger(prefix: 'OpenLibraryBookUniverseRepository');
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
      // NB: Sometimes I get 500 Internal Server Error from here.
      //  TODO(ux): Instead of immediately prompting user to retry, back off,
      //   then try again automagically.
      final oops =
          'search error: ${response.statusCode} ${response.reasonPhrase}';
      log(oops);
      return BookSearchResult.failed(oops);
    }
    final dynamic bodyJson = jsonDecode(response.body);
    final results = bodyJson['docs'] as List<dynamic>;
    return BookSearchResult(
      fullResultCount: bodyJson['numFound'] ?? -777,
      books: await Future.wait(
        results.map(
          (dynamic openLibBookDoc) async {
            final List? authorNames = openLibBookDoc['author_name'];
            return OpenLibraryBook(
              openLibBookDoc['title'],
              authorNames?.first ?? 'Unknown',
              openLibBookDoc['first_publish_year'],
              openLibBookDoc['number_of_pages_median'],
              openLibBookDoc['cover_i'],
              await _coverBytes(openLibBookDoc['cover_i'], 'S'),
            );
          },
        ),
      ),
    );
  }

  Future<Uint8List?> _coverBytes(int? coverId, String size) async {
    if (coverId == null) return null;
    var url = coverUrl(coverId, size);
    final http.Response response = await http.get(url);
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
