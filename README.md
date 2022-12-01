## Flutter Icon Font Generator

![Pub](https://img.shields.io/pub/v/icon_font_generator)

Convert all *.svg icons from dir to icon-font (.ttf) and generates flutter compatible dart class. 

Abstraction layer for NodeJs package `fantasticon`.

## Requirements
Node.JS v11+

## Install:

```
$ pub global activate icon_font_generator
```

## Params:
\* - required

- `--from` * - Input dir with svg's
- `--out-font` * - Output icon font path (to file, for example: lib/font.ttf)
- `--out-flutter` * - Output flutter icon class (to file, for example: lib/icons.dart)
- `--class-name` * - The class name is also the font name used in pubspec.yaml (as font name)
- `--symlinks-map` - Source map of symlinked icons, have to be a json map with this pattern: target -> source
- `--height` - Fixed font height value, defaults: 512
- `--descent` - Offset applied to the baseline, defaults: 240
- `--package` - Name of package for generated icon data ([See more](https://api.flutter.dev/flutter/widgets/IconData/fontPackage.html))
- `--indent` - Indent for generating dart file, for example: '   ', default: '  '
- `--normalize` - Normalize icons sizes, default: false
- `--yarn` - Usage yarn instead npm, default: false
- `--naming-strategy` - Icons name strategy: snake (yaru_icon) or camel (yaruIcon), default: snake

## Example
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
  const UiIcons._();

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
