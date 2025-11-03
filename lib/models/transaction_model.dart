class Transaction {
  final int? id;
  final int walletId;
  final int? categoryId;
  final String type; // 'income' | 'expense' | 'transfer'
  final double amount;
  final String description;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.walletId,
    this.categoryId,
    required this.type,
    required this.amount,
    required this.description,
    this.note,
    required this.date,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      walletId: map['wallet_id'] as int,
      categoryId: map['category_id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wallet_id': walletId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Transaction copyWith({
    int? id,
    int? walletId,
    int? categoryId,
    String? type,
    double? amount,
    String? description,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  get comment => null;

  get currency => null;

  @override
  String toString() =>
      'Transaction{id: $id, walletId: $walletId, type: $type, amount: $amount, description: $description}';
}