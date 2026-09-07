import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Book cover art, or the on-brand unknown-cover image when none is usable.
class const BookCover({
  required final double width,
  required final double height,
  final Uint8List? bytes,
  final double borderRadius = 4,
}) extends StatelessWidget {
  static const _unknownCoverAsset = 'assets/images/unknown_book_cover.jpg';

  /// Pixel aspect of [assets/images/unknown_book_cover.jpg] (682×1024).
  static const fallbackAspectRatio = 682 / 1024;

  static Size? pixelSizeOf(Uint8List? bytes) {
    if (bytes == null) return null;
    return _CoverPixelSize.of(bytes);
  }

  static double aspectRatioOf(Uint8List? bytes) {
    final Size? size = pixelSizeOf(bytes);
    if (size == null || size.height <= 0) return fallbackAspectRatio;
    return size.width / size.height;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: _art(context)),
    );
  }

  Widget _art(BuildContext context) {
    if (!_hasDecodableCover) return _unknownCover();
    return Image.memory(
      bytes!,
      fit: BoxFit.cover,
      width: width,
      height: height,
      cacheWidth: _decodeWidthAtDisplaySize(context),
      errorBuilder: (_, _, _) => _unknownCover(),
    );
  }

  int? _decodeWidthAtDisplaySize(BuildContext context) {
    if (!width.isFinite || width <= 0) return null;
    final int pixelWidth = (width * MediaQuery.devicePixelRatioOf(context))
        .round();
    return pixelWidth > 0 ? pixelWidth : null;
  }

  Widget _unknownCover() => Image.asset(
    _unknownCoverAsset,
    fit: BoxFit.cover,
    width: width,
    height: height,
  );

  bool get _hasDecodableCover {
    final coverBytes = bytes;
    if (coverBytes == null) return false;
    return _CoverPixelSize.isJpeg(coverBytes) ||
        _CoverPixelSize.isPng(coverBytes);
  }
}

abstract final class _CoverPixelSize() {
  static Size? of(Uint8List bytes) {
    if (isPng(bytes)) return _pngSize(bytes);
    if (isJpeg(bytes)) return _jpegSize(bytes);
    return null;
  }

  static bool isJpeg(Uint8List bytes) =>
      bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;

  static bool isPng(Uint8List bytes) =>
      bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;

  static Size? _pngSize(Uint8List bytes) {
    final int width = _u32(bytes, 16);
    final int height = _u32(bytes, 20);
    if (width <= 0 || height <= 0) return null;
    return Size(width.toDouble(), height.toDouble());
  }

  static Size? _jpegSize(Uint8List bytes) {
    var offset = 2;
    while (offset + 8 < bytes.length) {
      if (bytes[offset] != 0xFF) return null;
      final int marker = bytes[offset + 1];
      offset += 2;
      if (marker == 0xD8 ||
          marker == 0xD9 ||
          (marker >= 0xD0 && marker <= 0xD7)) {
        continue;
      }
      if (offset + 1 >= bytes.length) return null;
      final int segmentLength = (bytes[offset] << 8) | bytes[offset + 1];
      if (segmentLength < 2) return null;
      if (_isJpegSof(marker)) {
        if (offset + 6 >= bytes.length) return null;
        final int height = (bytes[offset + 3] << 8) | bytes[offset + 4];
        final int width = (bytes[offset + 5] << 8) | bytes[offset + 6];
        if (width <= 0 || height <= 0) return null;
        return Size(width.toDouble(), height.toDouble());
      }
      offset += segmentLength;
    }
    return null;
  }

  static bool _isJpegSof(int marker) =>
      marker == 0xC0 ||
      marker == 0xC1 ||
      marker == 0xC2 ||
      marker == 0xC3 ||
      marker == 0xC5 ||
      marker == 0xC6 ||
      marker == 0xC7 ||
      marker == 0xC9 ||
      marker == 0xCA ||
      marker == 0xCB ||
      marker == 0xCD ||
      marker == 0xCE ||
      marker == 0xCF;

  static int _u32(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
