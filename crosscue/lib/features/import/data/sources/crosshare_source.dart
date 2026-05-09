import 'package:crosscue/core/domain/models/enums.dart';
import 'package:crosscue/features/import/domain/repositories/puzzle_source.dart';

/// Crosshare daily mini crossword source.
///
/// Crosshare is an open-source (AGPL-3.0) community crossword platform.
/// Single daily puzzle download is within the spirit of the platform.
/// No ToS or robots.txt restrictions found; no auth required.
/// Attribution to crosshare.org is required per the platform's license.
class CrosshareSource implements PuzzleSource {
  const CrosshareSource();

  static const homepage = 'https://crosshare.org';
  static const githubUrl = 'https://github.com/crosshare-org/crosshare';

  @override
  String get id => 'crosshare_daily_mini';

  @override
  String get displayName => 'Crosshare Daily Mini';

  @override
  LicenseStatus get licenseStatus => LicenseStatus.openLicense;

  @override
  String? get licenseUrl => githubUrl;

  @override
  String? get permissionContact => homepage;

  @override
  String get cachePolicy =>
      'Downloaded .puz bytes are parsed into app storage; raw bytes are not retained.';

  @override
  String? get lastLegalReviewAt => '2026-05-09';

  @override
  String? get reviewNotes =>
      'AGPL-3.0 open source. Single daily .puz download via public API. '
      'No ToS restrictions found. Attribution to crosshare.org required.';

  @override
  bool get enabled => true;

  @override
  bool get attributionRequired => true;

  @override
  bool get commercialUseAllowed => false;

  @override
  bool get rawPayloadRetention => false;
}
