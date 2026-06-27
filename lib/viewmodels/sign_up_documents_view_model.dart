import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart'; // ADD THIS IMPORT
import 'package:flutter_cc_evs/models/user_model.dart';
import 'package:flutter_cc_evs/services/document_service.dart';
import 'package:flutter_cc_evs/services/state_persistence_service.dart';
import 'package:image_picker/image_picker.dart';

class DocumentUploadState {
  final String documentType;
  final double progress;
  final bool isUploading;
  final String? error;

  DocumentUploadState({
    required this.documentType,
    this.progress = 0.0,
    this.isUploading = false,
    this.error,
  });
}

class SignUpDocumentsViewModel with ChangeNotifier {
  final DocumentService _documentService = DocumentService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  String? _userId;
  final Map<String, File> _localFilesCache = {};

  // Document files
  DocumentFile? _saIdPassportImage;
  DocumentFile? _workPermit;
  DocumentFile? _proofOfResidence;
  DocumentFile? _qualificationsCertificates;

  // Upload states
  final Map<String, DocumentUploadState> _uploadStates = {};

  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _uploadStates.values.any((state) => state.isUploading); // ADD THIS GETTER
  DocumentFile? get saIdPassportImage => _saIdPassportImage;
  DocumentFile? get workPermit => _workPermit;
  DocumentFile? get proofOfResidence => _proofOfResidence;
  DocumentFile? get qualificationsCertificates => _qualificationsCertificates;

  bool get hasRequiredDocuments => _saIdPassportImage != null;
  bool get hasAnyDocuments => _saIdPassportImage != null || _workPermit != null || 
                            _proofOfResidence != null || _qualificationsCertificates != null;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void initialize(String userId) {
    _userId = userId;
  }

  bool isUploadingDocument(String documentType) {
    return _uploadStates[documentType]?.isUploading ?? false;
  }

  double getUploadProgress(String documentType) {
    return _uploadStates[documentType]?.progress ?? 0.0;
  }

  DocumentUploadState getUploadState(String documentType) {
    return _uploadStates[documentType] ?? DocumentUploadState(documentType: documentType);
  }

  Future<void> pickFile(String documentType) async {
    try {
      FilePickerResult? result = await _documentService.pickFile();
      if (result != null && result.files.isNotEmpty) {
        await _handleFilePicked(result.files.first, documentType);
      }
    } catch (e) {
      _updateUploadState(documentType, error: e.toString());
      rethrow;
    }
  }

  Future<void> pickImage(String documentType, ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final platformFile = PlatformFile(
          name: pickedFile.name,
          path: pickedFile.path,
          size: await file.length(),
        );
        await _handleFilePicked(platformFile, documentType);
      }
    } catch (e) {
      _updateUploadState(documentType, error: e.toString());
      rethrow;
    }
  }

  Future<void> _handleFilePicked(PlatformFile platformFile, String documentType) async {
    if (!_isValidFileType(platformFile)) {
      throw 'Invalid file type. Please select JPG, PNG, PDF, DOC, or DOCX files.';
    }

    if (!_documentService.isFileSizeValid(platformFile)) {
      final fileSizeMB = _documentService.getFileSizeInMB(platformFile);
      throw 'File size too large (${fileSizeMB.toStringAsFixed(1)}MB). Please select files smaller than 10MB.';
    }

    // For pre-auth uploads, store locally
    if (_userId == null || _userId!.isEmpty) {
      await _storeFileLocally(platformFile, documentType);
    } else {
      await _uploadToFirebase(platformFile, documentType);
    }
  }

  Future<void> _storeFileLocally(PlatformFile platformFile, String documentType) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${documentType}_${DateTime.now().millisecondsSinceEpoch}'); // FIXED: removed extra underscore
    await tempFile.writeAsBytes(await File(platformFile.path!).readAsBytes());
    _localFilesCache[documentType] = tempFile;

    // Create temporary DocumentFile for UI
    final tempDocument = DocumentFile(
      fileName: platformFile.name,
      filePath: tempFile.path,
      fileUrl: '', // No URL for local files
      fileSize: platformFile.size,
      fileType: _getFileType(platformFile.name), // FIXED: Use local method
      uploadedAt: DateTime.now(),
    );

    _updateDocument(documentType, tempDocument);
    await _saveDocumentState();
  }

  Future<void> uploadCachedFiles(String userId) async {
    _userId = userId;
    for (final entry in _localFilesCache.entries) {
      final platformFile = PlatformFile(
        name: entry.key,
        path: entry.value.path,
        size: await entry.value.length(),
      );
      await _uploadToFirebase(platformFile, entry.key, userId);
    }
    _localFilesCache.clear();
  }

  Future<void> _uploadToFirebase(PlatformFile platformFile, String documentType, [String? userId]) async {
    final uploadUserId = userId ?? _userId;
    if (uploadUserId == null) throw 'User ID not available for upload';

    _updateUploadState(documentType, isUploading: true, progress: 0.0);

    try {
      final uploadedFile = await _documentService.uploadDocument(
        userId: uploadUserId,
        documentType: _getStorageDocumentType(documentType),
        platformFile: platformFile,
        onProgress: (progress) {
          _updateUploadState(documentType, progress: progress);
        },
      );

      if (uploadedFile != null) {
        _updateDocument(documentType, uploadedFile);
        await _saveDocumentState();
        _updateUploadState(documentType, isUploading: false, progress: 1.0);
      } else {
        throw 'Failed to upload document';
      }
    } catch (e) {
      _updateUploadState(documentType, error: e.toString(), isUploading: false);
      rethrow;
    }
  }

  void _updateUploadState(String documentType, {
    bool? isUploading,
    double? progress,
    String? error,
  }) {
    _uploadStates[documentType] = DocumentUploadState(
      documentType: documentType,
      isUploading: isUploading ?? _uploadStates[documentType]?.isUploading ?? false,
      progress: progress ?? _uploadStates[documentType]?.progress ?? 0.0,
      error: error,
    );
    notifyListeners();
  }

  void _updateDocument(String documentType, DocumentFile uploadedFile) {
    switch (documentType) {
      case 'saIdPassport': _saIdPassportImage = uploadedFile; break;
      case 'workPermit': _workPermit = uploadedFile; break;
      case 'proofOfResidence': _proofOfResidence = uploadedFile; break;
      case 'qualifications': _qualificationsCertificates = uploadedFile; break;
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

  Future<void> replaceDocument(String documentType) async {
    await deleteDocument(documentType);
    await pickFile(documentType);
  }

  Future<void> deleteDocument(String documentType) async {
    final document = _getDocumentByType(documentType);
    if (document != null && document.filePath.isNotEmpty) {
      try {
        // If it's a Firebase-stored document, delete from storage
        if (!document.filePath.contains('/tmp/') && _userId != null) {
          final success = await _documentService.deleteDocument(
            userId: _userId!,
            documentType: _getStorageDocumentType(documentType),
            filePath: document.filePath,
          );

          if (!success) throw 'Failed to delete document from storage';
        }

        // Remove from local state
        _removeDocument(documentType);
        await _saveDocumentState();
        _updateUploadState(documentType, isUploading: false, progress: 0.0);
        
        notifyListeners();
      } catch (e) {
        throw 'Failed to delete document: ${e.toString()}';
      }
    }
  }

  void _removeDocument(String documentType) {
    switch (documentType) {
      case 'saIdPassport': _saIdPassportImage = null; break;
      case 'workPermit': _workPermit = null; break;
      case 'proofOfResidence': _proofOfResidence = null; break;
      case 'qualifications': _qualificationsCertificates = null; break;
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

  bool _isValidFileType(PlatformFile file) {
    final fileName = file.name.toLowerCase();
    return fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || 
           fileName.endsWith('.png') || fileName.endsWith('.pdf') || 
           fileName.endsWith('.doc') || fileName.endsWith('.docx');
  }

  // ADD THIS METHOD: Local file type detection
  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final documentTypes = ['pdf', 'doc', 'docx', 'txt'];
    
    if (imageTypes.contains(extension)) return 'image';
    if (documentTypes.contains(extension)) return 'document';
    return 'file';
  }

  Future<void> _saveDocumentState() async {
    if (_saIdPassportImage != null) {
      await StatePersistenceService.saveDocument('saIdPassport', _saIdPassportImage!);
    }
    if (_workPermit != null) {
      await StatePersistenceService.saveDocument('workPermit', _workPermit!);
    }
    if (_proofOfResidence != null) {
      await StatePersistenceService.saveDocument('proofOfResidence', _proofOfResidence!);
    }
    if (_qualificationsCertificates != null) {
      await StatePersistenceService.saveDocument('qualifications', _qualificationsCertificates!);
    }
  }

  Future<void> loadSavedDocumentState() async {
    isLoading = true;
    try {
      _saIdPassportImage = await StatePersistenceService.loadDocument('saIdPassport');
      _workPermit = await StatePersistenceService.loadDocument('workPermit');
      _proofOfResidence = await StatePersistenceService.loadDocument('proofOfResidence');
      _qualificationsCertificates = await StatePersistenceService.loadDocument('qualifications');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved document state: $e'); // FIXED: Use debugPrint instead of print
    } finally {
      isLoading = false;
    }
  }

  UserModel updateUserWithDocuments(UserModel user) {
    return user.copyWith(
      saIdPassportImage: _saIdPassportImage,
      workPermit: _workPermit,
      proofOfResidence: _proofOfResidence,
      qualificationsCertificates: _qualificationsCertificates,
    );
  }

  Map<String, dynamic> getDocumentStatus(String documentType) {
    final document = _getDocumentByType(documentType);
    return {
      'hasDocument': document != null,
      'fileName': document?.fileName,
      'uploadedAt': document?.uploadedAt,
      'fileSize': document?.fileSizeFormatted,
    };
  }

  Future<void> clearAllDocuments() async {
    _saIdPassportImage = null;
    _workPermit = null;
    _proofOfResidence = null;
    _qualificationsCertificates = null;
    _userId = null;
    _localFilesCache.clear();
    _uploadStates.clear();

    await StatePersistenceService.clearAllData();
    notifyListeners();
  }

  void preloadDocumentsFromUser(UserModel user) {
    _saIdPassportImage = user.saIdPassportImage;
    _workPermit = user.workPermit;
    _proofOfResidence = user.proofOfResidence;
    _qualificationsCertificates = user.qualificationsCertificates;
    notifyListeners();
  }
}