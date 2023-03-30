import 'dart:math' as math;

import '../otf/cff/char_string.dart';
import '../otf/cff/char_string_optimizer.dart';
import '../otf/table/glyph/flag.dart';
import '../otf/table/glyph/header.dart';
import '../otf/table/glyph/simple.dart';
import '../svg/outline_converter.dart';
import '../svg/path.dart';
import '../svg/svg.dart';
import '../utils/logger.dart';
import '../utils/misc.dart';
import '../utils/otf.dart';
import 'outline.dart';

/// Metadata for a generic glyph.
class GenericGlyphMetadata {
  GenericGlyphMetadata({
    this.charCode,
    this.name,
    this.ratioX,
    this.ratioY,
    this.offset,
    this.preview,
  });

  int? charCode;
  String? name;
  double? ratioX;
  double? ratioY;
  int? offset;

  /// base64 encoded image
  String? preview;

  /// Deep copy
  GenericGlyphMetadata copy() {
    return GenericGlyphMetadata(charCode: charCode, name: name);
  }
}

/// Metrics for a generic glyph.
class GenericGlyphMetrics {
  GenericGlyphMetrics(this.xMin, this.xMax, this.yMin, this.yMax);

  factory GenericGlyphMetrics.empty() => GenericGlyphMetrics(0, 0, 0, 0);

  factory GenericGlyphMetrics.square(int unitsPerEm) =>
      GenericGlyphMetrics(0, unitsPerEm, 0, unitsPerEm);

  final int xMin;
  final int xMax;
  final int yMin;
  final int yMax;

  int get width => xMax - xMin;

  int get height => yMax - yMin;
}

/// Generic glyph.
/// Used as an intermediate storage between different types of glyphs
/// (including OpenType's CharString, TrueType outlines).
class GenericGlyph {
  GenericGlyph(this.outlines, this.bounds, [GenericGlyphMetadata? metadata])
      : metadata = metadata ?? GenericGlyphMetadata();

  GenericGlyph.empty()
      : outlines = [],
        bounds = const math.Rectangle(0, 0, 0, 0),
        metadata = GenericGlyphMetadata();

  factory GenericGlyph.fromSimpleTrueTypeGlyph(SimpleGlyph glyph) {
    final isOnCurveList = glyph.flags.map((e) => e.onCurvePoint).toList();
    final endPoints = [-1, ...glyph.endPtsOfContours];

    final outlines = [
      for (var i = 1; i < endPoints.length; i++)
        Outline(
            glyph.pointList.sublist(endPoints[i - 1] + 1, endPoints[i] + 1),
            isOnCurveList.sublist(endPoints[i - 1] + 1, endPoints[i] + 1),
            true,
            true,
            FillRule.nonzero)
    ];

    final bounds = math.Rectangle(
      glyph.header.xMin,
      glyph.header.yMin,
      glyph.header.xMax - glyph.header.xMin,
      glyph.header.yMax - glyph.header.yMin,
    );

    return GenericGlyph(outlines, bounds);
  }

  factory GenericGlyph.fromSvg(Svg svg) {
    final pathList = svg.elementList.whereType<PathElement>();

    final outlines = [
      for (final p in pathList) ...PathToOutlineConverter(svg, p).convert()
    ];

    final metadata = GenericGlyphMetadata(
      name: svg.name,
      ratioX: svg.ratioX,
      ratioY: svg.ratioY,
      offset: svg.offset,
      preview: svg.toBase64(),
    );

    return GenericGlyph(outlines, svg.viewBox, metadata);
  }

  final List<Outline> outlines;
  final math.Rectangle bounds;
  final GenericGlyphMetadata metadata;

  /// Deep copy of a glyph and its outlines
  GenericGlyph copy() {
    final outlines = this.outlines.map((e) => e.copy()).toList();
    return GenericGlyph(outlines, bounds, metadata.copy());
  }

  List<bool> _getIsOnCurveList() {
    return [for (final o in outlines) ...o.isOnCurveList];
  }

  List<math.Point> _getPointList() {
    return [for (final o in outlines) ...o.pointList];
  }

  List<int> _getEndPoints() {
    final endPoints = [-1];

    for (final o in outlines) {
      endPoints.add(endPoints.last + o.pointList.length);
    }

    endPoints.removeAt(0);

    return endPoints;
  }

  List<CharStringCommand> toCharStringCommands(CharStringOptimizer optimizer) {
    for (final outline in outlines) {
      if (outline.hasQuadCurves) {
        // NOTE: what about doing it implicitly?
        throw UnsupportedError('CharString outlines must contain cubic curves');
      }

      if (outline.fillRule == FillRule.evenodd) {
        logger.logOnce(Level.warning,
            'Some of the outlines are using even-odd fill rule. Make sure using a non-zero winding number fill rule for OpenType outlines.');
      }
    }

    final commandList = <CharStringCommand>[];

    final isOnCurveList = _getIsOnCurveList();
    final endPoints = _getEndPoints();
    final pointList = _getPointList();

    final relX =
        absToRelCoordinates(pointList.map((e) => e.x.toInt()).toList());
    final relY =
        absToRelCoordinates(pointList.map((e) => e.y.toInt()).toList());

    var isContourStart = true;

    for (var i = 0; i < relX.length; i++) {
      if (isContourStart) {
        commandList.add(CharStringCommand.moveto(relX[i], relY[i]));
        isContourStart = false;
        continue;
      }

      if (!isOnCurveList[i] && !isOnCurveList[i + 1]) {
        final points = [
          for (var p = 0; p < 3; p++) ...[relX[i + p], relY[i + p]]
        ];

        commandList.add(CharStringCommand.curveto(points));
        i += 2;
      } else {
        commandList.add(CharStringCommand.lineto(relX[i], relY[i]));
      }

      if (endPoints.isNotEmpty && endPoints.first == i) {
        endPoints.removeAt(0);
        isContourStart = true;
      }
    }

    return optimizer.optimize(commandList);
  }

  SimpleGlyph toSimpleTrueTypeGlyph() {
    final isOnCurveList = _getIsOnCurveList();
    final endPoints = _getEndPoints();
    final pointList = _getPointList();

    final absXcoordinates = pointList.map((p) => p.x.toInt()).toList();
    final absYcoordinates = pointList.map((p) => p.y.toInt()).toList();

    final relXcoordinates = absToRelCoordinates(absXcoordinates);
    final relYcoordinates = absToRelCoordinates(absYcoordinates);

    final xMin = absXcoordinates.fold<int>(kInt32Max, math.min);
    final yMin = absYcoordinates.fold<int>(kInt32Max, math.min);
    final xMax = absXcoordinates.fold<int>(kInt32Min, math.max);
    final yMax = absYcoordinates.fold<int>(kInt32Min, math.max);

    final flags = [
      for (var i = 0; i < pointList.length; i++)
        SimpleGlyphFlag.createForPoint(
            relXcoordinates[i], relYcoordinates[i], isOnCurveList[i])
    ];

    // TODO: compact flags: repeat & not short same flag

    return SimpleGlyph(
      GlyphHeader(endPoints.length, xMin, yMin, xMax, yMax),
      endPoints,
      [],
      flags,
      pointList,
    );
  }

  /// Resizes according to ascender/descender or a font height.
  GenericGlyph resize({
    int? ascender,
    int? descender,
    int? fontHeight,
    double? ratioX,
    double? ratioY,
  }) {
    final metrics = this.metrics;

    late final int longestSide;
    late final double sideRatioX;
    late final double sideRatioY;

    if (ascender != null && descender != null) {
      longestSide = math.max(metrics.height, metrics.width);
      sideRatioX = (ascender + descender) / longestSide * (ratioX ?? 1);
      sideRatioY = (ascender + descender) / longestSide * (ratioY ?? 1);
    } else if (fontHeight != null) {
      longestSide = bounds.height.toInt();
      sideRatioX = fontHeight / longestSide * (ratioX ?? 1);
      sideRatioY = fontHeight / longestSide * (ratioY ?? 1);
    } else {
      throw ArgumentError('Wrong parameters for resizing');
    }

    // No need to resize
    if ((sideRatioX - 1).abs() < .02 && (sideRatioY - 1).abs() < .02) {
      return this;
    }

    final newOutlines = outlines.map((o) {
      final newOutline = o.copy();
      final newPointList = newOutline.pointList
          .map((e) => math.Point<num>(e.x * sideRatioX, e.y * sideRatioY))
          .toList();
      newOutline.pointList
        ..clear()
        ..addAll(newPointList);
      return newOutline;
    }).toList();

    final newBounds = math.Rectangle.fromPoints(
      math.Point<num>(bounds.bottomLeft.toDoublePoint().x * sideRatioX,
          bounds.bottomLeft.toDoublePoint().y * sideRatioY),
      math.Point<num>(bounds.topRight.toDoublePoint().x * sideRatioX,
          bounds.topRight.toDoublePoint().y * sideRatioY),
      // bounds.topRight.toDoublePoint() * sideRatio,
    );

    return GenericGlyph(newOutlines, newBounds, metadata);
  }

  GenericGlyph center(int ascender, int descender, int offset) {
    final metrics = this.metrics;

    final offsetX = -metrics.xMin;
    final offsetY =
        (ascender + descender) / 2 - metrics.height / 2 - metrics.yMin + offset;

    final newOutlines = outlines.map((o) {
      final newOutline = o.copy();
      final newPointList = newOutline.pointList
          .map((e) => math.Point<num>(e.x + offsetX, e.y + offsetY))
          .toList();
      newOutline.pointList
        ..clear()
        ..addAll(newPointList);
      return newOutline;
    }).toList();

    final newBounds = math.Rectangle(
      bounds.left + offsetX,
      bounds.bottom + offsetY,
      bounds.width,
      bounds.height,
    );

    return GenericGlyph(newOutlines, newBounds, metadata);
  }

  GenericGlyphMetrics get metrics {
    final points = _getPointList();

    if (points.isEmpty) {
      return GenericGlyphMetrics.empty();
    }

    var xMin = kInt32Max, yMin = kInt32Max, xMax = kInt32Min, yMax = kInt32Min;

    for (final p in points) {
      if (p.x.isFinite && p.y.isFinite) {
        xMin = math.min(xMin, p.x.toInt());
        xMax = math.max(xMax, p.x.toInt());
        yMin = math.min(yMin, p.y.toInt());
        yMax = math.max(yMax, p.y.toInt());
      }
    }
    return GenericGlyphMetrics(xMin, xMax, yMin, yMax);
  }
}
