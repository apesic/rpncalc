import 'dart:math' as math;

import 'package:rational/rational.dart';

typedef BinaryOperation = Rational Function(Rational a, Rational b);

enum BinaryOperator { add, subtract, multiply, divide, exponent }

Map<BinaryOperator, BinaryOperation> operations = <BinaryOperator, BinaryOperation>{
  BinaryOperator.add: (a, b) => a + b,
  BinaryOperator.subtract: (a, b) => a - b,
  BinaryOperator.multiply: (a, b) => a * b,
  BinaryOperator.divide: (a, b) => a / b,
  BinaryOperator.exponent: (a, b) {
    // Rational only supports positive integer exponents.
    if (b.scale == 0 && !b.isNegative) {
      return a.pow(b.toInt());
    }
    final res = math.pow(a.toDouble(), b.toDouble());
    return Rational.parse(res.toString());
  },
};
