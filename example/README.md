# Example

File structire:
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
Generated to:
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

```
And also need add font to pubspec.yaml:
```yaml
...

flutter:
  fonts:
    - family: UiIcons
      fonts:
        - asset: lib/icon_font/ui_icons.ttf
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