## Flutter Icon Font Generator

![Pub](https://img.shields.io/pub/v/icon_font_generator)

Convert all *.svg icons from dir to icon-font (.ttf) and generates flutter compatible dart class. 

Abstraction layer for NodeJs package `icon-font-generator`

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
- `--height` - Fixed font height value, defaults: 512
- `--ascent` - Offset applied to the baseline, defaults: 240
- `--package` - Name of package for generated icon data ([See more](https://api.flutter.dev/flutter/widgets/IconData/fontPackage.html))
- `--indent` - Indent for generating dart file, for example: '   ', default: '  '
- `--mono` - Make font monospace, default: true
- `--normalize` - Normalize icons sizes, default: false

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

Still you can usage it with [DPM](https://github.com/rbcprolabs/dpm) (Dart Package Manager)

For example:
1. `$ pub global activate dpm`
2. `$ dpm add --dev icon_font_generator`
3. Next add script to pubspec.yaml:
```yaml
...
scripts:
  generate_icons: icon_font_generator 
    --from=icons 
    --class-name=UiIcons 
    --out-font=lib/icon_font/ui_icons.ttf 
    --out-flutter=lib/widgets/icons.dart
```
4. And always perform with the command: `dpm generate_icons`
