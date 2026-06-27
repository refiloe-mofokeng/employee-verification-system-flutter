import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatePersistenceService {
  // Personal Details Keys
  static const String _firstNameKey = 'signup_firstName';
  static const String _lastNameKey = 'signup_lastName';
  static const String _idNumberKey = 'signup_idNumber';
  static const String _phoneKey = 'signup_phone';
  static const String _emailKey = 'signup_email';

  // Employee Details Keys
  static const String _employeeNumberKey = 'employee_number';
  static const String _departmentKey = 'employee_department';
  static const String _locationTypeKey = 'employee_location_type';
  static const String _siteKey = 'employee_site';
  static const String _officeKey = 'employee_office';

  // Document Keys (now storing full DocumentFile as JSON)
  static const String _saIdPassportKey = 'doc_sa_id_passport';
  static const String _workPermitKey = 'doc_work_permit';
  static const String _proofOfResidenceKey = 'doc_proof_residence';
  static const String _qualificationsKey = 'doc_qualifications';

  // Authentication Options Keys
  static const String _selectedAuthMethodKey = 'selected_auth_method';
  static const String _isBiometricEnabledKey = 'is_biometric_enabled';

  // User Session Keys
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _lastLoginKey = 'last_login';

  // Save Authentication Method Preference
  static Future<void> saveAuthMethodPreference({
    String? authMethod,
    bool? isBiometricEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (authMethod != null) await prefs.setString(_selectedAuthMethodKey, authMethod);
    if (isBiometricEnabled != null) await prefs.setBool(_isBiometricEnabledKey, isBiometricEnabled);
  }

  // Load Authentication Method Preference
  static Future<Map<String, dynamic>> loadAuthMethodPreference() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'authMethod': prefs.getString(_selectedAuthMethodKey) ?? 'otp',
      'isBiometricEnabled': prefs.getBool(_isBiometricEnabledKey) ?? false,
    };
  }

  // Clear Authentication Preferences
  static Future<void> clearAuthPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_selectedAuthMethodKey);
    await prefs.remove(_isBiometricEnabledKey);
  }

  // Save Document Data (store full DocumentFile as JSON)
  static Future<void> saveDocumentData({
    Map<String, dynamic>? saIdPassport,
    Map<String, dynamic>? workPermit,
    Map<String, dynamic>? proofOfResidence,
    Map<String, dynamic>? qualifications,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (saIdPassport != null) {
      await prefs.setString(_saIdPassportKey, _mapToJson(saIdPassport));
    }
    if (workPermit != null) {
      await prefs.setString(_workPermitKey, _mapToJson(workPermit));
    }
    if (proofOfResidence != null) {
      await prefs.setString(_proofOfResidenceKey, _mapToJson(proofOfResidence));
    }
    if (qualifications != null) {
      await prefs.setString(_qualificationsKey, _mapToJson(qualifications));
    }
  }

  // Load Document Data
  static Future<Map<String, Map<String, dynamic>?>> loadDocumentData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'saIdPassport': _jsonToMap(prefs.getString(_saIdPassportKey)),
      'workPermit': _jsonToMap(prefs.getString(_workPermitKey)),
      'proofOfResidence': _jsonToMap(prefs.getString(_proofOfResidenceKey)),
      'qualifications': _jsonToMap(prefs.getString(_qualificationsKey)),
    };
  }

  // Save specific document
  static Future<void> saveDocument(String documentType, DocumentFile document) async {
    final prefs = await SharedPreferences.getInstance();
    final documentMap = document.toMap();
    final key = _getDocumentKey(documentType);
    if (key != null) {
      await prefs.setString(key, _mapToJson(documentMap));
    }
    
    switch (documentType) {
      case 'saIdPassport':
        await prefs.setString(_saIdPassportKey, _mapToJson(documentMap));
        break;
      case 'workPermit':
        await prefs.setString(_workPermitKey, _mapToJson(documentMap));
        break;
      case 'proofOfResidence':
        await prefs.setString(_proofOfResidenceKey, _mapToJson(documentMap));
        break;
      case 'qualifications':
        await prefs.setString(_qualificationsKey, _mapToJson(documentMap));
        break;
    }
  }

  static String? _getDocumentKey(String documentType) {
    switch (documentType) {
      case 'saIdPassport': return _saIdPassportKey;
      case 'workPermit': return _workPermitKey;
      case 'proofOfResidence': return _proofOfResidenceKey;
      case 'qualifications': return _qualificationsKey;
      default: return null;
    }
  }

  // Load specific document
  static Future<DocumentFile?> loadDocument(String documentType) async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString;
    
    switch (documentType) {
      case 'saIdPassport':
        jsonString = prefs.getString(_saIdPassportKey);
        break;
      case 'workPermit':
        jsonString = prefs.getString(_workPermitKey);
        break;
      case 'proofOfResidence':
        jsonString = prefs.getString(_proofOfResidenceKey);
        break;
      case 'qualifications':
        jsonString = prefs.getString(_qualificationsKey);
        break;
    }
    
    if (jsonString != null) {
      final map = _jsonToMap(jsonString);
      return map != null ? DocumentFile.fromMap(map) : null;
    }
    
    return null;
  }

  // Clear Document Data
  static Future<void> clearDocumentData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_saIdPassportKey);
    await prefs.remove(_workPermitKey);
    await prefs.remove(_proofOfResidenceKey);
    await prefs.remove(_qualificationsKey);
  }

  // Clear specific document
  static Future<void> clearDocument(String documentType) async {
    final prefs = await SharedPreferences.getInstance();
    
    switch (documentType) {
      case 'saIdPassport':
        await prefs.remove(_saIdPassportKey);
        break;
      case 'workPermit':
        await prefs.remove(_workPermitKey);
        break;
      case 'proofOfResidence':
        await prefs.remove(_proofOfResidenceKey);
        break;
      case 'qualifications':
        await prefs.remove(_qualificationsKey);
        break;
    }
  }

  // Save Personal Form Data
  static Future<void> savePersonalFormData({
    String? firstName,
    String? lastName,
    String? idOrPassportNo,
    String? phoneNumber,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (firstName != null) await prefs.setString(_firstNameKey, firstName);
    if (lastName != null) await prefs.setString(_lastNameKey, lastName);
    if (idOrPassportNo != null) await prefs.setString(_idNumberKey, idOrPassportNo);
    if (phoneNumber != null) await prefs.setString(_phoneKey, phoneNumber);
    if (email != null) await prefs.setString(_emailKey, email);
  }

  // Save Employee Form Data
  static Future<void> saveEmployeeFormData({
    String? employeeNumber,
    String? department,
    String? locationType,
    String? site,
    String? office,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (employeeNumber != null) await prefs.setString(_employeeNumberKey, employeeNumber);
    if (department != null) await prefs.setString(_departmentKey, department);
    if (locationType != null) await prefs.setString(_locationTypeKey, locationType);
    if (site != null) await prefs.setString(_siteKey, site);
    if (office != null) await prefs.setString(_officeKey, office);
  }

  // Load Personal Form Data
  static Future<Map<String, String>> loadPersonalFormData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'firstName': prefs.getString(_firstNameKey) ?? '',
      'lastName': prefs.getString(_lastNameKey) ?? '',
      'idOrPassportNo': prefs.getString(_idNumberKey) ?? '',
      'phoneNumber': prefs.getString(_phoneKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
    };
  }

  // Load Employee Form Data
  static Future<Map<String, String>> loadEmployeeFormData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'employeeNumber': prefs.getString(_employeeNumberKey) ?? '',
      'department': prefs.getString(_departmentKey) ?? '',
      'locationType': prefs.getString(_locationTypeKey) ?? 'site',
      'site': prefs.getString(_siteKey) ?? '',
      'office': prefs.getString(_officeKey) ?? '',
    };
  }

  // Save complete user session
  static Future<void> saveUserSession({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_userIdKey, userId);
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    
    // Save user data to respective form data methods
    await savePersonalFormData(
      firstName: userData['firstName'],
      lastName: userData['lastName'],
      idOrPassportNo: userData['idOrPassportNor'],
      phoneNumber: userData['phoneNumber'],
      email: userData['email'],
    );
    
    if (userData['employeeNumber'] != null) {
      await saveEmployeeFormData(
        employeeNumber: userData['employeeNumber'],
        department: userData['department'],
        locationType: userData['locationType'],
        site: userData['site'],
        office: userData['office'],
      );
    }
  }

  // Load user session
  static Future<Map<String, dynamic>> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    final personalData = await loadPersonalFormData();
    final employeeData = await loadEmployeeFormData();
    final authPrefs = await loadAuthMethodPreference();
    
    return {
      'userId': prefs.getString(_userIdKey),
      'isLoggedIn': prefs.getBool(_isLoggedInKey) ?? false,
      'lastLogin': prefs.getString(_lastLoginKey),
      ...personalData,
      ...employeeData,
      ...authPrefs,
    };
  }

  // Clear user session (logout)
  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_userIdKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_lastLoginKey);
    
    // Clear sensitive data but keep preferences
    await clearAllFormData();
    await clearDocumentData();
  }

  // Clear All Form Data
  static Future<void> clearAllFormData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Personal details
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_idNumberKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_emailKey);
    
    // Employee details
    await prefs.remove(_employeeNumberKey);
    await prefs.remove(_departmentKey);
    await prefs.remove(_locationTypeKey);
    await prefs.remove(_siteKey);
    await prefs.remove(_officeKey);
  }

  // Clear only employee form data
  static Future<void> clearEmployeeFormData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.remove(_employeeNumberKey);
    await prefs.remove(_departmentKey);
    await prefs.remove(_locationTypeKey);
    await prefs.remove(_siteKey);
    await prefs.remove(_officeKey);
  }

  // Check if user has incomplete signup data
  static Future<bool> hasIncompleteSignupData() async {
    final personalData = await loadPersonalFormData();
    final hasPersonalData = personalData['firstName']!.isNotEmpty &&
        personalData['lastName']!.isNotEmpty &&
        personalData['idOrPassportNo']!.isNotEmpty &&
        personalData['phoneNumber']!.isNotEmpty &&
        personalData['email']!.isNotEmpty;

    final employeeData = await loadEmployeeFormData();
    final hasEmployeeData = employeeData['employeeNumber']!.isNotEmpty &&
        employeeData['department']!.isNotEmpty;

    final documentData = await loadDocumentData();
    final hasDocuments = documentData['saIdPassport'] != null;

    return hasPersonalData && (!hasEmployeeData || !hasDocuments);
  }

  // Get signup progress
  static Future<Map<String, dynamic>> getSignupProgress() async {
    final personalData = await loadPersonalFormData();
    final employeeData = await loadEmployeeFormData();
    final documentData = await loadDocumentData();

    final personalComplete = personalData['firstName']!.isNotEmpty &&
        personalData['lastName']!.isNotEmpty &&
        personalData['idOrPassportNo']!.isNotEmpty &&
        personalData['phoneNumber']!.isNotEmpty &&
        personalData['email']!.isNotEmpty;

    final employeeComplete = employeeData['employeeNumber']!.isNotEmpty &&
        employeeData['department']!.isNotEmpty;

    final documentsComplete = documentData['saIdPassport'] != null;

    final totalSteps = 3;
    final completedSteps = [personalComplete, employeeComplete, documentsComplete]
        .where((complete) => complete)
        .length;

    return {
      'personalComplete': personalComplete,
      'employeeComplete': employeeComplete,
      'documentsComplete': documentsComplete,
      'progressPercentage': (completedSteps / totalSteps) * 100,
      'completedSteps': completedSteps,
      'totalSteps': totalSteps,
    };
  }

  // Helper method to convert map to JSON string
  static String _mapToJson(Map<String, dynamic> map) {
    // Convert DateTime to milliseconds since epoch for storage
    final convertedMap = Map<String, dynamic>.from(map);
    if (convertedMap['uploadedAt'] is DateTime) {
      convertedMap['uploadedAt'] = (convertedMap['uploadedAt'] as DateTime).millisecondsSinceEpoch;
    }
    
    return convertedMap.entries.map((entry) => '${entry.key}::${entry.value}').join('||');
  }

  // Helper method to convert JSON string to map
  static Map<String, dynamic>? _jsonToMap(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    
    final map = <String, dynamic>{};
    final pairs = jsonString.split('||');
    
    for (final pair in pairs) {
      final parts = pair.split('::');
      if (parts.length == 2) {
        final key = parts[0];
        dynamic value = parts[1]; // ✅ Use dynamic
        
        // Convert back to appropriate types
        if (key == 'uploadedAt') {
          value = DateTime.fromMillisecondsSinceEpoch(int.parse(parts[1]));
        } else if (key == 'fileSize') {
          value = int.parse(parts[1]);
        }
        
        map[key] = value;
      }
    }
    
    return map;
  }


  // Backup all data (for debugging or migration)
  static Future<Map<String, dynamic>> backupAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final personalData = await loadPersonalFormData();
    final employeeData = await loadEmployeeFormData();
    final documentData = await loadDocumentData();
    final authData = await loadAuthMethodPreference();
    final sessionData = await loadUserSession();

    return {
      'personalData': personalData,
      'employeeData': employeeData,
      'documentData': documentData,
      'authData': authData,
      'sessionData': sessionData,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Clear everything (complete reset)
  static Future<void> clearEverything() async {
    final prefs = await SharedPreferences.getInstance();
    
    await clearAllFormData();
    await clearDocumentData();
    await clearAuthPreferences();
    await clearUserSession();
    
    // Clear any other keys that might exist
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('signup_') || 
          key.startsWith('employee_') || 
          key.startsWith('doc_')) {
        await prefs.remove(key);
      }
    }
  }

  // Clear all data
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_firstNameKey);
    await prefs.remove(_lastNameKey);
    await prefs.remove(_idNumberKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_employeeNumberKey);
    await prefs.remove(_departmentKey);
    await prefs.remove(_locationTypeKey);
    await prefs.remove(_siteKey);
    await prefs.remove(_officeKey);
    await prefs.remove(_saIdPassportKey);
    await prefs.remove(_workPermitKey);
    await prefs.remove(_proofOfResidenceKey);
    await prefs.remove(_qualificationsKey);
    await prefs.remove(_selectedAuthMethodKey);
    await prefs.remove(_isBiometricEnabledKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_lastLoginKey);
  }
}