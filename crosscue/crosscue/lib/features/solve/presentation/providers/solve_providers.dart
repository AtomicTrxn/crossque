import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/solve_repository_impl.dart';

part 'solve_providers.g.dart';

@Riverpod(keepAlive: true)
SolveRepositoryImpl solveRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SolveRepositoryImpl(dao: db.solveSessionDao);
}
