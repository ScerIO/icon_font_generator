import 'dart:typed_data';
import 'package:collection/collection.dart';

import '../../common/codable/binary.dart';
import '../../utils/exception.dart';
import '../../utils/otf.dart';
import 'operand.dart';
import 'operator.dart';

const _kOperatorEscapeByte = 0x0C;

class CFFDictEntry extends BinaryCodable {
  CFFDictEntry(this.operandList, this.operator);

  factory CFFDictEntry.fromByteData(ByteData byteData, int startOffset) {
    final operandList = <CFFOperand>[];

    var offset = startOffset;

    while (offset < byteData.lengthInBytes) {
      final b0 = byteData.getUint8(offset++);

      if (b0 < 28) {
        /// Reading an operator (b0 is not in operand range)
        int? b1;

        if (b0 == _kOperatorEscapeByte) {
          /// An operator is 2-byte long
          b1 = byteData.getUint8(offset++);
        }

        return CFFDictEntry(
            operandList, CFFOperator(CFFOperatorContext.dict, b0, b1));
      } else {
        final operand = CFFOperand.fromByteData(byteData, offset, b0);
        operandList.add(operand);
        offset += operand.size - 1;
      }
    }

    throw TableDataFormatException('No operator for CFF dict entry');
  }

  final CFFOperator operator;
  final List<CFFOperand> operandList;

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    for (final operand in operandList) {
      final operandSize = operand.size;
      operand.encodeToBinary(byteData.sublistView(offset, operandSize));
      offset += operandSize;
    }

    operator.encodeToBinary(byteData.sublistView(offset, operator.size));
  }

  @override
  int get size =>
      operator.size + operandList.fold<int>(0, (p, e) => p + e.size);

  void recalculatePointers(int operandIndex, num Function() valueCallback) {
    int expectedOperandLength = 0, actualOperandLength;
    CFFOperand subrsOperand;

    do {
      expectedOperandLength++;

      // Filling with empty value and fixed length
      operandList.replaceRange(operandIndex, operandIndex + 1,
          [CFFOperand(null, expectedOperandLength)]);

      // Checking that offset's byte length is the same as current operand's length
      subrsOperand = CFFOperand.fromValue(valueCallback());
      actualOperandLength = subrsOperand.size;
    } while (expectedOperandLength != actualOperandLength);

    operandList.replaceRange(operandIndex, operandIndex + 1, [subrsOperand]);
  }

  @override
  String toString() {
    var operandListString = operandList.map((e) => e.toString()).join(', ');

    if (operandListString.length > 10) {
      operandListString = '${operandListString.substring(0, 10)}...';
    }

    return '$operator [$operandListString]';
  }
}

class CFFDict extends BinaryCodable {
  CFFDict(this.entryList);

  CFFDict.empty() : entryList = [];

  factory CFFDict.fromByteData(ByteData byteData) {
    final entryList = <CFFDictEntry>[];

    var offset = 0;

    while (offset < byteData.lengthInBytes) {
      final entry = CFFDictEntry.fromByteData(byteData, offset);
      entryList.add(entry);
      offset += entry.size;
    }

    return CFFDict(entryList);
  }

  List<CFFDictEntry> entryList;

  CFFDictEntry? getEntryForOperator(CFFOperator operator) {
    return entryList.firstWhereOrNull((e) => e.operator == operator);
  }

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    for (final e in entryList) {
      final entrySize = e.size;
      e.encodeToBinary(byteData.sublistView(offset, entrySize));
      offset += entrySize;
    }
  }

  @override
  int get size => entryList.fold<int>(0, (p, e) => p + e.size);
}
