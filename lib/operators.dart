import 'dart:math' as math;

typedef BinaryOperation = num Function(num a, num b);

enum BinaryOperator { add, subtract, multiply, divide, exponent }

Map<BinaryOperator, BinaryOperation> operations = <BinaryOperator, BinaryOperation>{
  BinaryOperator.add: (a, b) => a + b,
  BinaryOperator.subtract: (a, b) => a - b,
  BinaryOperator.multiply: (a, b) => a * b,
  BinaryOperator.divide: (a, b) => a / b,
  BinaryOperator.exponent: math.pow,
};
