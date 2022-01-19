const String base = '''
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/widgets.dart';

@immutable
class _%CLASS_NAME%Data extends IconData {
%INDENT%const _%CLASS_NAME%Data(int codePoint)
%INDENT%%INDENT%%INDENT%: super(
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%codePoint,
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%fontFamily: '%CLASS_NAME%',%PACKAGE%
%INDENT%%INDENT%%INDENT%%INDENT%);
}

@immutable
class %CLASS_NAME% {
%INDENT%const %CLASS_NAME%._();

%CONTENT%

%INDENT%static const values = <String, IconData>{
%VALUES_MAP%
%INDENT%};

%INDENT%static final names = <IconData, String>{
%NAMES_MAP%
%INDENT%};
}
''';

const String icon = '%INDENT%static const IconData %ICON_NAME% = '
    '_%CLASS_NAME%Data(0x%ICON_CODE%);';

const String package = '\n%INDENT%%INDENT%%INDENT%%INDENT%'
    '%INDENT%fontPackage: \'%PACKAGE_NAME%\',';

const String value = '''%INDENT%%INDENT%'%ICON_NAME%': %ICON_NAME%,''';

const String name = '''%INDENT%%INDENT%%ICON_NAME%: '%ICON_NAME%',''';
