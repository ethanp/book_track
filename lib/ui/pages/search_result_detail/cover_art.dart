import 'dart:typed_data';

import 'package:book_track/services/book_universe_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoverArt extends ConsumerStatefulWidget {
  const CoverArt(this.book);

  final OpenLibraryBook book;

  @override
  ConsumerState createState() => _CoverArtState();
}

class _CoverArtState extends ConsumerState<CoverArt> {
  late final Future<Uint8List?> futureCoverArtMedSize;

  @override
  void initState() {
    super.initState();
    futureCoverArtMedSize =
        BookUniverseService.downloadMedSizeCover(widget.book);
  }

  @override
  void dispose() {
    // `ignore()` is for when we _used to but no longer_ care about the result
    futureCoverArtMedSize.ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: FutureBuilder(
        future: futureCoverArtMedSize,
        builder: imageOrPlaceholder,
      ),
    );
  }

  Widget imageOrPlaceholder(
    BuildContext _,
    AsyncSnapshot<Uint8List?> snapshot,
  ) {
    // Waiting: Show loading indicator
    if (snapshot.connectionState == ConnectionState.waiting) {
      return coverArtMissingPlaceholder(loading: true);
    }
    // Null: Show blank box
    if (snapshot.data == null) {
      return coverArtMissingPlaceholder(loading: false);
    }
    // Data: Show image
    return Image.memory(snapshot.data!);
  }

  Widget coverArtMissingPlaceholder({required bool loading}) {
    return Container(
      height: 200,
      width: 150,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: loading
            ? CircularProgressIndicator()
            : SizedBox(
                width: 110,
                child: Text(
                  'No cover art found',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                ),
              ),
      ),
    );
  }
}
