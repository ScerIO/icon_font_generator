const String base = '''
import 'package:flutter/widgets.dart';

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: constant_identifier_names
@immutable
class _%CLASS_NAME%Data extends IconData {
%INDENT%const _%CLASS_NAME%Data(int codePoint, this.name)
%INDENT%%INDENT%%INDENT%: super(
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%codePoint,
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%fontFamily: '%CLASS_NAME%',%PACKAGE%
%INDENT%%INDENT%%INDENT%%INDENT%);

%INDENT%final String name;
}

@immutable
class %CLASS_NAME% {
%INDENT%const %CLASS_NAME%._();

%CONTENT%

%INDENT%static const all = <String, _%CLASS_NAME%Data>{
%VALUES_MAP%
%INDENT%};
}
''';

const String icon = '%INDENT%static const %ICON_NAME% = '
    '_%CLASS_NAME%Data(0x%ICON_CODE%, \'%ICON_NAME%\');';

const String package = '\n%INDENT%%INDENT%%INDENT%%INDENT%'
    '%INDENT%fontPackage: \'%PACKAGE_NAME%\',';

const String value = '''%INDENT%%INDENT%'%ICON_NAME%': %ICON_NAME%,''';
