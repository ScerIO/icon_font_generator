import 'dart:typed_data';

import '../../../common/codable/binary.dart';
import '../../../utils/otf.dart';

const _kOnCurvePointValue = 0x01;
const _kXshortVectorValue = 0x02;
const _kYshortVectorValue = 0x04;
const _kRepeatFlagValue = 0x08;
const _kXisSameValue = 0x10;
const _kYisSameValue = 0x20;
const _kOverlapSimpleValue = 0x40;
const _kReservedValue = 0x80;

class SimpleGlyphFlag implements BinaryCodable {
  SimpleGlyphFlag(
      this.onCurvePoint,
      this.xShortVector,
      this.yShortVector,
      this.repeat,
      this.xIsSameOrPositive,
      this.yIsSameOrPositive,
      this.overlapSimple,
      this.reserved);

  factory SimpleGlyphFlag.fromIntValue(int flag, [int? repeatTimes]) {
    return SimpleGlyphFlag(
        checkBitMask(flag, _kOnCurvePointValue),
        checkBitMask(flag, _kXshortVectorValue),
        checkBitMask(flag, _kYshortVectorValue),
        repeatTimes,
        checkBitMask(flag, _kXisSameValue),
        checkBitMask(flag, _kYisSameValue),
        checkBitMask(flag, _kOverlapSimpleValue),
        checkBitMask(flag, _kReservedValue));
  }

  factory SimpleGlyphFlag.fromByteData(ByteData byteData, int offset) {
    final flag = byteData.getUint8(offset);
    final repeatFlag = checkBitMask(flag, _kRepeatFlagValue);
    final repeatTimes = repeatFlag ? byteData.getUint8(offset + 1) : null;

    return SimpleGlyphFlag.fromIntValue(flag, repeatTimes);
  }

  factory SimpleGlyphFlag.createForPoint(int x, int y, bool isOnCurve) {
    final xIsShort = isShortInteger(x);
    final yIsShort = isShortInteger(y);

    return SimpleGlyphFlag(
        isOnCurve,
        xIsShort,
        yIsShort,
        null,
        xIsShort && !x.isNegative, // 1 if short and positive, 0 otherwise
        yIsShort && !y.isNegative, // 1 if short and positive, 0 otherwise
        false,
        false);
  }

  final bool onCurvePoint;
  final bool xShortVector;
  final bool yShortVector;
  final int? repeat;
  final bool xIsSameOrPositive;
  final bool yIsSameOrPositive;
  final bool overlapSimple;
  final bool reserved;

  Map<int, bool> get _valueForMaskMap => {
        _kOnCurvePointValue: onCurvePoint,
        _kXshortVectorValue: xShortVector,
        _kYshortVectorValue: yShortVector,
        _kXisSameValue: xIsSameOrPositive,
        _kYisSameValue: yIsSameOrPositive,
        _kOverlapSimpleValue: overlapSimple,
        _kReservedValue: reserved,
        _kRepeatFlagValue: isRepeating,
      };

  bool get isRepeating => repeat != null;

  int get repeatTimes => repeat ?? 0;

  int get intValue {
    var value = 0;

    _valueForMaskMap.forEach((mask, flagIsSet) {
      value |= flagIsSet ? mask : 0;
    });

    return value;
  }

  @override
  int get size => 1 + (isRepeating ? 1 : 0);

  @override
  void encodeToBinary(ByteData byteData) {
    byteData.setUint8(0, intValue);

    if (isRepeating) {
      byteData.setUint8(1, repeatTimes);
    }
  }
}
