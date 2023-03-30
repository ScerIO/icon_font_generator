import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';

import '../utils/enum_class.dart';

enum TransformType { matrix, translate, scale, rotate, skewX, skewY }

const _kTransformNameMap = EnumClass<TransformType, String>({
  TransformType.matrix: 'matrix',
  TransformType.translate: 'translate',
  TransformType.scale: 'scale',
  TransformType.rotate: 'rotate',
  TransformType.skewX: 'skewX',
  TransformType.skewY: 'skewY',
});

final _joinedTransformNames = _kTransformNameMap.values.join('|');

// Taken from svgicons2svgfont
final _transformRegExp = RegExp('($_joinedTransformNames)s*(([^)]*))s*');
final _transformParameterRegExp = RegExp(r'[\w.-]+');

class Transform {
  Transform(this.type, this.parameterList);

  final TransformType? type;
  final List<double> parameterList;

  static List<Transform> parse(String? string) {
    if (string == null) {
      return [];
    }

    final transforms = _transformRegExp.allMatches(string).map((m) {
      final name = m.group(1)!;
      final type = _kTransformNameMap.getKeyForValue(name);

      final parameterString = m.group(2)!;
      final parameterMatches =
          _transformParameterRegExp.allMatches(parameterString);
      final parameterList =
          parameterMatches.map((m) => double.parse(m.group(0)!)).toList();

      return Transform(type, parameterList);
    }).toList();

    return transforms;
  }

  Matrix3? get matrix {
    switch (type) {
      case TransformType.matrix:
        return Matrix3.fromList(
            [...parameterList, ...List.filled(9 - parameterList.length, 0)]);
      case TransformType.translate:
        final dx = parameterList[0];
        final dy = [...parameterList, .0][1];

        return _getTranslateMatrix(dx, dy);
      case TransformType.scale:
        final sw = parameterList[0];
        final sh = [...parameterList, .0][1];

        return _getScaleMatrix(sw, sh);
      case TransformType.rotate:
        final degrees = parameterList[0];
        var transform = _getRotateMatrix(degrees);

        // The rotation is about the point (x, y)
        if (parameterList.length > 1) {
          final x = parameterList[1];
          final y = [...parameterList, .0][2];

          final t = _getTranslateMatrix(x, y)
            ..multiply(transform)
            ..multiply(_getTranslateMatrix(-x, -y));
          transform = t;
        }

        return transform;
      case TransformType.skewX:
        return _skewX(parameterList[0]);
      case TransformType.skewY:
        return _skewY(parameterList[0]);
      case null:
        return null;
    }
  }
}

/// Generates transform matrix for a list of transforms.
///
/// Returns null, if transformList is empty.
Matrix3? generateTransformMatrix(List<Transform> transformList) {
  if (transformList.isEmpty) {
    return null;
  }

  final matrix = Matrix3.identity();

  for (final t in transformList) {
    if (t.matrix != null) {
      matrix.multiply(t.matrix!);
    }
  }

  return matrix;
}

Matrix3 _getTranslateMatrix(double dx, double dy) {
  return Matrix3.fromList([1, 0, dx, 0, 1, dy, 0, 0, 1]);
}

Matrix3 _getScaleMatrix(double sw, double sh) {
  return Matrix3.fromList([sw, 0, 0, 0, sh, 0, 0, 0, 1]);
}

Matrix3 _getRotateMatrix(double degrees) {
  return Matrix3.rotationZ(radians(degrees));
}

Matrix3 _skewX(double degrees) {
  return Matrix3.fromList([1, 0, 0, math.tan(radians(degrees)), 1, 0, 0, 0, 1]);
}

Matrix3 _skewY(double degrees) {
  return Matrix3.fromList([1, math.tan(radians(degrees)), 0, 0, 1, 0, 0, 0, 1]);
}
