import 'package:googleapis/youtube/v3.dart' show DetailedApiRequestError;

/// Whether [error] is YouTube refusing a request because the day's API
/// quota is used up.
bool isQuotaExceeded(Object error) =>
    error is DetailedApiRequestError &&
    error.status == 403 &&
    (error.message?.contains('quota') == true ||
        error.errors.any(
          (e) =>
              e.reason == 'quotaExceeded' || e.reason == 'dailyLimitExceeded',
        ));
