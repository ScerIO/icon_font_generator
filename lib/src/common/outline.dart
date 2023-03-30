import 'dart:math';

import '../utils/misc.dart';

/// How shapes with more than one closed outlines are filled.
///
/// * CharStrings must always be the nonzero
/// * TrueType is either always nonzero
/// or evenodd/nonzero according to OVERLAP_SIMPLE flag
/// (depending on rasterizer implementation)
/// * SVG can be both
enum FillRule { nonzero, evenodd }

/// A helper for working with outlines (including transforming).
///
/// TODO: It's very basic class for now used for generic glyph description. Replace it with a proper Path class (like java.awt.geom.Path2D or dart:ui's Path)
class Outline {
  Outline(this.pointList, this.isOnCurveList, this._hasCompactCurves,
      this._hasQuadCurves, this.fillRule);

  final List<Point<num>> pointList;
  final List<bool> isOnCurveList;
  final FillRule fillRule;

  /// Indicates weather curves are compact (midpoints and endpoint are implicit)
  bool _hasCompactCurves;
  bool get hasCompactCurves => _hasCompactCurves;

  /// Indicates weather outline contains quadratic or cubic curves
  bool _hasQuadCurves;
  bool get hasQuadCurves => _hasQuadCurves;

  /// Deep copy of an outline
  Outline copy() {
    return Outline([...pointList], [...isOnCurveList], _hasCompactCurves,
        _hasQuadCurves, fillRule);
  }

  /// Decompacts implicit points of quadratic curves (midpoints and end points)
  void decompactImplicitPoints() {
    if (!hasCompactCurves) {
      return;
    }

    if (!hasQuadCurves) {
      throw UnsupportedError('Only quadratic curves supported');
    }

    // Starting with 2, because first point can't be a CP and we need 2 of them
    for (var i = 2; i < pointList.length; i++) {
      // Two control points in a row
      if (!isOnCurveList[i - 1] && !isOnCurveList[i]) {
        final c0 = pointList[i - 1];
        final c1 = pointList[i];

        // Calculating midpoint
        final midpoint = (c0 + c1) * .5;

        // Adding midpoint to the list and moving to the next point
        pointList.insert(i, midpoint);
        isOnCurveList.insert(i, true);
        i++;
      }
    }

    // Last point is CP - duplicating start point
    if (!isOnCurveList.last) {
      isOnCurveList.add(true);
      pointList.add(pointList.first);
    }

    _hasCompactCurves = false;
  }

  /// Compacts implicit points of quadratic curves (midpoints and end points)
  void compactImplicitPoints() {
    if (!hasQuadCurves) {
      throw UnsupportedError('Only quadratic curves supported');
    }

    if (hasCompactCurves) {
      return;
    }

    // Starting with 2, because first point can't be a CP and we need 2 of them
    for (var i = 2; i < pointList.length; i++) {
      // Two control points in a row
      if (!isOnCurveList[i - 1] &&
          i + 1 < pointList.length &&
          !isOnCurveList[i + 1]) {
        final c0 = pointList[i - 1];
        final p0 = pointList[i];
        final c1 = pointList[i + 1];

        // Calculating midpoint
        final midpoint = (c0 + c1) * .5;

        // Point on curve equals calculated midpoint
        if (midpoint.toIntPoint() == p0.toIntPoint()) {
          pointList.removeAt(i);
          isOnCurveList.removeAt(i);
        }
      }
    }

    // Last point and end point are same
    if (pointList.length > 1 &&
        pointList.first.toIntPoint() == pointList.last.toIntPoint()) {
      pointList.removeLast();
      isOnCurveList.removeLast();
    }

    _hasCompactCurves = true;
  }

  /// Converts every quadratic bezier to a cubic one
  void quadToCubic() {
    if (hasCompactCurves) {
      throw UnsupportedError('Outline mustn\'t contain compact curves');
    }

    if (!hasQuadCurves) {
      return;
    }

    // Starting with 1, because first point can't be a CP
    for (var i = 1; i < pointList.length; i++) {
      if (isOnCurveList[i]) {
        continue;
      }

      final qp0 = pointList[i - 1];
      final qp1 = pointList[i];
      final qp2 = i + 1 < pointList.length ? pointList[i + 1] : pointList.first;

      pointList.replaceRange(i, i + 1, quadCurveToCubic(qp0, qp1, qp2));
      isOnCurveList.insert(i, false);
      i++;
    }

    _hasQuadCurves = false;
  }
}
