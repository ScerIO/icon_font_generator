library;

import 'dart:typed_data';

import '../../common/calculatable_offsets.dart';
import '../../common/codable/binary.dart';
import '../../common/generic_glyph.dart';
import '../../utils/misc.dart';
import '../../utils/otf.dart';
import '../cff/char_string.dart';
import '../cff/char_string_operator.dart' as cs_op;
import '../cff/char_string_optimizer.dart';
import '../cff/dict.dart';
import '../cff/dict_operator.dart' as op;
import '../cff/index.dart';
import '../cff/operand.dart';
import '../cff/variations.dart';
import '../debugger.dart';
import 'abstract.dart';
import 'head.dart';
import 'hmtx.dart';
import 'name.dart';
import 'table_record_entry.dart';

part '../cff/charset.dart';
part '../cff/standard_string.dart';
part 'cff1.dart';
part 'cff2.dart';

const _kMajorVersion1 = 0x0001;
const _kMajorVersion2 = 0x0002;

abstract class CFFTable extends FontTable {
  CFFTable.fromTableRecordEntry(super.entry)
      : super.fromTableRecordEntry();

  static CFFTable? fromByteData(ByteData byteData, TableRecordEntry entry) {
    final major = byteData.getUint8(entry.offset);

    switch (major) {
      case _kMajorVersion1:
        return CFF1Table.fromByteData(byteData, entry);
      case _kMajorVersion2:
        return CFF2Table.fromByteData(byteData, entry);
    }

    debugUnsupportedTableVersion('CFF', major);
    return null;
  }

  bool get isCFF1 => this is CFF1Table;
}

void _calculateEntryOffsets(
  List<CFFDictEntry> entryList,
  List<int> offsetList, {
  int? operandIndex,
  List<int>? operandIndexList,
}) {
  if (operandIndex == null && operandIndexList == null) {
    throw ArgumentError.notNull('Specify operand index');
  }

  bool sizeChanged;

  /// Iterating and changing offsets while operand size is changing
  /// A bit dirty, maybe there's easier way to do that
  do {
    sizeChanged = false;

    for (var i = 0; i < entryList.length; i++) {
      final entryOperandIndex = operandIndex ?? operandIndexList![i];
      final entry = entryList[i];
      final oldOperand = entry.operandList[entryOperandIndex];
      final newOperand = CFFOperand.fromValue(offsetList[i]);

      final sizeDiff = newOperand.size - oldOperand.size;

      if (oldOperand.value != newOperand.value) {
        entry.operandList.replaceRange(
            entryOperandIndex, entryOperandIndex + 1, [newOperand]);
      }

      if (sizeDiff > 0) {
        sizeChanged = true;

        for (var i = 0; i < offsetList.length; i++) {
          offsetList[i] += sizeDiff;
        }
      }
    }
  } while (sizeChanged);
}
