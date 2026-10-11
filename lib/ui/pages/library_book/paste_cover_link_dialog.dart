import 'dart:typed_data';

import 'package:book_track/data_model.dart';
import 'package:book_track/riverpods.dart';
import 'package:book_track/sync/library_providers.dart';
import 'package:book_track/ui/common/book_cover.dart';
import 'package:ethan_ui/ethan_ui.dart';
import 'package:ethan_utils/ethan_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const _log = ELogger('PasteCoverLinkDialog');

class const PasteCoverLinkDialog() extends StatefulWidget {
  static const _downloadTimeout = Duration(seconds: 20);
  static const _maxCoverBytes = 4 * 1024 * 1024;

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required Book book,
  }) async {
    final Uint8List? coverArt = await showDialog<Uint8List>(
      context: context,
      builder: (context) => const PasteCoverLinkDialog(),
    );
    if (coverArt == null) return;
    _log.log('updating cover (${coverArt.length} bytes)');
    final libraryRepository = await ref.read(libraryRepositoryProvider.future);
    await libraryRepository.books.updateCoverArt(book, coverArt);
    ref.invalidate(userLibraryProvider);
  }

  @override
  State<PasteCoverLinkDialog> createState() => _PasteCoverLinkDialogState();
}

class _PasteCoverLinkDialogState() extends State<PasteCoverLinkDialog> {
  final TextEditingController _link = TextEditingController();
  String? _failure;
  bool _downloading = false;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  Future<void> _useLink() async {
    final Uri? url = _imageUrl(_link.text);
    if (url == null) {
      setState(() => _failure = 'Paste a link to an image.');
      return;
    }
    setState(() {
      _downloading = true;
      _failure = null;
    });
    try {
      final Uint8List? coverArt = await _downloadCover(url);
      if (!mounted) return;
      if (coverArt == null) {
        setState(() => _downloading = false);
        return;
      }
      Navigator.pop(context, coverArt);
    } catch (error) {
      _log.warn('cover download failed: $error');
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _failure = 'Could not download that image.';
      });
    }
  }

  Uri? _imageUrl(String link) {
    final Uri? url = Uri.tryParse(link.trim());
    if (url == null || !url.hasScheme || url.host.isEmpty) return null;
    if (url.scheme != 'http' && url.scheme != 'https') return null;
    return url;
  }

  Future<Uint8List?> _downloadCover(Uri url) async {
    final http.Response response = await http
        .get(url)
        .timeout(PasteCoverLinkDialog._downloadTimeout);
    if (!mounted) return null;
    if (response.statusCode != 200) {
      _failure = 'Could not download that image.';
      return null;
    }
    final Uint8List coverArt = response.bodyBytes;
    if (coverArt.length > PasteCoverLinkDialog._maxCoverBytes) {
      _failure = 'That image is too large.';
      return null;
    }
    if (BookCover.pixelSizeOf(coverArt) == null) {
      _failure = 'Use a JPEG or PNG.';
      return null;
    }
    return coverArt;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cover'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _link,
            autofocus: true,
            enabled: !_downloading,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'Link to an image',
              isDense: true,
            ),
            onSubmitted: (_) => _useLink(),
          ),
          if (_failure != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _failure!,
                style: const TextStyle(color: EColors.danger),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _downloading ? null : _useLink,
          child: _downloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
