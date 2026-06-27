import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/routes/route_manager.dart';
import 'package:flutter_cc_evs/services/validation_service.dart';
import 'package:flutter_cc_evs/viewmodels/sign_up_employee_view_model.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';
import 'package:provider/provider.dart';

class SignUpEmployeeScreen extends StatefulWidget {
  final UserModel user;

  const SignUpEmployeeScreen({super.key, required this.user});

  @override
  State<SignUpEmployeeScreen> createState() => _SignUpEmployeeScreenState();
}

class _SignUpEmployeeScreenState extends State<SignUpEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignUpEmployeeViewModel>().loadSavedFormState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpEmployeeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Employee Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please provide your employment information',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Employee Number
                  TextFormField(
                    controller: viewModel.employeeNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Employee Number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    validator: ValidationService.validateEmployeeNumber,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // Department
                  TextFormField(
                    controller: viewModel.departmentController,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: ValidationService.validateDepartment,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Select Location:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildLocationRadio(
                    value: LocationType.site,
                    title: 'Site',
                    viewModel: viewModel,
                  ),
                  const SizedBox(height: 12),
                  _buildLocationRadio(
                    value: LocationType.office,
                    title: 'Office',
                    viewModel: viewModel,
                  ),
                  const SizedBox(height: 16),

                  // Conditional Site/Office Field
                  if (viewModel.selectedLocation == LocationType.site)
                    TextFormField(
                      controller: viewModel.siteController,
                      decoration: const InputDecoration(
                        labelText: 'Site Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) =>
                          ValidationService.validateSite(value, viewModel.selectedLocation),
                    ),
                  if (viewModel.selectedLocation == LocationType.office)
                    TextFormField(
                      controller: viewModel.officeController,
                      decoration: const InputDecoration(
                        labelText: 'Office Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                      validator: (value) =>
                          ValidationService.validateOffice(value, viewModel.selectedLocation),
                    ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed:
                              viewModel.isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: viewModel.isLoading
                              ? null
                              : () => _handleContinue(context, viewModel),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: viewModel.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRadio({
    required LocationType value,
    required String title,
    required SignUpEmployeeViewModel viewModel,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: viewModel.selectedLocation == value
              ? Colors.blue
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RadioListTile<LocationType>(
        value: value,
        groupValue: viewModel.selectedLocation,
        title: Text(title),
        activeColor: Colors.blue,
        onChanged: (newValue) {
          viewModel.selectedLocation = newValue;
        },
      ),
    );
  }

  /// ✅ Refined _handleContinue method
  Future<void> _handleContinue(
    BuildContext context,
    SignUpEmployeeViewModel viewModel,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    if (viewModel.selectedLocation == null) {
      CustomSnackbar.showError(context, 'Please select a location (Site or Office)');
      return;
    }

    viewModel.isLoading = true;
    try {
      // Merge personal user data with employee data
      final mergedUser = viewModel.mergeWithPersonalUser(widget.user);

      // Navigate to Upload Documents screen with full user data
      Navigator.pushNamed(
        context,
        RouteManager.signUpDocuments,
        arguments: mergedUser,
      );

      CustomSnackbar.showSuccess(context, 'Employee details saved successfully!');
    } catch (e) {
      CustomSnackbar.showError(context, 'Error: ${e.toString()}');
    } finally {
      viewModel.isLoading = false;
    }
  }
}
