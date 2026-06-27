import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/services/auth_service.dart';
import 'package:flutter_cc_evs/services/document_service.dart';
import 'package:flutter_cc_evs/services/state_persistence_service.dart';
import 'package:flutter_cc_evs/widgets/document_item.dart';
import 'package:flutter_cc_evs/widgets/custom_snackbars.dart';
import 'package:flutter_cc_evs/widgets/upload_button_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DocumentService _documentService = DocumentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  
  bool _isUpdating = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isUploading = false;

  // Document states
  DocumentFile? _saIdPassportImage;
  DocumentFile? _workPermit;
  DocumentFile? _proofOfResidence;
  DocumentFile? _qualificationsCertificates;

  // Upload progress tracking
  final Map<String, double> _uploadProgress = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _currentUser = UserModel.fromMap(userDoc.id, userData);
          _saIdPassportImage = _currentUser?.saIdPassportImage;
          _workPermit = _currentUser?.workPermit;
          _proofOfResidence = _currentUser?.proofOfResidence;
          _qualificationsCertificates = _currentUser?.qualificationsCertificates;
        });
      }
    } catch (e) {
      CustomSnackbar.showError(context, 'Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showUploadOptions(String documentType) async {
    if (_isUploading) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UploadButtonSheet(
        onFileSelected: (file) => _handleFileUpload(file, documentType),
        onError: (error) {
          CustomSnackbar.showError(context, 'Upload error: ${error.toString()}');
        },
        maxFileSizeMB: 10.0,
      ),
    );
  }

  Future<void> _handleFileUpload(PlatformFile platformFile, String documentType) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      CustomSnackbar.showError(context, 'Please sign in to upload documents');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress[documentType] = 0.0;
    });

    try {
      final uploadedFile = await _documentService.uploadDocument(
        userId: currentUser.uid,
        documentType: _getStorageDocumentType(documentType),
        platformFile: platformFile,
        onProgress: (progress) {
          setState(() {
            _uploadProgress[documentType] = progress;
          });
        },
      );

      if (uploadedFile != null) {
        // Update local state
        _updateDocument(documentType, uploadedFile);
        
        // Update Firestore
        await _updateUserDocument(currentUser.uid, documentType, uploadedFile);
        
        CustomSnackbar.showSuccess(context, 'Document uploaded successfully!');
      }
    } catch (e) {
      CustomSnackbar.showError(context, 'Upload failed: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress.remove(documentType);
      });
    }
  }

  Future<void> _updateUserDocument(
    String userId, 
    String documentType, 
    DocumentFile documentFile
  ) async {
    final fieldName = _getStorageDocumentType(documentType);
    
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
          fieldName: documentFile.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _deleteDocument(String documentType) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final document = _getDocumentByType(documentType);
    if (document == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete ${document.fileName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(documentType, document);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(String documentType, DocumentFile document) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final success = await _documentService.deleteDocument(
        userId: currentUser.uid,
        documentType: _getStorageDocumentType(documentType),
        filePath: document.filePath,
      );

      if (success) {
        // Update local state
        _removeDocument(documentType);
        
        // Update Firestore
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .update({
              _getStorageDocumentType(documentType): FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        CustomSnackbar.showSuccess(context, 'Document deleted successfully');
      } else {
        throw Exception('Failed to delete document');
      }
    } catch (e) {
      CustomSnackbar.showError(context, 'Delete failed: ${e.toString()}');
    }
  }

  void _updateDocument(String documentType, DocumentFile uploadedFile) {
    setState(() {
      switch (documentType) {
        case 'saIdPassport':
          _saIdPassportImage = uploadedFile;
          break;
        case 'workPermit':
          _workPermit = uploadedFile;
          break;
        case 'proofOfResidence':
          _proofOfResidence = uploadedFile;
          break;
        case 'qualifications':
          _qualificationsCertificates = uploadedFile;
          break;
      }
    });
  }

  void _removeDocument(String documentType) {
    setState(() {
      switch (documentType) {
        case 'saIdPassport':
          _saIdPassportImage = null;
          break;
        case 'workPermit':
          _workPermit = null;
          break;
        case 'proofOfResidence':
          _proofOfResidence = null;
          break;
        case 'qualifications':
          _qualificationsCertificates = null;
          break;
      }
    });
  }

  Future<void> _updateProfileField(String field, String newValue) async {
  final currentUser = _auth.currentUser;
  if (currentUser == null || newValue.isEmpty) return;

  setState(() => _isUpdating = true);

  try {
    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .update({
          field: newValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });

    // Update local state
    setState(() {
      switch (field) {
        case 'firstName':
          _currentUser = _currentUser?.copyWith(firstName: newValue);
          break;
        case 'lastName':
          _currentUser = _currentUser?.copyWith(lastName: newValue);
          break;
        case 'phoneNumber':
          _currentUser = _currentUser?.copyWith(phoneNumber: newValue);
          break;
      }
    });

    CustomSnackbar.showSuccess(context, 'Profile updated successfully');
  } catch (e) {
    CustomSnackbar.showError(context, 'Failed to update profile: $e');
  } finally {
    setState(() => _isUpdating = false);
  }
}

Future<void> _signOut() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await _performSignOut();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Sign Out'),
        ),
      ],
    ),
  );
}

Future<void> _performSignOut() async {
  try {
    await _authService.signOut();
    await StatePersistenceService.clearAllData();
    
    // Navigate to sign in screen and clear all routes
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/signIn', 
      (route) => false
    );
    
    CustomSnackbar.showSuccess(context, 'Signed out successfully');
  } catch (e) {
    CustomSnackbar.showError(context, 'Sign out failed: $e');
  }
}

  DocumentFile? _getDocumentByType(String documentType) {
    switch (documentType) {
      case 'saIdPassport': return _saIdPassportImage;
      case 'workPermit': return _workPermit;
      case 'proofOfResidence': return _proofOfResidence;
      case 'qualifications': return _qualificationsCertificates;
      default: return null;
    }
  }

  String _getStorageDocumentType(String documentType) {
    switch (documentType) {
      case 'saIdPassport': return 'saIdPassportImage';
      case 'workPermit': return 'workPermit';
      case 'proofOfResidence': return 'proofOfResidence';
      case 'qualifications': return 'qualificationsCertificates';
      default: return documentType;
    }
  }

  Widget _buildUserInfoSection() {
    if (_currentUser == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading user information...'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('First Name', _currentUser!.firstName, 'firstName'),
            _buildInfoRow('Last Name', _currentUser!.lastName, 'lastName'),
            _buildInfoRow('ID/Passport', _currentUser!.idOrPassportNo, 'idOrPassportNo'),
            _buildInfoRow('Phone', _currentUser!.phoneNumber, 'phoneNumber'),
            _buildInfoRow('Email', _currentUser!.email, 'email'),
            if (_currentUser!.employeeNumber != null)
              _buildInfoRow('Employee Number', _currentUser!.employeeNumber!, 'Employee Number'),
            if (_currentUser!.department != null)
              _buildInfoRow('Department', _currentUser!.department!, 'Department'),
            if (_currentUser!.location != null)
              _buildInfoRow('Location', _currentUser!.location!.displayName, 'Location'),
            if (_currentUser!.site != null && _currentUser!.site!.isNotEmpty)
              _buildInfoRow('Site', _currentUser!.site!, 'Site'),
            if (_currentUser!.office != null && _currentUser!.office!.isNotEmpty)
              _buildInfoRow('Office', _currentUser!.office!, 'Office'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String field) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _isUpdating && _getControllerForField(field).text.isNotEmpty
                    ? TextField(
                        controller: _getControllerForField(field),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: value,
                        ),
                        onSubmitted: (newValue) {
                          if (newValue.isNotEmpty && newValue != value) {
                            _updateProfileField(field, newValue);
                          }
                        },
                      )
                    : GestureDetector(
                        onTap: () {
                          _showEditDialog(label, value, field);
                        },
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                        ),
                      ),
              ),
              if (!_isUpdating)
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  onPressed: () => _showEditDialog(label, value, field),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

TextEditingController _getControllerForField(String field) {
  switch (field) {
    case 'firstName': return _firstNameController;
    case 'lastName': return _lastNameController;
    case 'phoneNumber': return _phoneController;
    default: return TextEditingController();
  }
}

Future<void> _showEditDialog(String label, String currentValue, String field) async {
  final controller = _getControllerForField(field);
  controller.text = currentValue;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Edit $label'),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Enter new $label',
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final newValue = controller.text.trim();
            if (newValue.isNotEmpty && newValue != currentValue) {
              _updateProfileField(field, newValue);
            }
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            'Documents',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        DocumentItem(
          documentType: 'saIdPassport',
          label: 'ID/Passport',
          document: _saIdPassportImage,
          onUpload: () => _showUploadOptions('saIdPassport'),
          onReplace: () => _showUploadOptions('saIdPassport'),
          onDelete: () => _deleteDocument('saIdPassport'),
          isLoading: _isUploading && _uploadProgress.containsKey('saIdPassport'),
          uploadProgress: _uploadProgress['saIdPassport'],
        ),
        DocumentItem(
          documentType: 'workPermit',
          label: 'Work Permit',
          document: _workPermit,
          onUpload: () => _showUploadOptions('workPermit'),
          onReplace: () => _showUploadOptions('workPermit'),
          onDelete: () => _deleteDocument('workPermit'),
          isLoading: _isUploading && _uploadProgress.containsKey('workPermit'),
          uploadProgress: _uploadProgress['workPermit'],
        ),
        DocumentItem(
          documentType: 'proofOfResidence',
          label: 'Proof of Residence',
          document: _proofOfResidence,
          onUpload: () => _showUploadOptions('proofOfResidence'),
          onReplace: () => _showUploadOptions('proofOfResidence'),
          onDelete: () => _deleteDocument('proofOfResidence'),
          isLoading: _isUploading && _uploadProgress.containsKey('proofOfResidence'),
          uploadProgress: _uploadProgress['proofOfResidence'],
        ),
        DocumentItem(
          documentType: 'qualifications',
          label: 'Qualifications/Certificates',
          document: _qualificationsCertificates,
          onUpload: () => _showUploadOptions('qualifications'),
          onReplace: () => _showUploadOptions('qualifications'),
          onDelete: () => _deleteDocument('qualifications'),
          isLoading: _isUploading && _uploadProgress.containsKey('qualifications'),
          uploadProgress: _uploadProgress['qualifications'],
        ),
      ],
    );
  }

  Widget _buildVerificationStatus() {
    final isVerified = _currentUser?.isVerified ?? false;
    
    return Card(
      color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              isVerified ? Icons.verified : Icons.pending_actions,
              color: isVerified ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified ? 'Account Verified' : 'Pending Verification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isVerified ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isVerified 
                        ? 'Your account has been successfully verified'
                        : 'Your documents are under review',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading profile...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Row(
                    children: [
                      Icon(Icons.person, size: 32, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  
                  // Verification Status
                  _buildVerificationStatus(),
                  const SizedBox(height: 20),
                  
                  // User Information
                  _buildUserInfoSection(),
                  const SizedBox(height: 24),
                  
                  // Documents Section
                  _buildDocumentsSection(),
                  const SizedBox(height: 20),
                  
                  // Statistics
                  _buildStatistics(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatistics() {
    final totalDocuments = [
      _saIdPassportImage,
      _workPermit,
      _proofOfResidence,
      _qualificationsCertificates,
    ].where((doc) => doc != null).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.description,
              value: totalDocuments.toString(),
              label: 'Documents',
            ),
            _buildStatItem(
              icon: Icons.verified,
              value: _currentUser?.isVerified == true ? 'Yes' : 'No',
              label: 'Verified',
            ),
            _buildStatItem(
              icon: Icons.calendar_today,
              value: _currentUser?.createdAt != null 
                  ? '${_currentUser!.createdAt!.day}/${_currentUser!.createdAt!.month}/${_currentUser!.createdAt!.year}'
                  : 'N/A',
              label: 'Joined',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _refreshProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh Profile'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _refreshProfile() async {
  setState(() => _isLoading = true);
  await _loadUserData();
  CustomSnackbar.showSuccess(context, 'Profile refreshed');
}

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
void dispose() {
  _firstNameController.dispose();
  _lastNameController.dispose();
  _phoneController.dispose();
  super.dispose();
}
}