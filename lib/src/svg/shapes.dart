import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../utils/svg.dart';
import 'element.dart';
import 'path.dart';

/// Element convertable to path.
abstract class PathConvertible {
  PathElement getPath();
}

class RectElement extends SvgElement implements PathConvertible {
  RectElement(
      this.rectangle, this.rx, this.ry, SvgElement? parent, XmlElement element)
      : super(parent, element);

  factory RectElement.fromXmlElement(SvgElement? parent, XmlElement element) {
    final rect = math.Rectangle(
      element.getScalarAttribute('x')!,
      element.getScalarAttribute('y')!,
      element.getScalarAttribute('width')!,
      element.getScalarAttribute('height')!,
    );

    var rx = element.getScalarAttribute('rx', zeroIfAbsent: false);
    var ry = element.getScalarAttribute('ry', zeroIfAbsent: false);

    ry ??= rx;
    rx ??= ry;

    return RectElement(rect, rx ?? 0, ry ?? 0, parent, element);
  }

  final math.Rectangle rectangle;
  final num rx;
  final num ry;

  num get x => rectangle.left;

  num get y => rectangle.top;

  num get width => rectangle.width;

  num get height => rectangle.height;

  @override
  PathElement getPath() {
    final topRight = rx != 0 || ry != 0 ? 'a $rx $ry 0 0 1 $rx $ry' : '';
    final bottomRight = rx != 0 || ry != 0 ? 'a $rx $ry 0 0 1 ${-rx} $ry' : '';
    final bottomLeft =
        rx != 0 || ry != 0 ? 'a $rx $ry 0 0 1 ${-rx} ${-ry}' : '';
    final topLeft = rx != 0 || ry != 0 ? 'a $rx $ry 0 0 1 $rx ${-ry}' : '';

    final d =
        'M${x + rx} ${y}h${width - rx * 2}${topRight}v${height - ry * 2}${bottomRight}h${-(width - rx * 2)}${bottomLeft}v${-(height - ry * 2)}${topLeft}z';

    return PathElement(null, d, parent, null, transform: transform);
  }
}

class CircleElement extends SvgElement implements PathConvertible {
  CircleElement(this.center, this.r, SvgElement? parent, XmlElement element)
      : super(parent, element);

  factory CircleElement.fromXmlElement(SvgElement? parent, XmlElement element) {
    final center = math.Point(
        element.getScalarAttribute('cx')!, element.getScalarAttribute('cy')!);

    final r = element.getScalarAttribute('r')!;

    return CircleElement(center, r, parent, element);
  }

  final math.Point center;
  final num r;

  num get cx => center.x;

  num get cy => center.y;

  @override
  PathElement getPath() {
    final d =
        'M${cx - r},${cy}A$r,$r 0,0,0 ${cx + r},${cy}A$r,$r 0,0,0 ${cx - r},${cy}z';

    return PathElement(null, d, parent, null, transform: transform);
  }
}

class PolylineElement extends SvgElement implements PathConvertible {
  PolylineElement(this.points, SvgElement? parent, XmlElement element)
      : super(parent, element);

  factory PolylineElement.fromXmlElement(
      SvgElement? parent, XmlElement element) {
    final points = element.getAttribute('points')!;

    return PolylineElement(points, parent, element);
  }

  final String points;

  @override
  PathElement getPath() {
    final d = 'M${points}z';

    return PathElement(null, d, parent, null, transform: transform);
  }
}

class PolygonElement extends SvgElement implements PathConvertible {
  PolygonElement(this.points, SvgElement? parent, XmlElement element)
      : super(parent, element);

  factory PolygonElement.fromXmlElement(
      SvgElement? parent, XmlElement element) {
    final points = element.getAttribute('points')!;

    return PolygonElement(points, parent, element);
  }

  final String points;

  @override
  PathElement getPath() {
    final d = 'M${points}z';

    return PathElement(null, d, parent, null, transform: transform);
  }
}

class LineElement extends SvgElement implements PathConvertible {
  LineElement(this.p1, this.p2, SvgElement? parent, XmlElement element)
      : super(parent, element);

  factory LineElement.fromXmlElement(SvgElement? parent, XmlElement element) {
    final p1 = math.Point(
        element.getScalarAttribute('x1')!, element.getScalarAttribute('y1')!);

    final p2 = math.Point(
        element.getScalarAttribute('x2')!, element.getScalarAttribute('y2')!);

    return LineElement(p1, p2, parent, element);
  }

  /// Line width
  static const _kW = 1;

  final math.Point p1;
  final math.Point p2;

  num get x1 => p1.x;

  num get y1 => p1.y;

  num get x2 => p2.x;

  num get y2 => p2.y;

  @override
  PathElement getPath() {
    final d =
        'M$x1 $y1 ${x1 + _kW} ${y1 + _kW} ${x2 + _kW} ${y2 + _kW} $x2 $y2 z';

    return PathElement(null, d, parent, null, transform: transform);
  }
}
