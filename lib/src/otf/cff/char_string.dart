// ignore_for_file: invariant_booleans

import 'dart:collection';
import 'dart:typed_data';

import '../../common/codable/binary.dart';
import '../../utils/otf.dart';
import '../debugger.dart';
import 'char_string_operator.dart';
import 'operand.dart';
import 'operator.dart';

class CharStringOperand extends CFFOperand {
  CharStringOperand(super.value, [super.size]);

  factory CharStringOperand.fromByteData(
      ByteData byteData, int offset, int b0) {
    if (b0 == 255) {
      final value = byteData.getUint32(0);
      return CharStringOperand(value / 0x10000, 5);
    } else {
      final operand = CFFOperand.fromByteData(byteData, offset, b0);
      return CharStringOperand(operand.value, operand.size);
    }
  }

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    if (value is double) {
      byteData
        ..setUint8(offset++, 255)
        ..setUint32(offset, (value! * 0x10000).round().toInt());
      offset += 4;
    } else {
      super.encodeToBinary(byteData);
    }
  }

  @override
  int get size {
    if (value is double) {
      return 5;
    } else {
      return super.size;
    }
  }
}

class CharStringCommand implements BinaryCodable {
  CharStringCommand(this.operator, this.operandList)
      : assert(operator.context == CFFOperatorContext.charString,
            "Operator's context must be CharString");

  factory CharStringCommand.hmoveto(int dx) {
    return CharStringCommand(hmoveto, _getOperandList([dx]));
  }

  factory CharStringCommand.vmoveto(int dy) {
    return CharStringCommand(vmoveto, _getOperandList([dy]));
  }

  factory CharStringCommand.rmoveto(int dx, int dy) {
    return CharStringCommand(rmoveto, _getOperandList([dx, dy]));
  }

  factory CharStringCommand.moveto(int dx, int dy) {
    if (dx == 0) {
      return CharStringCommand.vmoveto(dy);
    } else if (dy == 0) {
      return CharStringCommand.hmoveto(dx);
    }

    return CharStringCommand.rmoveto(dx, dy);
  }

  factory CharStringCommand.hlineto(int dx) {
    return CharStringCommand(hlineto, _getOperandList([dx]));
  }

  factory CharStringCommand.vlineto(int dy) {
    return CharStringCommand(vlineto, _getOperandList([dy]));
  }

  factory CharStringCommand.rlineto(List<int> dlist) {
    if (dlist.length.isOdd || dlist.length < 2) {
      throw ArgumentError('|- {dxa dya}+ rlineto (5) |-');
    }

    return CharStringCommand(rlineto, _getOperandList(dlist));
  }

  factory CharStringCommand.lineto(int dx, int dy) {
    if (dx == 0) {
      return CharStringCommand.vlineto(dy);
    } else if (dy == 0) {
      return CharStringCommand.hlineto(dx);
    }

    return CharStringCommand.rlineto([dx, dy]);
  }

  factory CharStringCommand.hhcurveto(List<int> dlist) {
    if (dlist.length < 4 || (dlist.length % 4 != 0 && dlist.length % 4 != 1)) {
      throw ArgumentError('|- dy1? {dxa dxb dyb dxc}+ hhcurveto (27) |-');
    }

    return CharStringCommand(hhcurveto, _getOperandList(dlist));
  }

  factory CharStringCommand.vvcurveto(List<int> dlist) {
    if (dlist.length < 4 || (dlist.length % 4 != 0 && dlist.length % 4 != 1)) {
      throw ArgumentError('|- dx1? {dya dxb dyb dyc}+ vvcurveto (26) |-');
    }

    return CharStringCommand(vvcurveto, _getOperandList(dlist));
  }

  factory CharStringCommand.rrcurveto(List<int> dlist) {
    if (dlist.length < 6 || dlist.length % 6 != 0) {
      throw ArgumentError('|- {dxa dya dxb dyb dxc dyc}+ rrcurveto (8) |-');
    }

    return CharStringCommand(rrcurveto, _getOperandList(dlist));
  }

  factory CharStringCommand.curveto(List<int> dlist) {
    if (dlist.length != 6) {
      throw ArgumentError('List length must be equal 6');
    }

    if (dlist[4] == 0) {
      dlist.removeAt(4);
      final dx = dlist.removeAt(0);

      if (dx != 0) {
        dlist.insert(0, dx);
      }

      return CharStringCommand.vvcurveto(dlist);
    } else if (dlist[5] == 0) {
      dlist.removeAt(5);
      final dy = dlist.removeAt(1);

      if (dy != 0) {
        dlist.insert(0, dy);
      }

      return CharStringCommand.hhcurveto(dlist);
    }

    return CharStringCommand(rrcurveto, _getOperandList(dlist));
  }

  final CFFOperator operator;
  final List<CharStringOperand> operandList;

  static List<CharStringOperand> _getOperandList(List<num> operandValues) {
    return operandValues.map(CharStringOperand.new).toList();
  }

  CharStringCommand copy() => CharStringCommand(operator, [...operandList]);

  @override
  String toString() {
    var operandListString = operandList.map((e) => e.toString()).join(', ');

    if (operandListString.length > 10) {
      operandListString = '${operandListString.substring(0, 10)}...';
    }

    return '$operator [$operandListString]';
  }

  @override
  void encodeToBinary(ByteData byteData) {
    var offset = 0;

    for (final operand in operandList) {
      final operandSize = operand.size;
      operand.encodeToBinary(byteData.sublistView(offset, operandSize));
      offset += operandSize;
    }

    operator.encodeToBinary(byteData.sublistView(offset, operator.size));
  }

  @override
  int get size => operator.size + operandList.fold<int>(0, (p, e) => e.size);
}

/// A very basic implementation of the CFF2 CharString interpreter.
/// Doesn't support hinting, subroutines, blending.
/// Doesn't respect interpreter implementation limits.
class CharStringInterpreter {
  CharStringInterpreter(this.isCFF1);

  final bool isCFF1;

  final _commandList = <CharStringCommand>[];
  final Queue<num> _stack = Queue();

  int getSubrBias(int length) {
    if (length < 1240) {
      return 107;
    } else if (length < 33900) {
      return 1131;
    } else {
      return 32768;
    }
  }

  void _pushCommand(Iterable<num?> operandValues, int opB0, [int? opB1]) {
    final command = CharStringCommand(
        CFFOperator(CFFOperatorContext.charString, opB0, opB1),
        operandValues.map(CharStringOperand.new).toList());

    _commandList.add(command);
  }

  List<CharStringCommand> readCommands(ByteData byteData) {
    _stack.clear();
    _commandList.clear();

    var offset = 0;
    final end = byteData.lengthInBytes;

    while (offset < end) {
      var op = byteData.getUint8(offset++);

      if (op == 28 || op >= 32) {
        final operandByteData = byteData.sublistView(offset);
        final operand = CharStringOperand.fromByteData(operandByteData, 0, op);
        _stack.add(operand.value!);
      } else {
        switch (op) {
          case 1: // hstem
          case 3: // vstem
          case 18: // hstemhm
          case 23: // vstemhm
            _stack.clear();
            debugUnsupportedFeature('CFF hinting not supported');
            break;

          case 4: // vmoveto
            final dy = _stack.removeFirstOrZero();
            _pushCommand([dy], op);
            break;

          case 5: // rlineto
            final arguments = <num?>[];

            while (_stack.length >= 2) {
              final dx = _stack.removeFirstOrZero();
              final dy = _stack.removeFirstOrZero();

              arguments.addAll([dx, dy]);
            }

            _pushCommand(arguments, op);
            break;

          case 6: // hlineto
          case 7: // vlineto
            final arguments = <num?>[];
            var isX = op == 6;

            while (_stack.isNotEmpty) {
              if (isX) {
                final dx = _stack.removeFirstOrZero();
                arguments.add(dx);
              } else {
                final dy = _stack.removeFirstOrZero();
                arguments.add(dy);
              }

              isX = !isX;
            }

            _pushCommand(arguments, op);
            break;

          case 8: // rrcurveto
            final arguments = <num?>[];

            while (_stack.length >= 6) {
              final dxc1 = _stack.removeFirstOrZero();
              final dyc1 = _stack.removeFirstOrZero();
              final dxc2 = _stack.removeFirstOrZero();
              final dyc2 = _stack.removeFirstOrZero();
              final dx = _stack.removeFirstOrZero();
              final dy = _stack.removeFirstOrZero();

              arguments.addAll([dxc1, dyc1, dxc2, dyc2, dx, dy]);
            }

            _pushCommand(arguments, op);
            break;

          case 10: // callsubr
          case 29: // callgsubr
            _stack.clear();
            debugUnsupportedFeature('CFF subrs not supported');
            break;

          case 16:
            {
              // blend
              _stack.clear();
              debugUnsupportedFeature('CFF blending not supported');
              break;
            }

          case 19: // hintmask
          case 20: // cntrmask
            _stack.clear();
            debugUnsupportedFeature('CFF hinting not supported');
            break;

          case 21: // rmoveto
            final dx = _stack.removeFirstOrZero();
            final dy = _stack.removeFirstOrZero();

            _pushCommand([dx, dy], op);
            break;

          case 22: // hmoveto
            final dx = _stack.removeFirstOrZero();

            _pushCommand([dx], op);
            break;

          case 24: // rcurveline
            final arguments = <num?>[];

            while (_stack.length >= 8) {
              final dxc1 = _stack.removeFirstOrZero();
              final dyc1 = _stack.removeFirstOrZero();
              final dxc2 = _stack.removeFirstOrZero();
              final dyc2 = _stack.removeFirstOrZero();
              final dx = _stack.removeFirstOrZero();
              final dy = _stack.removeFirstOrZero();

              arguments.addAll([dxc1, dyc1, dxc2, dyc2, dx, dy]);
            }

            final dx = _stack.removeFirstOrZero();
            final dy = _stack.removeFirstOrZero();

            _pushCommand([...arguments, dx, dy], op);
            break;

          case 25: // rlinecurve
            final arguments = <num?>[];

            while (_stack.length >= 8) {
              final dx = _stack.removeFirstOrZero();
              final dy = _stack.removeFirstOrZero();

              arguments.addAll([dx, dy]);
            }

            final dxc1 = _stack.removeFirstOrZero();
            final dyc1 = _stack.removeFirstOrZero();
            final dxc2 = _stack.removeFirstOrZero();
            final dyc2 = _stack.removeFirstOrZero();
            final dx = _stack.removeFirstOrZero();
            final dy = _stack.removeFirstOrZero();

            _pushCommand([...arguments, dxc1, dyc1, dxc2, dyc2, dx, dy], op);
            break;

          case 26: // vvcurveto
            final arguments = <num?>[];

            if (_stack.length.isOdd) {
              final dx = _stack.removeFirstOrZero();

              arguments.add(dx);
            }

            while (_stack.length >= 4) {
              final dyc1 = _stack.removeFirstOrZero();
              final dxc2 = _stack.removeFirstOrZero();
              final dyc2 = _stack.removeFirstOrZero();
              final dy = _stack.removeFirstOrZero();

              arguments.addAll([dyc1, dxc2, dyc2, dy]);
            }

            _pushCommand(arguments, op);
            break;

          case 27: // hhcurveto
            final arguments = <num?>[];

            if (_stack.length.isOdd) {
              final dy = _stack.removeFirstOrZero();

              arguments.add(dy);
            }

            while (_stack.length >= 4) {
              final dxc1 = _stack.removeFirstOrZero();
              final dxc2 = _stack.removeFirstOrZero();
              final dyc2 = _stack.removeFirstOrZero();
              final dx = _stack.removeFirstOrZero();

              arguments.addAll([dxc1, dxc2, dyc2, dx]);
            }

            _pushCommand(arguments, op);
            break;

          case 30: // vhcurveto
          case 31: // hvcurveto
            var isX = op == 31;
            final arguments = <num?>[];

            while (_stack.length >= 4) {
              if (isX) {
                final dxc1 = _stack.removeFirstOrZero();
                final dxc2 = _stack.removeFirstOrZero();
                final dyc2 = _stack.removeFirstOrZero();
                final dy = _stack.removeFirstOrZero();
                final dx =
                    _stack.length == 1 ? _stack.removeFirstOrZero() : null;

                arguments.addAll([dxc1, dxc2, dyc2, dy, if (dx != null) dx]);
              } else {
                final dyc1 = _stack.removeFirstOrZero();
                final dxc2 = _stack.removeFirstOrZero();
                final dyc2 = _stack.removeFirstOrZero();
                final dx = _stack.removeFirstOrZero();
                final dy =
                    _stack.length == 1 ? _stack.removeFirstOrZero() : null;

                arguments.addAll([dyc1, dxc2, dyc2, dx, if (dy != null) dy]);
              }

              isX = !isX;
            }

            _pushCommand(arguments, op);
            break;
          case 12:
            {
              op = byteData.getUint8(offset++);

              switch (op) {
                case 34: // hflex
                  _pushCommand(_stack.toList().sublist(0, 7), 12, op);
                  break;
                case 35: // flex
                  _pushCommand(_stack.toList().sublist(0, 13), 12, op);
                  break;
                case 36: // hflex1
                  _pushCommand(_stack.toList().sublist(0, 9), 12, op);
                  break;
                case 37: // flex1
                  _pushCommand(_stack.toList().sublist(0, 11), 12, op);
                  break;
                default:
                  debugUnsupportedFeature(
                      'Unknown charString op: 12 $op');
                  _stack.clear();
              }

              break;
            }

          default:
            debugUnsupportedFeature('Unknown charString op: $op');
            _stack.clear();
        }
      }
    }

    return [..._commandList];
  }

  ByteData writeCommands(
    List<CharStringCommand> commandList, {
    int? glyphWidth,
  }) {
    final list = <int>[];

    void encodeAndPush(BinaryEncodable encodable) {
      final byteData = ByteData(encodable.size);
      encodable.encodeToBinary(byteData);
      list.addAll(byteData.buffer.asUint8List());
    }

    // CFF1 glyphs contain width value as a first operand
    if (isCFF1 && glyphWidth != null) {
      encodeAndPush(CFFOperand.fromValue(glyphWidth));
    }

    for (final command in commandList) {
      command.operandList.forEach(encodeAndPush);
      encodeAndPush(command.operator);
    }

    return ByteData.sublistView(Uint8List.fromList(list));
  }
}

class CharStringInterpreterLimits {
  factory CharStringInterpreterLimits(bool isCFF1) => isCFF1
      ? const CharStringInterpreterLimits._cff1()
      : const CharStringInterpreterLimits._cff2();

  const CharStringInterpreterLimits._cff1() : argumentStackLimit = 48;

  const CharStringInterpreterLimits._cff2() : argumentStackLimit = 513;

  final int argumentStackLimit;
}

extension _QueueExt<T> on Queue<T> {
  T? removeFirstOrZero() {
    if (isEmpty) {
      if (T == num) {
        return 0 as T;
      } else {
        return null;
      }
    }

    return removeFirst();
  }
}
