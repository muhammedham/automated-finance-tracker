class TransactionModel {
  final int? id;
  final int accountId;
  final int categoryId;
  final int amount; // Stored in minor units (e.g., Kurush)
  final DateTime date;
  final String? receiver;
  final String? note;
  final bool isAutomated;

  TransactionModel({
    this.id,
    required this.accountId,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.receiver,
    this.note,
    this.isAutomated = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'receiver': receiver,
      'note': note,
      'is_automated': isAutomated ? 1 : 0,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int,
      accountId: map['account_id'] as int,
      categoryId: map['category_id'] as int,
      amount: map['amount'] as int,
      date: DateTime.parse(map['date'] as String),
      receiver: map['receiver'] as String?,
      note: map['note'] as String?,
      isAutomated: (map['is_automated'] as int) == 1,
    );
  }
}