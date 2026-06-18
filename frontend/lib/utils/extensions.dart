import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// DateTime formatting extensions.
extension DateTimeFormatting on DateTime {
  String get formatted => DateFormat('MMM dd, yyyy').format(this);
  String get formattedWithTime => DateFormat('MMM dd, yyyy • hh:mm a').format(this);
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatted;
  }
}

/// BuildContext convenience extensions.
extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  bool get isDark => theme.brightness == Brightness.dark;
  MediaQueryData get media => MediaQuery.of(this);
  double get screenWidth => media.size.width;
  double get screenHeight => media.size.height;

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// String utility extensions.
extension StringExtensions on String {
  String get truncated =>
      length > 80 ? '${substring(0, 80)}...' : this;
}
