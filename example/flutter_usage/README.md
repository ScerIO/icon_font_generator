# Example

File structure:
```
project
└───icons
│   │   account.svg
│   │   arrow_left.svg
│   │   arrow_right.svg
│   │   collection.svg
│   
└───lib
│   │   icon_font
│   │   widgets
```
Run command:
```
$ icon_font_generator --from=icons --class-name=UiIcons --out-font=lib/icon_font/ui_icons.ttf --out-flutter=lib/widgets/icons.dart
```
Generates:
```
project
└───icons
│   │   account.svg
│   │   arrow_left.svg
│   │   arrow_right.svg
│   │   collection.svg
│   
└───lib
│   └───widgets
│   |   │   icons.dart
│   │
│   └───icon_font
│       │   ui_icons.ttf
```
Generated icons.dart:
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/widgets.dart';

@immutable
class _UiIconsData extends IconData {
  const UiIconsData(int codePoint)
      : super(
          codePoint,
          fontFamily: 'UiIcons',
        );
}

@immutable
class UiIcons {
  UiIcons._();

  static const IconData account = _UiIconsData(0xe000);
  static const IconData arrowLeft = _UiIconsData(0xe001);
  static const IconData arrowRight = _UiIconsData(0xe002);
  static const IconData collection = _UiIconsData(0xe003);
}
```
And also need add font to pubspec.yaml:
```yaml
...

flutter:
  fonts:
    - family: UiIcons
      fonts:
        - asset: lib/src/icon_font/ui_icons.ttf
```
