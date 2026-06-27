// models/document_model.dart
class DocumentModel {
  final String id;
  final String type;
  final String fileName;
  final String fileUrl;
  final String filePath;
  final DateTime uploadedAt;
  final String userId;

  DocumentModel({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.filePath,
    required this.uploadedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'filePath': filePath,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      fileName: map['fileName'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      filePath: map['filePath'] ?? '',
      uploadedAt: map['uploadedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'])
          : DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }
}