import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cc_evs/models/user_model.dart';

class DocumentService {
  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

  DocumentService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  }) : 
    _storage = storage ?? FirebaseStorage.instance,
    _firestore = firestore ?? FirebaseFirestore.instance;

  Future<FilePickerResult?> pickFile() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        allowMultiple: false,
      );
    } catch (e) {
      throw Exception('Error picking file: $e');
    }
  }

  Future<DocumentFile?> uploadDocument({
    required String userId,
    required String documentType,
    required PlatformFile platformFile,
    void Function(double progress)? onProgress,
  }) async {
    try {
      // Validate file before upload
      if (!isFileSizeValid(platformFile)) {
        throw Exception('File size exceeds 10MB limit');
      }
      
      if (!isFileTypeAllowed(platformFile.name)) {
        throw Exception('File type not allowed. Please use JPG, PNG, PDF, DOC, or DOCX');
      }
      
      if (platformFile.path == null) {
        throw Exception('Invalid file path');
      }

      final file = File(platformFile.path!);
      
      // Create unique file name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = platformFile.name.split('.').last.toLowerCase();
      final uniqueFileName = '${documentType}_$timestamp.$fileExtension';
      final storagePath = 'users/$userId/documents/$uniqueFileName';

      // Upload to Firebase Storage
      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask = storageRef.putFile(file);
      
      // Listen for progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // Create DocumentFile
      final documentFile = DocumentFile(
        fileName: platformFile.name,
        filePath: storagePath,
        fileUrl: downloadUrl,
        fileSize: platformFile.size,
        fileType: _getFileType(platformFile.name),
        uploadedAt: DateTime.now(),
      );

      // Update user document in Firestore
      await _updateUserDocument(userId, documentType, documentFile);

      return documentFile;
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }

  Future<void> _updateUserDocument(
    String userId, 
    String documentType, 
    DocumentFile documentFile
  ) async {
    final fieldMap = {
      'saIdPassportImage': 'saIdPassportImage',
      'workPermit': 'workPermit',
      'proofOfResidence': 'proofOfResidence',
      'qualificationsCertificates': 'qualificationsCertificates',
    };

    final fieldName = fieldMap[documentType];
    if (fieldName == null) throw Exception('Invalid document type: $documentType');

    await _firestore
        .collection('users')
        .doc(userId)
        .update({
          fieldName: documentFile.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<bool> deleteDocument({
    required String userId,
    required String documentType,
    required String filePath,
  }) async {
    try {
      // Delete from Firebase Storage
      await _storage.ref().child(filePath).delete();

      // Remove document reference from user model
      final fieldMap = {
        'saIdPassportImage': 'saIdPassportImage',
        'workPermit': 'workPermit',
        'proofOfResidence': 'proofOfResidence',
        'qualificationsCertificates': 'qualificationsCertificates',
      };

      final fieldName = fieldMap[documentType];
      if (fieldName != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .update({
              fieldName: FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      return true;
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final documentTypes = ['pdf', 'doc', 'docx', 'txt'];
    
    if (imageTypes.contains(extension)) return 'image';
    if (documentTypes.contains(extension)) return 'document';
    return 'file';
  }

  bool isFileSizeValid(PlatformFile file) {
    return file.size <= 10 * 1024 * 1024; // 10MB in bytes
  }

  bool isFileTypeAllowed(String fileName) {
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'];
    final extension = fileName.toLowerCase().split('.').last;
    return allowedExtensions.contains(extension);
  }

  double getFileSizeInMB(PlatformFile file) {
    return file.size / (1024 * 1024);
  }
}