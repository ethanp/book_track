import 'dart:convert';
import 'dart:ui';

import 'package:book_track/data_model.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const _log = ELogger('BookCoverSearch');

/// Finds up to [maxCovers] cover images for a library book that are big
/// enough and shaped like a book cover.
///
/// Open Library matches the book to its works, which carry their editions'
/// ISBNs and any uploaded cover. Amazon serves a ~500px-tall cover per
/// ISBN-10; Open Library serves its large cover per cover id.
class BookCoverSearch(final LibraryBook libraryBook) {
  static const maxCovers = 10;
  static const _maxMatchedWorks = 3;
  static const _maxAmazonIsbns = 24;
  static const _minCoverWidth = 250;
  static const _minCoverHeight = 380;
  static const _requestTimeout = Duration(seconds: 15);

  /// Printed covers run from tall trade paperbacks (~0.6) to wide
  /// technical books (Manning, ~0.8).
  static const _minPrintAspect = 0.55;
  static const _maxPrintAspect = 0.86;

  /// Audiobook covers are square.
  static const _minAudiobookAspect = 0.92;
  static const _maxAudiobookAspect = 1.08;

  Future<List<Uint8List>> topCovers() async {
    final List<Uri> coverUrls = await _candidateCoverUrls();
    _log.log('downloading ${coverUrls.length} candidate covers');
    final List<Uint8List?> downloads = await Future.wait(
      coverUrls.map(_downloadOrNull),
    );
    final List<Uint8List> covers = [];
    for (final Uint8List? coverArt in downloads) {
      if (coverArt == null || !_isBookShaped(coverArt)) continue;
      if (_alreadyHave(covers, coverArt)) continue;
      covers.add(coverArt);
      if (covers.length == maxCovers) break;
    }
    return covers;
  }

  Future<List<Uri>> _candidateCoverUrls() async {
    final Book book = libraryBook.book;
    final Uri searchUrl = Uri.https('openlibrary.org', '/search.json', {
      'q': [book.title, ?book.author].join(' '),
      'limit': '10',
      'fields': 'title,cover_i,isbn',
    });
    final http.Response response = await http
        .get(searchUrl)
        .timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception('Open Library search failed: ${response.statusCode}');
    }
    final List<dynamic> workDocs = jsonDecode(response.body)['docs'];
    final List<dynamic> matchedWorkDocs = workDocs
        .where((dynamic workDoc) => _titleMatches(workDoc['title'] as String))
        .take(_maxMatchedWorks)
        .toList();

    final Set<String> isbn10s = {
      for (final dynamic workDoc in matchedWorkDocs)
        for (final dynamic isbn in workDoc['isbn'] ?? const [])
          ?_isbn10Of(isbn as String),
    };
    final List<int> openLibraryCoverIds = [
      for (final dynamic workDoc in matchedWorkDocs)
        ?workDoc['cover_i'] as int?,
    ];
    return [
      for (final String isbn10 in isbn10s.take(_maxAmazonIsbns))
        Uri.https(
          'm.media-amazon.com',
          '/images/P/$isbn10.01._SCLZZZZZZZ_.jpg',
        ),
      for (final int coverId in openLibraryCoverIds)
        Uri.https('covers.openlibrary.org', '/b/id/$coverId-L.jpg', {
          'default': 'false',
        }),
    ];
  }

  bool _titleMatches(String workTitle) {
    final String wanted = _comparableTitle(libraryBook.book.title);
    final String found = _comparableTitle(workTitle);
    return found.contains(wanted) || wanted.contains(found);
  }

  String _comparableTitle(String title) =>
      title.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');

  /// Amazon keys cover images by ISBN-10. A 978- ISBN-13 converts;
  /// 979- ISBN-13s have no ISBN-10.
  String? _isbn10Of(String isbn) {
    if (isbn.length == 10) return isbn;
    if (isbn.length != 13 || !isbn.startsWith('978')) return null;
    final String body = isbn.substring(3, 12);
    var weightedSum = 0;
    for (var index = 0; index < body.length; index++) {
      weightedSum += (10 - index) * int.parse(body[index]);
    }
    final int checkDigit = (11 - weightedSum % 11) % 11;
    return '$body${checkDigit == 10 ? 'X' : checkDigit}';
  }

  Future<Uint8List?> _downloadOrNull(Uri url) async {
    try {
      final http.Response response = await http
          .get(url)
          .timeout(_requestTimeout);
      if (response.statusCode != 200) return null;
      return response.bodyBytes;
    } catch (error) {
      _log.warn('cover download failed for $url: $error');
      return null;
    }
  }

  bool _isBookShaped(Uint8List coverArt) {
    final Size? pixelSize = BookCover.pixelSizeOf(coverArt);
    if (pixelSize == null) return false;
    if (pixelSize.width < _minCoverWidth) return false;
    if (pixelSize.height < _minCoverHeight) return false;
    final double aspect = pixelSize.width / pixelSize.height;
    if (aspect >= _minPrintAspect && aspect <= _maxPrintAspect) return true;
    if (!libraryBook.formats.any((format) => format.isAudiobook)) return false;
    return aspect >= _minAudiobookAspect && aspect <= _maxAudiobookAspect;
  }

  /// Different editions often share one image; so may the current cover.
  bool _alreadyHave(List<Uint8List> covers, Uint8List coverArt) {
    final Uint8List? currentCover = libraryBook.book.coverArt;
    if (currentCover != null && listEquals(currentCover, coverArt)) return true;
    return covers.any((cover) => listEquals(cover, coverArt));
  }
}
