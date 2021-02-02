import 'package:rational/rational.dart';
import 'package:rpncalc/operators.dart';
import 'package:rpncalc/rpn_stack.dart';
import 'package:rpncalc/stack_item.dart';
import 'package:test/test.dart';

void main() {
  group('editing current item', () {
    test('starts empty', () {
      final s = RpnStack();
      expect(s.isEmpty, true);
    });

    test('advancing when empty has no result', () {
      final s = RpnStack()..advance();
      expect(s.isEmpty, true);
    });

    test('characters are appended', () {
      final s = RpnStack()..appendCurrent('2')..appendCurrent('.')..appendCurrent('1');
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('2.1'));
    });

    test('characters can be removed', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..appendCurrent('.')
        ..appendCurrent('1')
        ..backspaceCurrent();
      expect(s.length, 1);
      expect(s.first.value, Rational.fromInt(2));
    });

    test('item is pushed to stack and copied on advance', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..appendCurrent('.')
        ..appendCurrent('1')
        ..advance();
      expect(s.length, 2);
      expect(s.first.value, Rational.parse('2.1'));
      expect(s.first.runtimeType, EditableItem);
    });
  });

  group('operations', () {
    test('percent works as unary operation', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..appendCurrent('0')
        ..percent();
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('0.2'));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('percent works as binary operation', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..appendCurrent('0')
        ..advance()
        ..appendCurrent('5')
        ..appendCurrent('0')
        ..percent();
      expect(s.length, 1);
      expect(s.first.value, Rational.fromInt(10));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('reverse sign works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..reverseSign();
      expect(s.length, 1);
      expect(s.first.value, Rational.fromInt(-2));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('inverting works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..inverse();
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('0.5'));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('addition works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3.2')
        ..applyBinaryOperation(BinaryOperator.add);
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('5.2'));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('subtraction works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3')
        ..applyBinaryOperation(BinaryOperator.subtract);
      expect(s.length, 1);
      expect(s.first.value, Rational.fromInt(-1));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('floating point math is correct', () {
      final s = RpnStack()
        ..appendCurrent('1.1')
        ..advance()
        ..appendCurrent('0.5')
        ..applyBinaryOperation(BinaryOperator.subtract);
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('0.6'));
    });

    test('multiplication works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3.2')
        ..applyBinaryOperation(BinaryOperator.multiply);
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('6.4'));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('division works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3.2')
        ..applyBinaryOperation(BinaryOperator.divide);
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('0.625'));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('exponent works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3.2')
        ..applyBinaryOperation(BinaryOperator.exponent);
      expect(s.length, 1);
      expect(s.first.value, Rational.parse('9.18958683997628'));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('irrational numbers work', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('0.5')
        ..applyBinaryOperation(BinaryOperator.exponent);
      expect(s.length, 1);
      expect(s.first.value.toStringAsPrecision(10), '1.414213562');
      expect(s.first.runtimeType, RealizedItem);
    });

    test('binary options use clone of item after advance', () {
      final s = RpnStack()
        ..appendCurrent('3')
        ..advance()
        ..applyBinaryOperation(BinaryOperator.multiply);
      expect(s.length, 1);
      expect(s.first.value, Rational.fromInt(9));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('binary options have no effect with only a single item in stack', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..backspaceCurrent()
        ..applyBinaryOperation(BinaryOperator.divide);
      expect(s.length, 1);
      expect(s.first.value, Rational.fromInt(2));
      expect(s.first.runtimeType, RealizedItem);
    });
  });

  group('stack manipulation', () {
    test('clearing current item works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..clearCurrent();
      expect(s.length, 2);
      expect(s.first.isEmpty, true);
      expect(s.first.runtimeType, EditableItem);
    });

    test('clearing all works', () {
      final s = RpnStack()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3')
        ..advance()
        ..clearAll();
      expect(s.length, 1);
      expect(s.first.isEmpty, true);
      expect(s.first.runtimeType, EditableItem);
    });

    test('swapping items works', () {
      final s = RpnStack()
        ..appendCurrent('1')
        ..advance()
        ..appendCurrent('2')
        ..swap();
      expect(s.length, 2);
      expect(s.first.value, Rational.one);
      expect(s[1].value, Rational.fromInt(2));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('rotating down works', () {
      final s = RpnStack()
        ..appendCurrent('1')
        ..advance()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3')
        ..rotateDown();
      expect(s.length, 3);
      expect(s.first.value, Rational.fromInt(2));
      expect(s[1].value, Rational.one);
      expect(s[2].value, Rational.fromInt(3));
      expect(s.first.runtimeType, RealizedItem);
    });

    test('rotating up works', () {
      final s = RpnStack()
        ..appendCurrent('1')
        ..advance()
        ..appendCurrent('2')
        ..advance()
        ..appendCurrent('3')
        ..rotateUp();
      expect(s.length, 3);
      expect(s.first.value, Rational.one);
      expect(s[1].value, Rational.fromInt(3));
      expect(s[2].value, Rational.fromInt(2));
      expect(s.first.runtimeType, RealizedItem);
    });
  });
}
