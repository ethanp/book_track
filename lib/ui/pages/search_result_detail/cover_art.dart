import 'dart:typed_data';

import 'package:book_track/services/book_universe_service.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class const CoverArt(final OpenLibraryBook book)
    extends ConsumerStatefulWidget {
  @override
  ConsumerState createState() => _CoverArtState();
}

class _CoverArtState() extends ConsumerState<CoverArt> {
  late final Future<Uint8List?> futureCoverArt;

  @override
  void initState() {
    super.initState();
    futureCoverArt = BookUniverseService.coverBytes(
      widget.book.openLibCoverId,
      OpenLibraryCoverSize.large,
    );
  }

  @override
  void dispose() {
    // `ignore()` is for when we _used to but no longer_ care about the result
    futureCoverArt.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder(
        future: futureCoverArt,
        builder: imageOrPlaceholder,
      ),
    );
  }

  Widget imageOrPlaceholder(
    BuildContext _,
    AsyncSnapshot<Uint8List?> snapshot,
  ) {
    final cover = BookCover(
      width: 150,
      height: 200,
      bytes: snapshot.data,
      borderRadius: 10,
    );
    if (snapshot.connectionState != ConnectionState.waiting) return cover;
    return Stack(
      alignment: Alignment.center,
      children: [cover, const CircularProgressIndicator()],
    );
  }
}
