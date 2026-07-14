import 'package:test/test.dart';

import 'charcodes_test.dart' as charcodes;
import 'cli_test.dart' as cli;
import 'normalize_test.dart' as norm;
import 'ttf_test.dart' as ttf;

void main() {
  group('TTF', ttf.main);
  group('CLI', cli.main);
  group('Normalization', norm.main);
  group('CharCodes', charcodes.main);
}
