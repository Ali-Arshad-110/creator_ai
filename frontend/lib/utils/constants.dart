/// Application-wide constants.
class AppConstants {
  // Input constraints
  static const int maxContentLength = 5000;
  static const int minPasswordLength = 6;

  // Pagination
  static const int defaultPageSize = 20;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);

  // Score thresholds
  static const int highScoreThreshold = 7;
  static const int mediumScoreThreshold = 4;

  // API paths
  static const String analyzeEndpoint = '/analyze';
  static const String analysesEndpoint = '/analyses';
}
