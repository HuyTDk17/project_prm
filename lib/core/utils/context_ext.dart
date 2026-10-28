import 'package:flutter/material.dart';

extension SnackContext on BuildContext {
  /// Shows a short floating message and replaces the current one.
  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
