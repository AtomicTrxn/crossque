// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(puzzleList)
final puzzleListProvider = PuzzleListProvider._();

final class PuzzleListProvider extends $FunctionalProvider<
        AsyncValue<List<PuzzleMetadata>>,
        List<PuzzleMetadata>,
        Stream<List<PuzzleMetadata>>>
    with
        $FutureModifier<List<PuzzleMetadata>>,
        $StreamProvider<List<PuzzleMetadata>> {
  PuzzleListProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'puzzleListProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$puzzleListHash();

  @$internal
  @override
  $StreamProviderElement<List<PuzzleMetadata>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<PuzzleMetadata>> create(Ref ref) {
    return puzzleList(ref);
  }
}

String _$puzzleListHash() => r'd1f50eec428c3100d22d9f237e762e13e591cccf';
