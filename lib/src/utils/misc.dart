import 'dart:math' as math;

const int kUint8Max = 255;
const int kInt32Max = 2147483647;
const int kInt32Min = -2147483648;

const int kUnicodeSpaceCharCode = 0x20;

const int kUnicodePrivateUseAreaStart = 0xE000;
const int kUnicodePrivateUseAreaEnd = 0xF8FF;

int combineHashCode(int hashFirst, int hashOther) {
  var hash = 17;
  hash = hash * 31 + hashFirst;
  hash = hash * 31 + hashOther;
  return hash;
}

/// Converts quadratic bezier curve to a cubic one.
///
/// Takes three points as parameters, where [qp1] is a control point.
///
/// Returns two new control points in a list.
List<math.Point<num>> quadCurveToCubic(
    math.Point<num> qp0, math.Point<num> qp1, math.Point<num> qp2) {
  final cp1 = qp0 + (qp1 - qp0) * (2 / 3);
  final cp2 = qp2 + (qp1 - qp2) * (2 / 3);

  return [cp1, cp2];
}

extension MockableDateTime on DateTime {
  static DateTime? mockedDate;

  static DateTime now() => mockedDate ?? DateTime.now();
}

extension PointExt<T extends num> on math.Point<T> {
  math.Point<int> toIntPoint() => math.Point<int>(x.toInt(), y.toInt());

  math.Point<double> toDoublePoint() =>
      math.Point<double>(x.toDouble(), y.toDouble());

  math.Point<num> getReflectionOf(math.Point<T> point) {
    return math.Point<num>(2 * x - point.x, 2 * y - point.y);
  }
}
