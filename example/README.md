## Usage in flutter app

Located here: [example/flutter_usage/](example/flutter_usage/)

## Generate from cli

```dart
import 'dart:io';

import 'package:icon_font_generator/icon_font_generator.dart';

void main() {
  const fontFileName = 'my_icons.otf';
  const classFileName = 'my_icons.dart';

  // Input data
  final svgMap = {
    'account_icon': '''<svg viewBox="0 0 0 0"></svg>'''
  };

  // Generating font
  final svgToOtfResult = svgToOtf(
    svgMap: svgMap,
    fontName: 'My Icons',
  );

  // Writing font to a file
  writeToFile(fontFileName, svgToOtfResult.font);

  // Generating Flutter class
  final generatedClass = generateFlutterClass(
    glyphList: svgToOtfResult.glyphList,
    familyName: svgToOtfResult.font.familyName,
    className: 'MyIcons',
    fontFileName: fontFileName,
  );

  // Writing class content to a file
  File(classFileName).writeAsStringSync(generatedClass);
}
```