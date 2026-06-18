/// Input validators used across forms.
class Validators {
  static final RegExp _emailRegex =
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static final RegExp _instagramUrlRegex =
      RegExp(r'https?://(www\.)?instagram\.com/(reel|p)/[\w-]+', caseSensitive: false);

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  static String? instagramUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please paste an Instagram Reel URL.';
    }
    if (!_instagramUrlRegex.hasMatch(value.trim())) {
      return 'Enter a valid Instagram Reel URL.';
    }
    return null;
  }

  static String? notEmpty(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }
}
