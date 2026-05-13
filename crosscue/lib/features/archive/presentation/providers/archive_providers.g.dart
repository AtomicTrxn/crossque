// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton repository for the Archive feature.

@ProviderFor(archiveRepository)
final archiveRepositoryProvider = ArchiveRepositoryProvider._();

/// Singleton repository for the Archive feature.

final class ArchiveRepositoryProvider extends $FunctionalProvider<
    ArchiveRepository,
    ArchiveRepository,
    ArchiveRepository> with $Provider<ArchiveRepository> {
  /// Singleton repository for the Archive feature.
  ArchiveRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'archiveRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$archiveRepositoryHash();

  @$internal
  @override
  $ProviderElement<ArchiveRepository> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveRepository create(Ref ref) {
    return archiveRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveRepository>(value),
    );
  }
}

String _$archiveRepositoryHash() => r'bdb7747e7fb12f4a230ef450d0ce022de5bc0752';

/// All archive entries (puzzles + their latest session status), import-date desc.

@ProviderFor(archiveEntries)
final archiveEntriesProvider = ArchiveEntriesProvider._();

/// All archive entries (puzzles + their latest session status), import-date desc.

final class ArchiveEntriesProvider extends $FunctionalProvider<
        AsyncValue<List<ArchiveEntry>>,
        List<ArchiveEntry>,
        Stream<List<ArchiveEntry>>>
    with
        $FutureModifier<List<ArchiveEntry>>,
        $StreamProvider<List<ArchiveEntry>> {
  /// All archive entries (puzzles + their latest session status), import-date desc.
  ArchiveEntriesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'archiveEntriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$archiveEntriesHash();

  @$internal
  @override
  $StreamProviderElement<List<ArchiveEntry>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<ArchiveEntry>> create(Ref ref) {
    return archiveEntries(ref);
  }
}

String _$archiveEntriesHash() => r'543ad6e397de62f7b5368580a82be21ed958d5ae';
