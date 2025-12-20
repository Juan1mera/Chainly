import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chainly/data/repositories/stats_repository.dart';
import 'package:chainly/domain/providers/transaction_provider.dart';
import 'package:chainly/domain/providers/wallet_provider.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(
    db: ref.watch(localDatabaseProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
  );
});
