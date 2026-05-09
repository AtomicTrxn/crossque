import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:crosscue/core/utils/result.dart';

/// Errors that can occur when downloading a Crosshare puzzle.
enum CrosshareDownloadError {
  /// No puzzle link matching today's date was found on the dailyminis page.
  notFound,

  /// A network request failed (timeout, HTTP error, no connection).
  networkError,
}

/// Downloads the Crosshare daily mini crossword as raw .puz bytes.
///
/// Two-step process:
///   1. GET https://crosshare.org/dailyminis — find today's puzzle ID by
///      matching the date slug in crossword links on the page.
///   2. GET https://crosshare.org/api/puz/{id} — fetch the .puz file.
///
/// No PDF fallback. If either step fails, returns [CrosshareDownloadError].
class CrosshareDownloader {
  CrosshareDownloader({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _dailyMinisUrl = 'https://crosshare.org/dailyminis';
  static const _puzApiBase = 'https://crosshare.org/api/puz';

  Future<Result<Uint8List, CrosshareDownloadError>> downloadToday() async {
    try {
      final id = await _findTodayPuzzleId();
      if (id == null) return const Err(CrosshareDownloadError.notFound);

      final response = await _dio.get<List<int>>(
        '$_puzApiBase/$id',
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode != 200 || response.data == null) {
        return const Err(CrosshareDownloadError.networkError);
      }
      return Ok(Uint8List.fromList(response.data!));
    } on DioException {
      return const Err(CrosshareDownloadError.networkError);
    } catch (_) {
      return const Err(CrosshareDownloadError.networkError);
    }
  }

  /// Fetches the dailyminis page and extracts today's puzzle ID.
  ///
  /// Crosshare puzzle links have the form:
  ///   /crosswords/{PUZZLE_ID}/daily-mini-crossword-{day}-{month}-{year}
  ///
  /// We construct the expected date slug and regex-match it against the HTML.
  Future<String?> _findTodayPuzzleId() async {
    try {
      final response = await _dio.get<String>(
        _dailyMinisUrl,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.statusCode != 200 || response.data == null) return null;

      final today = DateTime.now();
      final dateSlug = '${today.day}-${_monthName(today.month)}-${today.year}';

      // Match: /crosswords/{ID}/{slug-containing-dateSlug}
      // Use [^/\s]* to match URL path characters without quotes or spaces.
      final pattern = RegExp(
        r'/crosswords/([A-Za-z0-9_-]+)/[^/\s]*' + RegExp.escape(dateSlug),
      );
      final match = pattern.firstMatch(response.data!);
      return match?.group(1);
    } on DioException {
      return null;
    }
  }

  static String _monthName(int month) {
    const months = [
      '',
      'january',
      'february',
      'march',
      'april',
      'may',
      'june',
      'july',
      'august',
      'september',
      'october',
      'november',
      'december',
    ];
    return months[month];
  }
}
