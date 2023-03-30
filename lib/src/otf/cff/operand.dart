import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/exception.dart';

const _kRealNumberTerminator = 0xF;

const _kStringForRealNumberByte = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '.',
  'E',
  'E-',
  '',
  '-',
  '',
];

class CFFOperand extends BinaryCodable {
  CFFOperand(this.value, this._size, {this.forceLargeInt = false});

  CFFOperand.fromValue(this.value, {this.forceLargeInt = false});

  factory CFFOperand.fromByteData(ByteData byteData, int offset, int b0) {
    /// -107 to +107
    int decodeOneByte() {
      return b0 - 139;
    }

    /// +108 to +1131
    int decodeTwoBytePositive() {
      final b1 = byteData.getUint8(offset++);

      return (b0 - 247) * 256 + b1 + 108;
    }

    /// -1131 to -108
    int decodeTwoByteNegative() {
      final b1 = byteData.getUint8(offset++);

      return -(b0 - 251) * 256 - b1 - 108;
    }

    /// -32768 to +32767
    int decodeThreeByte() {
      final value = byteData.getUint16(offset);
      offset += 2;

      return value;
    }

    /// -(2^31) to +(2^31 - 1)
    int decodeFiveByte() {
      final value = byteData.getUint32(offset);
      offset += 4;

      return value;
    }

    /// Real number
    double decodeRealNumber() {
      final sb = StringBuffer();

      // ignore: literal_only_boolean_expressions
      while (true) {
        final b = byteData.getUint8(offset++);

        final n1 = b >> 4;
        if (n1 == _kRealNumberTerminator) {
          break;
        }

        sb.write(_kStringForRealNumberByte[n1]);

        final n2 = b & 0xF;
        if (n2 == _kRealNumberTerminator) {
          break;
        }

        sb.write(_kStringForRealNumberByte[n2]);
      }

      return double.parse(sb.toString());
    }

    if (b0 == 28) {
      return CFFOperand(decodeThreeByte(), 3);
    } else if (b0 == 29) {
      return CFFOperand(decodeFiveByte(), 5);
    } else if (b0 == 30) {
      final startNumberOffset = offset;
      return CFFOperand(decodeRealNumber(),
          offset - startNumberOffset + 1 // + 1 because of byte 0
          );
    } else if (b0 >= 32 && b0 <= 246) {
      return CFFOperand(decodeOneByte(), 1);
    } else if (b0 >= 247 && b0 <= 250) {
      return CFFOperand(decodeTwoBytePositive(), 2);
    } else if (b0 >= 251 && b0 <= 254) {
      return CFFOperand(decodeTwoByteNegative(), 2);
    } else {
      throw TableDataFormatException(
          'Unknown operand type in CFF table (offset $offset)');
    }
  }

  /// Either real or integer number
  final num? value;

  /// Weather should force max-length integer or not (used for offset pointers)
  final bool forceLargeInt;

  int? _size;

  /// Returns normalized string representation of a real number
  String _doubleToNormalizedString() {
    if (value is! double) {
      throw StateError('Value type is not double');
    }

    var string = value.toString();

    // Removing integer part if it's 0
    string = string.replaceFirst(RegExp(r'^0.'), '.');

    // Making exponent char uppercase
    string = string.replaceFirst('e', 'E');

    // Removing plus
    string = string.replaceFirst('+', '');

    return string;
  }

  num get _guardedValue {
    if (value == null) {
      throw StateError('Value must not be null');
    }

    return value!;
  }

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;
    final value = _guardedValue;

    void writeDouble() {
      final s = _doubleToNormalizedString();

      var firstHalf = true;
      late int prevNibble;

      for (var i = 0; i < s.length; i++) {
        var char = s[i];

        if (char == 'E' && s[i + 1] == '-') {
          char += '-';
          i++;
        }

        final nibble = _kStringForRealNumberByte.indexOf(char);

        if (firstHalf) {
          prevNibble = nibble;
        } else {
          byteData.setUint8(offset++, (prevNibble << 4) | nibble);
        }

        firstHalf = !firstHalf;
      }

      if (firstHalf) {
        byteData.setUint8(offset++, 0xFF);
      } else {
        byteData.setUint8(offset++, (prevNibble << 4) | _kRealNumberTerminator);
      }
    }

    if (value is double) {
      byteData.setUint8(offset++, 30);
      writeDouble();
    } else {
      var intValue = value as int;

      if (!forceLargeInt && intValue >= -107 && intValue <= 107) {
        byteData.setUint8(offset++, intValue + 139);
      } else if (!forceLargeInt && intValue >= 108 && intValue <= 1131) {
        intValue -= 108;

        byteData
          ..setUint8(offset++, (intValue >> 8) + 247)
          ..setUint8(offset++, intValue & 0xFF);
      } else if (!forceLargeInt && intValue >= -1131 && intValue <= -108) {
        intValue = -intValue - 108;

        byteData
          ..setUint8(offset++, (intValue >> 8) + 251)
          ..setUint8(offset++, intValue & 0xFF);
      } else if (!forceLargeInt && intValue >= -32768 && value <= 32767) {
        byteData
          ..setUint8(offset++, 28)
          ..setUint16(offset, intValue);
        offset += 2;
      } else {
        byteData
          ..setUint8(offset++, 29)
          ..setUint32(offset, intValue);
        offset += 4;
      }
    }
  }

  @override
  int get size {
    if (_size != null) {
      return _size!;
    }

    final value = _guardedValue;

    return _size = () {
      if (value is double) {
        var valueString = _doubleToNormalizedString();
        valueString =
            valueString.replaceFirst('E-', 'E'); // 'E-' used as a single char

        return 1 + ((valueString.length + 1) / 2).ceil();
      } else if (value >= -107 && value <= 107) {
        return 1;
      } else if ((value >= 108 && value <= 1131) ||
          (value >= -1131 && value <= -108)) {
        return 2;
      } else if (value >= -32768 && value <= 32767) {
        return 3;
      } else {
        return 5;
      }
    }();
  }

  @override
  String toString() => value.toString();
}
