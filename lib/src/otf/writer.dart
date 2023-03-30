import 'dart:typed_data';

import 'otf.dart';

/// A helper for writing an OpenType font as a binary data.
class OTFWriter {
  /// Writes OpenType font as a binary data.
  ByteData write(OpenTypeFont font) {
    final byteData = ByteData(font.size);
    font.encodeToBinary(byteData);

    return byteData;
  }
}
