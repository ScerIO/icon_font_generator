const String base = '''
import 'package:flutter/widgets.dart';

@immutable
class %CLASS_NAME%Data extends IconData {
%INDENT%const %CLASS_NAME%Data(int codePoint)
%INDENT%%INDENT%%INDENT%: super(
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%codePoint,
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%fontFamily: '%CLASS_NAME%',%PACKAGE%
%INDENT%%INDENT%%INDENT%%INDENT%);
}

@immutable
class %CLASS_NAME% {
%INDENT%%CLASS_NAME%._();

%INDENT%// Generated code: do not hand-edit.
%CONTENT%
}
''';

const String icon = '%INDENT%static const IconData %ICON_NAME% = '
    '%CLASS_NAME%Data(0x%ICON_CODE%);';

const String package = '\n%INDENT%%INDENT%%INDENT%%INDENT%'
    '%INDENT%fontPackage: \'%PACKAGE_NAME%\',';
