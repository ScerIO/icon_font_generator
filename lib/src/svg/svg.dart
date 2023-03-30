import 'dart:convert';
import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../utils/exception.dart';
import '../utils/svg.dart';
import 'element.dart';

/// SVG root element.
class Svg extends SvgElement {
  Svg(
    this.name,
    this.viewBox,
    this.elementList,
    XmlElement xmlElement,
    this.ratioX,
    this.ratioY,
    this.offset,
  ) : super(null, xmlElement);

  /// Parses SVG.
  ///
  /// If [ignoreShapes] is set to false, shapes (circle, rect, etc.) are converted into paths.
  /// Defaults to true.
  /// NOTE: Attributes like "fill" or "stroke" are ignored,
  /// which means only shape's outline will be used.
  ///
  /// Throws [XmlParserException] if XML parsing exception occurs.
  /// Throws [SvgParserException] on any problem related to SVG parsing.
  factory Svg.parse(String name, String xmlString, {bool? ignoreShapes}) {
    ignoreShapes ??= true;

    final xml = XmlDocument.parse(xmlString);
    final root = xml.rootElement;

    if (root.name.local != 'svg') {
      throw SvgParserException('Root element must be SVG');
    }

    final width = root.getDoubleAttribute('width');
    final height = root.getDoubleAttribute('height');

    final parsedVb = root
        .getAttribute('viewBox')
        ?.split(RegExp(r'[\s|,]'))
        .where((e) => e.isNotEmpty)
        .map(num.parse);
    final vb = [
      ...parsedVb ?? [0, 0, width, height],
    ];

    if ((width == 0 || height == 0) && parsedVb == null) {
      throw SvgParserException(
          'SVG must contain size (width, height) and/or viewBox attributes');
    }

    if (vb.isEmpty || vb.length > 4) {
      throw SvgParserException('viewBox must contain 1..4 parameters');
    }

    final fvb = [
      ...List.filled(4 - vb.length, 0),
      ...vb,
    ];

    final viewBox = math.Rectangle(fvb[0], fvb[1], fvb[2], fvb[3]);

    final parsedRatioX = root.getDoubleAttribute('ratioX', 1);
    final parsedRatioY = root.getDoubleAttribute('ratioY', 1);

    final parsedOffset = root.getIntAttribute('offset');

    final svg =
        Svg(name, viewBox, [], root, parsedRatioX, parsedRatioY, parsedOffset);

    final elementList = root.parseSvgElements(svg, ignoreShapes);
    svg.elementList.addAll(elementList);

    return svg;
  }

  final String name;
  final math.Rectangle viewBox;
  final List<SvgElement> elementList;
  final double ratioX;
  final double ratioY;
  final int offset;

  final Codec<String, String> _stringToBase64 = utf8.fuse(base64);

  String toBase64() => _stringToBase64
      .encode(xmlElement!.toXmlString(pretty: true, indent: '', newLine: ''));

  @override
  String toString() => '$name (${elementList.length} elements)';
}

extension XmlNodeUtils on XmlNode {
  double getDoubleAttribute(String name, [double defaultValue = 0]) =>
      double.tryParse(getAttribute(name) ?? '$defaultValue') ?? defaultValue;

  int getIntAttribute(String name, [int defaultValue = 0]) =>
      int.tryParse(getAttribute(name) ?? '$defaultValue') ?? defaultValue;
}

extension NumPretty on num {
  String toStringPretty([int? fractionDigits]) =>
      (fractionDigits != null ? toStringAsFixed(fractionDigits) : toString())
          .replaceFirst(RegExp(r'\.?0*$'), '');
}
