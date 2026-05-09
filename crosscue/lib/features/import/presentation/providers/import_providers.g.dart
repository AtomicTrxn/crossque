// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(importRepository)
final importRepositoryProvider = ImportRepositoryProvider._();

final class ImportRepositoryProvider extends $FunctionalProvider<
    ImportRepository,
    ImportRepository,
    ImportRepository> with $Provider<ImportRepository> {
  ImportRepositoryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'importRepositoryProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$importRepositoryHash();

  @$internal
  @override
  $ProviderElement<ImportRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ImportRepository create(Ref ref) {
    return importRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ImportRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ImportRepository>(value),
    );
  }
}

String _$importRepositoryHash() => r'a498a4c72975e8d4db20b59872feca4a758d4060';

@ProviderFor(crosshareDownloader)
final crosshareDownloaderProvider = CrosshareDownloaderProvider._();

final class CrosshareDownloaderProvider extends $FunctionalProvider<
    CrosshareDownloader,
    CrosshareDownloader,
    CrosshareDownloader> with $Provider<CrosshareDownloader> {
  CrosshareDownloaderProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'crosshareDownloaderProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$crosshareDownloaderHash();

  @$internal
  @override
  $ProviderElement<CrosshareDownloader> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CrosshareDownloader create(Ref ref) {
    return crosshareDownloader(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CrosshareDownloader value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CrosshareDownloader>(value),
    );
  }
}

String _$crosshareDownloaderHash() =>
    r'8507b5090552ef0ef6029bb8d097fe642bc425db';
