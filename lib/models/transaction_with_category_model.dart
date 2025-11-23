import 'package:chainly/models/category_model.dart';
import 'package:chainly/models/transaction_model.dart';

class TransactionWithCategory {
  final Transaction transaction;
  final Category category;

  TransactionWithCategory(this.transaction, this.category);
}