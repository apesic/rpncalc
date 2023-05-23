import 'package:statistics/statistics.dart';

typedef BinaryOperation = DynamicNumber Function(DynamicNumber a, DynamicNumber b);

enum BinaryOperator { add, subtract, multiply, divide, exponent }

Map<BinaryOperator, BinaryOperation> operations = <BinaryOperator, BinaryOperation>{
  BinaryOperator.add: (a, b) => a + b as DynamicNumber,
  BinaryOperator.subtract: (a, b) => a - b as DynamicNumber,
  BinaryOperator.multiply: (a, b) => a * b as DynamicNumber,
  BinaryOperator.divide: (a, b) => a / b,
  BinaryOperator.exponent: (a, b) => a.power(b) as DynamicNumber,
};
