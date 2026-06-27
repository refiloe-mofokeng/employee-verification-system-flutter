import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/services/state_persistence_service.dart';
import 'package:flutter_cc_evs/services/validation_service.dart';

// FIXED: Convert to mixin instead of abstract class
mixin FormViewModel on ChangeNotifier {
  bool _isFormValid = false;
  bool get isFormValid => _isFormValid;

  void updateFormValidity() {
    _isFormValid = validateForm();
    notifyListeners();
  }

  bool validateForm();
}

class SignUpPersonalViewModel extends ChangeNotifier with FormViewModel { // FIXED: Use extends with mixin
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController identificationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String? get emailError => _emailError;
  String? get phoneError => _phoneError;
  String? get passwordError => _passwordError;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  void validateEmail(String value) {
    _emailError = ValidationService.validateEmail(value);
    updateFormValidity();
  }

  void validatePhone(String value) {
    _phoneError = ValidationService.validatePhoneNumber(value);
    updateFormValidity();
  }

  void validatePassword(String value) {
    _passwordError = ValidationService.validatePassword(value);
    updateFormValidity();
  }

  void onFieldChanged() => saveFormState();

  @override
  bool validateForm() {
    return ValidationService.validateFirstName(firstNameController.text) == null &&
        ValidationService.validateLastName(lastNameController.text) == null &&
        ValidationService.validateIdentificationNumber(identificationController.text) == null &&
        ValidationService.validatePhoneNumber(phoneController.text) == null &&
        ValidationService.validateEmail(emailController.text) == null &&
        ValidationService.validatePassword(passwordController.text) == null &&
        ValidationService.validateConfirmPassword(
          confirmPasswordController.text, 
          passwordController.text
        ) == null;
  }

  Future<void> saveFormState() async {
    await StatePersistenceService.savePersonalFormData(
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      idOrPassportNo: identificationController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim(),
    );
  }

  Future<void> loadSavedFormState() async {
    final saved = await StatePersistenceService.loadPersonalFormData();
    firstNameController.text = saved['firstName'] ?? '';
    lastNameController.text = saved['lastName'] ?? '';
    identificationController.text = saved['idOrPassportNo'] ?? '';
    phoneController.text = saved['phoneNumber'] ?? '';
    emailController.text = saved['email'] ?? '';
    
    // Validate loaded data
    validateEmail(emailController.text);
    validatePhone(phoneController.text);
    updateFormValidity();
    notifyListeners();
  }

  UserModel createUserModel() {
    return UserModel(
      uid: '',
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      idOrPassportNo: identificationController.text.trim(),
      phoneNumber: phoneController.text.trim(),
      email: emailController.text.trim().toLowerCase(),
      employeeNumber: null,
      department: null,
      location: null,
      site: null,
      office: null,
      saIdPassportImage: null,
      workPermit: null,
      proofOfResidence: null,
      qualificationsCertificates: null,
      isOTPVerified: false,
      isBiometricCompleted: false,
      isVerified: false,
    );
  }

  int get completionPercentage {
    final fields = [
      firstNameController.text.isNotEmpty,
      lastNameController.text.isNotEmpty,
      identificationController.text.isNotEmpty,
      phoneController.text.isNotEmpty,
      emailController.text.isNotEmpty,
      passwordController.text.isNotEmpty,
      confirmPasswordController.text.isNotEmpty,
    ];
    return ((fields.where((f) => f).length / fields.length) * 100).round();
  }

  Future<void> clearForm() async {
    firstNameController.clear();
    lastNameController.clear();
    identificationController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    await StatePersistenceService.clearAllData();
    updateFormValidity();
    notifyListeners();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    identificationController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}