import 'package:flutter/material.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is Map && error.containsKey('message')) {
      return error['message'];
    }
    return 'An unexpected error occurred';
  }
}
