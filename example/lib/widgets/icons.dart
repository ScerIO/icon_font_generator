import 'package:flutter/widgets.dart';

@immutable
class UiIconsData extends IconData {
  const UiIconsData(int codePoint)
      : super(
          codePoint,
          fontFamily: 'UiIcons',
        );
}

@immutable
class UiIcons {
  UiIcons._();

  // Generated code: do not hand-edit.
  static const IconData account = UiIconsData(0xe000);

  static const IconData arrowLeft = UiIconsData(0xe001);

  static const IconData arrowRight = UiIconsData(0xe002);

  static const IconData collection = UiIconsData(0xe003);
}
