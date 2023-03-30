import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../common/codable/binary.dart';
import 'char_string_operator.dart';
import 'dict_operator.dart';

enum CFFOperatorContext { dict, charString }

@immutable
class CFFOperator implements BinaryCodable {
  const CFFOperator(this.context, this.b0, [this.b1])
      : intValue = b1 != null ? ((b0 << 8) | b1) : b0;

  final int b0;
  final int? b1;
  final int intValue;
  final CFFOperatorContext context;

  @override
  int get size => b1 == null ? 1 : 2;

  @override
  int get hashCode => intValue.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is CFFOperator) {
      return other.intValue == intValue;
    }

    return false;
  }

  @override
  void encodeToBinary(ByteData byteData) {
    byteData.setUint8(0, b0);

    if (b1 != null) {
      byteData.setUint8(1, b1!);
    }
  }

  @override
  String toString() {
    var name = '<unknown>';

    switch (context) {
      case CFFOperatorContext.dict:
        if (dictOperatorNames.containsKey(this)) {
          name = dictOperatorNames[this]!;
        }
        break;
      case CFFOperatorContext.charString:
        if (charStringOperatorNames.containsKey(this)) {
          name = charStringOperatorNames[this]!;
        }
        break;
    }

    return name;
  }
}
