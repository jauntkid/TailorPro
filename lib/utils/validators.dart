import 'package:flutter/material.dart';

class Validators {
  static FormFieldValidator<String> required(String errorMessage) {
    return (value) {
      if (value == null || value.isEmpty) {
        return errorMessage;
      }
      return null;
    };
  }

  static FormFieldValidator<String> email() {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Email is optional
      }

      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
      return null;
    };
  }

  static FormFieldValidator<String> min(int minLength, [String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Let required validator handle this
      }

      if (value.length < minLength) {
        return errorMessage ?? 'Must be at least $minLength characters';
      }
      return null;
    };
  }

  static FormFieldValidator<String> max(int maxLength, [String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Let required validator handle this
      }

      if (value.length > maxLength) {
        return errorMessage ?? 'Must be at most $maxLength characters';
      }
      return null;
    };
  }

  static FormFieldValidator<String> phone() {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Let required validator handle this
      }

      final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
      if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\D'), ''))) {
        return 'Please enter a valid phone number';
      }
      return null;
    };
  }
}
