import 'dart:collection';

import 'operator.dart';

// CharString operators
const hstem = CFFOperator(CFFOperatorContext.charString, 1);
const vstem = CFFOperator(CFFOperatorContext.charString, 3);
const vmoveto = CFFOperator(CFFOperatorContext.charString, 4);
const rlineto = CFFOperator(CFFOperatorContext.charString, 5);
const hlineto = CFFOperator(CFFOperatorContext.charString, 6);
const vlineto = CFFOperator(CFFOperatorContext.charString, 7);
const rrcurveto = CFFOperator(CFFOperatorContext.charString, 8);
const callsubr = CFFOperator(CFFOperatorContext.charString, 10);
const escape = CFFOperator(CFFOperatorContext.charString, 12);
const vsindex = CFFOperator(CFFOperatorContext.charString, 15);
const blend = CFFOperator(CFFOperatorContext.charString, 16);
const hstemhm = CFFOperator(CFFOperatorContext.charString, 18);
const hintmask = CFFOperator(CFFOperatorContext.charString, 19);
const cntrmask = CFFOperator(CFFOperatorContext.charString, 20);
const rmoveto = CFFOperator(CFFOperatorContext.charString, 21);
const hmoveto = CFFOperator(CFFOperatorContext.charString, 22);
const vstemhm = CFFOperator(CFFOperatorContext.charString, 23);
const rcurveline = CFFOperator(CFFOperatorContext.charString, 24);
const rlinecurve = CFFOperator(CFFOperatorContext.charString, 25);
const vvcurveto = CFFOperator(CFFOperatorContext.charString, 26);
const hhcurveto = CFFOperator(CFFOperatorContext.charString, 27);
const callgsubr = CFFOperator(CFFOperatorContext.charString, 29);
const vhcurveto = CFFOperator(CFFOperatorContext.charString, 30);
const hvcurveto = CFFOperator(CFFOperatorContext.charString, 31);

const hflex = CFFOperator(CFFOperatorContext.charString, 12, 34);
const flex = CFFOperator(CFFOperatorContext.charString, 12, 35);
const hflex1 = CFFOperator(CFFOperatorContext.charString, 12, 36);
const flex1 = CFFOperator(CFFOperatorContext.charString, 12, 37);

/// CFF1 endchar
const endchar = CFFOperator(CFFOperatorContext.charString, 14);

final Map<CFFOperator, String> charStringOperatorNames = UnmodifiableMapView({
  vstem: 'vstem',
  vmoveto: 'vmoveto',
  rlineto: 'rlineto',
  hlineto: 'hlineto',
  vlineto: 'vlineto',
  rrcurveto: 'rrcurveto',
  callsubr: 'callsubr',
  escape: 'escape',
  vsindex: 'vsindex',
  blend: 'blend',
  hstemhm: 'hstemhm',
  hintmask: 'hintmask',
  cntrmask: 'cntrmask',
  rmoveto: 'rmoveto',
  hmoveto: 'hmoveto',
  vstemhm: 'vstemhm',
  rcurveline: 'rcurveline',
  rlinecurve: 'rlinecurve',
  vvcurveto: 'vvcurveto',
  hhcurveto: 'hhcurveto',
  callgsubr: 'callgsubr',
  vhcurveto: 'vhcurveto',
  hvcurveto: 'hvcurveto',
  hflex: 'hflex',
  flex: 'flex',
  hflex1: 'hflex1',
  flex1: 'flex1',
  endchar: 'endchar',
});
