import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/viewmodels/sign_up_documents_view_model.dart';
import 'package:flutter_cc_evs/viewmodels/sign_up_personal_view_model.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class SignUpDocumentsScreen extends StatefulWidget {
  final UserModel user;
  
  const SignUpDocumentsScreen({super.key, required this.user});

  @override
  State<SignUpDocumentsScreen> createState() => _SignUpDocumentsScreenState();
}

class _SignUpDocumentsScreenState extends State<SignUpDocumentsScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved document state when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SignUpDocumentsViewModel>().loadSavedDocumentState();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpDocumentsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Upload Documents',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload your required documents. You can skip and upload later.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // SA ID / Passport Image
                _buildDocumentSection(
                  title: 'SA ID / Passport Image',
                  documentType: 'saIdPassport',
                  documentFile: viewModel.saIdPassportImage,
                  viewModel: viewModel,
                ),
                const SizedBox(height: 24),

                // Work Permit
                _buildDocumentSection(
                  title: 'Work Permit',
                  documentType: 'workPermit',
                  documentFile: viewModel.workPermit,
                  viewModel: viewModel,
                ),
                const SizedBox(height: 24),

                // Proof of Residence
                _buildDocumentSection(
                  title: 'Proof of Residence',
                  documentType: 'proofOfResidence',
                  documentFile: viewModel.proofOfResidence,
                  viewModel: viewModel,
                ),
                const SizedBox(height: 24),

                // Qualifications / Certificates
                _buildDocumentSection(
                  title: 'Qualifications / Certificates',
                  documentType: 'qualifications',
                  documentFile: viewModel.qualificationsCertificates,
                  viewModel: viewModel,
                ),
                const SizedBox(height: 40),

                // Buttons Row
                Row(
                  children: [
                    // Back Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: viewModel.isLoading || viewModel.isUploading
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Continue Button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading || viewModel.isUploading
                            ? null
                            : () => _handleContinue(context, viewModel),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: viewModel.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Continue',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required String title,
    required String documentType,
    required DocumentFile? documentFile,
    required SignUpDocumentsViewModel viewModel,
  }) {
    final isUploading = viewModel.isUploadingDocument(documentType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title with spacing
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12), // Adjusted spacing

        // Upload/Replace Button
        if (documentFile == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: viewModel.isUploading
                  ? null
                  : () => _showFilePickerOptions(context, documentType, viewModel),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.upload_file),
              label: const Text('Click to Upload'),
            ),
          )
        else
          Column(
            children: [
              // Uploaded File Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      documentFile.isImage ? Icons.image : Icons.description,
                      color: Colors.green.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            documentFile.fileName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${documentFile.fileSizeFormatted} • ${documentFile.fileType}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons Row
              Row(
                children: [
                  // Replace Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isUploading
                          ? null
                          : () => _showFilePickerOptions(context, documentType, viewModel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Replace'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Delete Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: viewModel.isUploading
                          ? null
                          : () => _showDeleteConfirmation(context, documentType, viewModel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        
        // Uploading Indicator
        if (viewModel.isUploading && documentFile == null)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _showFilePickerOptions(
    BuildContext context,
    String documentType,
    SignUpDocumentsViewModel viewModel,
  ) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                viewModel.pickImage(documentType, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                viewModel.pickImage(documentType, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Choose File'),
              onTap: () {
                Navigator.pop(context);
                viewModel.pickFile(documentType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String documentType,
    SignUpDocumentsViewModel viewModel,
  ) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteDocument(documentType);
              CustomSnackbar.showInfo(context, 'Document deleted successfully');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleContinue(
    BuildContext context,
    SignUpDocumentsViewModel viewModel,
  ) async {
    FocusScope.of(context).unfocus();

    try {
      viewModel.isLoading = true;

      // Update the user model with any uploaded documents
      final updatedUser = viewModel.updateUserWithDocuments(widget.user);

      // Navigate to Sign Up Auth Options Screen with all collected data AND password
      Navigator.pushNamed(
        context,
        '/signUpAuthOptions',
        arguments: {
          'user': updatedUser,
          'password': _getPasswordFromPreviousScreens(), // Add this
        },
      );

      CustomSnackbar.showSuccess(
        context,
        viewModel.hasAnyDocuments
            ? 'Documents saved successfully!'
            : 'Skipped document upload — you can upload later.',
      );
    } catch (e) {
      CustomSnackbar.showError(context, 'Error: ${e.toString()}');
    } finally {
      viewModel.isLoading = false;
    }
  }

String _getPasswordFromPreviousScreens() {
  // Retrieve from your form state or ViewModel
  // This depends on how you're managing state between screens
  final personalViewModel = context.read<SignUpPersonalViewModel>();
  return personalViewModel.passwordController.text;
}
}