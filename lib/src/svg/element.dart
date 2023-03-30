import 'package:vector_math/vector_math.dart';
import 'package:xml/xml.dart';

import '../utils/svg.dart';
import 'path.dart';
import 'shapes.dart';
import 'unknown_element.dart';

abstract class SvgElement {
  SvgElement(this.parent, this.xmlElement, {Matrix3? transform})
      : transform = transform ?? xmlElement?.parseTransformMatrix();

  factory SvgElement.fromXmlElement(
      SvgElement? parent, XmlElement element, bool ignoreShapes) {
    switch (element.name.local) {
      case 'path':
        return PathElement.fromXmlElement(parent, element);
      case 'g':
        return GroupElement.fromXmlElement(parent, element, ignoreShapes);
      case 'rect':
        return RectElement.fromXmlElement(parent, element);
      case 'circle':
        return CircleElement.fromXmlElement(parent, element);
      case 'polyline':
        return PolylineElement.fromXmlElement(parent, element);
      case 'polygon':
        return PolygonElement.fromXmlElement(parent, element);
      case 'line':
        return LineElement.fromXmlElement(parent, element);
    }

    return UnknownElement(parent, element);
  }

  final XmlElement? xmlElement;
  Matrix3? transform;
  SvgElement? parent;

  /// Traverses parent elements and calculates result transform matrix.
  ///
  /// Returns result transform matrix or null, if there are no transforms.
  Matrix3? getResultTransformMatrix() {
    final transform = Matrix3.identity();
    SvgElement? element = this;

    while (element != null) {
      final elementTransform = element.transform;

      if (elementTransform != null) {
        transform.multiply(elementTransform);
      }

      element = element.parent;
    }

    return transform.isIdentity() ? null : transform;
  }
}

class GroupElement extends SvgElement {
  GroupElement(this.elementList, SvgElement? parent, XmlElement element)
      : super(parent, element);

  factory GroupElement.fromXmlElement(
    SvgElement? parent,
    XmlElement element,
    bool ignoreShapes,
  ) {
    final g = GroupElement(
      [],
      parent,
      element,
    );

    final children = element.parseSvgElements(g, ignoreShapes);
    g.elementList.addAll(children);

    return g;
  }

  final List<SvgElement> elementList;

  /// Applies group's transform on every child element
  /// and sets group's transform to null
  void applyTransformOnChildren() {
    if (transform == null) {
      return;
    }

    for (final c in elementList) {
      c.transform ??= Matrix3.identity();
      c.transform!.multiply(transform!);
    }

    transform = null;
  }
}
