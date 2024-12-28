import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String category;

  @HiveField(2)
  String comment;

  @HiveField(3)
  DateTime date;

  Expense({
    required this.amount,
    required this.category,
    required this.comment,
    required this.date,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      amount: json['amount'] as double,
      category: json['category'] as String,
      comment: json['comment'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}