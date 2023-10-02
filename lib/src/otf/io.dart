import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../utils/logger.dart';
import 'otf.dart';
import 'reader.dart';
import 'writer.dart';

/// Reads OpenType font from a file.
OpenTypeFont readFromFile(String path) =>
    OTFReader.fromByteData(ByteData.sublistView(File(path).readAsBytesSync()))
        .read();

/// Writes OpenType font to a file.
void writeToFile(String path, OpenTypeFont font) {
  final file = File(path)..createSync(recursive: true);
  final byteData = OTFWriter().write(font);
  final extension = p.extension(file.path).toLowerCase();

  if (extension != '.otf' && font.isOpenType) {
    logger.w(
        'A font that contains only CFF outline data should have an .OTF extension.');
  }

  file.writeAsBytesSync(byteData.buffer.asUint8List());
}
