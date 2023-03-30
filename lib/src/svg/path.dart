import 'package:vector_math/vector_math.dart';
import 'package:xml/xml.dart';

import '../utils/exception.dart';
import 'element.dart';

class PathElement extends SvgElement {
  PathElement(this.fillRule, this.data, SvgElement? parent, XmlElement? element,
      {Matrix3? transform})
      : super(parent, element, transform: transform);

  factory PathElement.fromXmlElement(SvgElement? parent, XmlElement element) {
    final dAttr = element.getAttribute('d');

    if (dAttr == null) {
      throw SvgParserException('Path element must contain "d" attribute');
    }

    final fillRule = element.getAttribute('fill-rule');

    return PathElement(fillRule, dAttr, parent, element);
  }

  final String? fillRule;
  final String data;
}
