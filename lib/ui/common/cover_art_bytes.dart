import 'dart:typed_data';

/// Whether [bytes] look like a JPEG or PNG we should try to decode.
///
/// Rejects empty/HTML/truncated payloads before [Image.memory] throws
/// "Invalid image data".
bool coverArtLooksDecodable(Uint8List bytes) {
  if (bytes.length < 3) return false;
  // JPEG SOI (FF D8 FF…) — APP0/APP1/etc. all fine
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
  // PNG signature
  return bytes.length >= 4 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47;
}
