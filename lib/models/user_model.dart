import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? uid;
  final String firstName;
  final String lastName;
  final String idOrPassportNo;
  final String phoneNumber;
  final String email;
  final String? employeeNumber;
  final String? department;
  final LocationType? location;
  final String? site;
  final String? office;
  final DocumentFile? saIdPassportImage;
  final DocumentFile? workPermit;
  final DocumentFile? proofOfResidence;
  final DocumentFile? qualificationsCertificates;
  final bool isOTPVerified;
  final bool isBiometricCompleted;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    this.uid,
    required this.firstName,
    required this.lastName,
    required this.idOrPassportNo,
    required this.phoneNumber,
    required this.email,
    this.employeeNumber,
    this.department,
    this.location,
    this.site,
    this.office,
    this.saIdPassportImage,
    this.workPermit,
    this.proofOfResidence,
    this.qualificationsCertificates,
    this.isOTPVerified = false,
    this.isBiometricCompleted = false,
    this.isVerified = false,
    this.createdAt,
    this.updatedAt,
  }) : assert(firstName.isNotEmpty && lastName.isNotEmpty && phoneNumber.isNotEmpty);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'idOrPassportNo': idOrPassportNo,
      'phoneNumber': phoneNumber,
      'email': email.toLowerCase(),
      'employeeNumber': employeeNumber,
      'department': department,
      'location': location?.toString().split('.').last,
      'site': site,
      'office': office,
      'isOTPVerified': isOTPVerified,
      'isBiometricCompleted': isBiometricCompleted,
      'isVerified': isVerified,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (saIdPassportImage != null) {
      map['saIdPassportImage'] = saIdPassportImage!.toMap();
    }
    if (workPermit != null) {
      map['workPermit'] = workPermit!.toMap();
    }
    if (proofOfResidence != null) {
      map['proofOfResidence'] = proofOfResidence!.toMap();
    }
    if (qualificationsCertificates != null) {
      map['qualificationsCertificates'] = qualificationsCertificates!.toMap();
    }

    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      idOrPassportNo: map['idOrPassportNo'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      employeeNumber: map['employeeNumber'],
      department: map['department'],
      location: _parseLocation(map['location']),
      site: map['site'],
      office: map['office'],
      saIdPassportImage: map['saIdPassportImage'] != null 
          ? DocumentFile.fromMap(map['saIdPassportImage']) 
          : null,
      workPermit: map['workPermit'] != null 
          ? DocumentFile.fromMap(map['workPermit']) 
          : null,
      proofOfResidence: map['proofOfResidence'] != null 
          ? DocumentFile.fromMap(map['proofOfResidence']) 
          : null,
      qualificationsCertificates: map['qualificationsCertificates'] != null 
          ? DocumentFile.fromMap(map['qualificationsCertificates']) 
          : null,
      isOTPVerified: map['isOTPVerified'] ?? false,
      isBiometricCompleted: map['isBiometricCompleted'] ?? false,
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static LocationType? _parseLocation(String? location) {
    if (location == null) return null;
    switch (location) {
      case 'site': return LocationType.site;
      case 'office': return LocationType.office;
      default: return null;
    }
  }

  UserModel copyWith({
    String? uid,
    String? firstName,
    String? lastName,
    String? idOrPassportNo,
    String? phoneNumber,
    String? email,
    String? employeeNumber,
    String? department,
    LocationType? location,
    String? site,
    String? office,
    DocumentFile? saIdPassportImage,
    DocumentFile? workPermit,
    DocumentFile? proofOfResidence,
    DocumentFile? qualificationsCertificates,
    bool? isOTPVerified,
    bool? isBiometricCompleted,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      idOrPassportNo: idOrPassportNo ?? this.idOrPassportNo,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      department: department ?? this.department,
      location: location ?? this.location,
      site: site ?? this.site,
      office: office ?? this.office,
      saIdPassportImage: saIdPassportImage ?? this.saIdPassportImage,
      workPermit: workPermit ?? this.workPermit,
      proofOfResidence: proofOfResidence ?? this.proofOfResidence,
      qualificationsCertificates: qualificationsCertificates ?? this.qualificationsCertificates,
      isOTPVerified: isOTPVerified ?? this.isOTPVerified,
      isBiometricCompleted: isBiometricCompleted ?? this.isBiometricCompleted,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  bool get hasEmployeeDetails {
    return employeeNumber != null && 
           employeeNumber!.isNotEmpty &&
           department != null && 
           department!.isNotEmpty &&
           location != null;
  }

  bool get hasDocuments => saIdPassportImage != null;

  bool get hasPersonalDetails {
    return firstName.isNotEmpty &&
           lastName.isNotEmpty &&
           idOrPassportNo.isNotEmpty &&
           phoneNumber.isNotEmpty &&
           email.isNotEmpty;
  }

  String get fullName => '$firstName $lastName';

  bool get isComplete => hasPersonalDetails && hasEmployeeDetails && hasDocuments;

  bool get hasValidLocation {
    return location != null && 
           ((location == LocationType.site && site != null && site!.isNotEmpty) ||
            (location == LocationType.office && office != null && office!.isNotEmpty));
  }
}

class DocumentFile {
  final String fileName;
  final String filePath;
  final String fileUrl;
  final int fileSize;
  final String fileType;
  final DateTime uploadedAt;

  DocumentFile({
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'filePath': filePath,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'fileType': fileType,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory DocumentFile.fromMap(Map<String, dynamic> map) {
    return DocumentFile(
      fileName: map['fileName'] ?? '',
      filePath: map['filePath'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileSize: map['fileSize'] ?? 0,
      fileType: map['fileType'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }

  bool get isValid => fileUrl.isNotEmpty && uploadedAt.isBefore(DateTime.now());
  
  bool get isImage {
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    final extension = fileName.toLowerCase().split('.').last;
    return imageTypes.contains(extension);
  }

  DocumentType get documentType {
    final name = fileName.toLowerCase();
    if (name.contains('id') || name.contains('passport')) return DocumentType.id;
    if (name.contains('work') || name.contains('permit')) return DocumentType.workPermit;
    if (name.contains('residence') || name.contains('proof')) return DocumentType.proofOfResidence;
    if (name.contains('qualification') || name.contains('certificate')) return DocumentType.qualification;
    return DocumentType.other;
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1048576) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
  }
}

enum DocumentType { id, workPermit, proofOfResidence, qualification, other }

enum LocationType { site, office }

extension LocationTypeExtension on LocationType {
  String get displayName {
    switch (this) {
      case LocationType.site: return 'Site';
      case LocationType.office: return 'Office';
    }
  }
}