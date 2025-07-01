import 'dart:convert';
import 'dart:typed_data';

import 'package:book_track/helpers.dart';
import 'package:book_track/riverpods.dart';
import 'package:http/http.dart' as http;

class BookUniverseService {
  static final _bookUniverseRepo = _OpenLibraryBookUniverseRepository();

  static Future<void> search(
    String expectedSubstring,
    BookSearchResultsNotifier bookSearchResultsNotifier,
  ) async {
    // Empty search string clears the search results list.
    if (expectedSubstring.isEmpty) {
      return bookSearchResultsNotifier.notify(BookSearchResults.empty);
    }

    final searchResults = await _bookUniverseRepo.search(expectedSubstring);
    bookSearchResultsNotifier.notify(searchResults);
  }

  static Future<Uint8List?> downloadMedSizeCover(OpenLibraryBook book) =>
      _bookUniverseRepo._coverBytes(book.openLibCoverId, 'M');
}

/// * Open Library has a simple HTTP search endpoint for books and covers:
///   * https://openlibrary.org/dev/docs/api/books
///   * It doesn't require any authentication or setup.
///   * **I'm starting with this one for now.**
///
/// * Google would probably work better/faster, but requires a token and has
///  more terms of service:
///   * https://developers.google.com/books/docs/v1/using
///   * I intend to try this out in the future.
///
/// * Another one to check out is:
///   * https://hardcover.app/account/api?referrer_id=15017
///   * Worth taking another look and maybe deleting this one from this list.
///
class _OpenLibraryBookUniverseRepository {
  static final SimpleLogger log =
      SimpleLogger(prefix: 'OpenLibraryBookUniverseRepository');

  static final Uri apiUrl = Uri.parse('https://openlibrary.org/search.json');

  static Uri coverUrl(int coverId, String size) =>
      Uri.parse('https://covers.openlibrary.org/b/id/$coverId-$size.jpg');

  Future<BookSearchResults> search(String containing) async {
    final Uri url = apiUrl.replace(queryParameters: {
      'q': Uri.encodeQueryComponent(containing),
      'limit': '10',
    });
    final http.Response response = await http.get(url);
    if (response.statusCode != 200) {
      // NB: Sometimes I get 500 Internal Server Error from here,
      // and a simple wait and retry fixes it.
      final oops = 'search error: '
          '${response.statusCode} ${response.reasonPhrase}.'
          ' Please try again.';
      log(oops);
      return BookSearchResults.failed(oops);
    }
    final dynamic bodyJson = jsonDecode(response.body);
    final results = bodyJson['docs'] as List<dynamic>;
    try {
      return BookSearchResults(
        fullResultCount: bodyJson['numFound'] ?? -777,
        books: await Future.wait(
          results.map(
            (dynamic /*Map<String, dynamic>*/ openLibBookDoc) async {
              final List<dynamic>? authorNames = openLibBookDoc['author_name'];
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
    } catch (e) {
      return BookSearchResults(books: [], fullResultCount: 0, failure: e);
    }
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
