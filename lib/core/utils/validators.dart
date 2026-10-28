import '../constants/app_strings.dart';

/// Form validators (BR01, BR02). Return `null` when the value is valid.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.emailRequired;
    if (!_email.hasMatch(text)) return AppStrings.emailInvalid;
    return null;
  }

  static String? displayName(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 2 || length > 50) return AppStrings.displayNameInvalid;
    return null;
  }

  /// BR04: 3-50 characters (uniqueness is checked by the repository).
  static String? channelName(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 3 || length > 50) return AppStrings.channelNameInvalid;
    return null;
  }

  /// BR06: title of 1-100 characters.
  static String? videoTitle(String? value) {
    final length = value?.trim().length ?? 0;
    if (length < 1 || length > 100) return AppStrings.titleInvalid;
    return null;
  }

  static String? password(String? value) {
    final length = value?.length ?? 0;
    if (length < 6 || length > 32) return AppStrings.passwordInvalid;
    return null;
  }
}
