import 'package:flutter_cc_evs/models/user_model.dart';

class ValidationService {
  // Personal Details Validations
  static String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    if (value.length < 2) {
      return 'First name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return 'First name can only contain letters';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    if (value.length < 2) {
      return 'Last name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return 'Last name can only contain letters';
    }
    return null;
  }

  static String? validateIdentificationNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'SA ID/Passport number is required';
    }
    if (value.length < 6) {
      return 'Invalid identification number';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    final phoneRegex = RegExp(r'^(\+27|0)[6-8][0-9]{8}$');
    final cleanedPhone = value.replaceAll(RegExp(r'\s+'), '');
    
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      return 'Please enter a valid South African phone number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase and numbers';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Employee Details Validations
  static String? validateEmployeeNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee number is required';
    }
    if (value.length < 3) {
      return 'Employee number must be at least 3 characters';
    }
    return null;
  }

  static String? validateDepartment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Department is required';
    }
    if (value.length < 2) {
      return 'Department must be at least 2 characters';
    }
    return null;
  }

  static String? validateLocation(LocationType? location) {
    if (location == null) {
      return 'Please select a location type';
    }
    return null;
  }

  static String? validateSite(String? value, LocationType? location) {
    if (location == LocationType.site && (value == null || value.isEmpty)) {
      return 'Site is required for site location';
    }
    if (value != null && value.isNotEmpty && value.length < 2) {
      return 'Site must be at least 2 characters';
    }
    return null;
  }

  static String? validateOffice(String? value, LocationType? location) {
    if (location == LocationType.office && (value == null || value.isEmpty)) {
      return 'Office is required for office location';
    }
    if (value != null && value.isNotEmpty && value.length < 2) {
      return 'Office must be at least 2 characters';
    }
    return null;
  }

  // ADD THIS METHOD: Enhanced email validation that can be used for real-time checking
  static String? validateEmailWithAsync(String? value) {
    final basicValidation = validateEmail(value);
    if (basicValidation != null) return basicValidation;
    
    // No uniqueness check here - that happens in ViewModel
    return null;
  }
}