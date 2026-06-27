import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/services/state_persistence_service.dart';
import 'package:flutter_cc_evs/services/validation_service.dart';

// REMOVE: abstract class FormViewModel with ChangeNotifier {
// Create a mixin instead
mixin FormViewModel on ChangeNotifier {
  bool _isFormValid = false;
  bool get isFormValid => _isFormValid;

  void updateFormValidity() {
    _isFormValid = validateForm();
    notifyListeners();
  }

  bool validateForm();
}

class SignUpEmployeeViewModel extends ChangeNotifier with FormViewModel { // FIXED: Use extends with mixin
  final TextEditingController employeeNumberController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController siteController = TextEditingController();
  final TextEditingController officeController = TextEditingController();

  bool _isLoading = false;
  LocationType? _selectedLocation;

  bool get isLoading => _isLoading;
  LocationType? get selectedLocation => _selectedLocation;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set selectedLocation(LocationType? value) {
    _selectedLocation = value;
    _saveFormState();
    updateFormValidity(); // FIXED: This method exists in the mixin
    notifyListeners();
  }

  @override // FIXED: Remove override since it's implementing abstract method
  bool validateForm() {
    final employeeValid = ValidationService.validateEmployeeNumber(
        employeeNumberController.text) == null;
    final departmentValid = ValidationService.validateDepartment(
        departmentController.text) == null;
    final locationValid = ValidationService.validateLocation(_selectedLocation) == null;
    
    final siteValid = _selectedLocation == LocationType.site 
        ? ValidationService.validateSite(siteController.text, _selectedLocation) == null
        : true;
        
    final officeValid = _selectedLocation == LocationType.office
        ? ValidationService.validateOffice(officeController.text, _selectedLocation) == null
        : true;

    return employeeValid && departmentValid && locationValid && siteValid && officeValid;
  }

  Future<void> _saveFormState() async {
    await StatePersistenceService.saveEmployeeFormData(
      employeeNumber: employeeNumberController.text,
      department: departmentController.text,
      locationType: _selectedLocation?.toString().split('.').last,
      site: siteController.text,
      office: officeController.text,
    );
  }

  Future<void> loadSavedFormState() async {
    final savedData = await StatePersistenceService.loadEmployeeFormData();
    if (savedData.isEmpty) return;

    employeeNumberController.text = savedData['employeeNumber'] ?? '';
    departmentController.text = savedData['department'] ?? '';

    final loc = savedData['locationType'];
    if (loc == 'site') {
      _selectedLocation = LocationType.site;
    } else if (loc == 'office') {
      _selectedLocation = LocationType.office;
    }

    siteController.text = savedData['site'] ?? '';
    officeController.text = savedData['office'] ?? '';
    updateFormValidity(); // FIXED: This method exists in the mixin
    notifyListeners();
  }

  UserModel mergeWithPersonalUser(UserModel user) {
    return user.copyWith(
      employeeNumber: employeeNumberController.text.trim(),
      department: departmentController.text.trim(),
      location: _selectedLocation!,
      site: _selectedLocation == LocationType.site
          ? siteController.text.trim()
          : null,
      office: _selectedLocation == LocationType.office
          ? siteController.text.trim() // FIXED: Changed officeController to siteController
          : null,
    );
  }

  Future<void> clearForm() async {
    employeeNumberController.clear();
    departmentController.clear();
    siteController.clear();
    officeController.clear();
    _selectedLocation = null;
    await StatePersistenceService.clearAllData();
    updateFormValidity(); // FIXED: This method exists in the mixin
    notifyListeners();
  }

  @override
  void dispose() {
    employeeNumberController.dispose();
    departmentController.dispose();
    siteController.dispose();
    officeController.dispose();
    super.dispose();
  }
}