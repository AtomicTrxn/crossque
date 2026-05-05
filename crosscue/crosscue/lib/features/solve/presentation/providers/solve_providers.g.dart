// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'solve_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(solveRepository)
final solveRepositoryProvider = SolveRepositoryProvider._();

final class SolveRepositoryProvider extends $FunctionalProvider<
    SolveRepositoryImpl,
    SolveRepositoryImpl,
    SolveRepositoryImpl> with $Provider<SolveRepositoryImpl> {
  SolveRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'solveRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$solveRepositoryHash();

  @$internal
  @override
  $ProviderElement<SolveRepositoryImpl> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SolveRepositoryImpl create(Ref ref) {
    return solveRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SolveRepositoryImpl value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SolveRepositoryImpl>(value),
    );
  }
}

String _$solveRepositoryHash() => r'd9f8277b714b0e07ebaf04435ded4529bedfb7d1';
