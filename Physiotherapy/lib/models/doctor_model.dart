import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorModel {
  final String id;
  final String fullName;
  final String email;
  final String specialization;
  final int yearsOfExperience;
  final String? certificate;
  final String? additionalInformation;
  final bool isVerified;
  final DateTime createdAt;
  final String status;
  final String? profileImage;
  final List<String> programsManaged;
  final String gender;

  DoctorModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.specialization,
    required this.yearsOfExperience,
    this.certificate,
    this.additionalInformation,
    this.isVerified = false,
    required this.createdAt,
    this.status = 'pending',
    this.profileImage,
    this.programsManaged = const [],
    this.gender = 'Not Specified',
  });

  factory DoctorModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return DoctorModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      specialization: data['specialization'] ?? '',
      yearsOfExperience: data['yearsOfExperience'] ?? 0,
      certificate: data['certificate'],
      additionalInformation: data['additionalInformation'],
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      profileImage: data['profileImage'],
      programsManaged: List<String>.from(data['programsManaged'] ?? []),
      gender: data['gender'] ?? 'Not Specified',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
      'specialization': specialization,
      'yearsOfExperience': yearsOfExperience,
      'certificate': certificate,
      'additionalInformation': additionalInformation,
      'isVerified': isVerified,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status,
      'profileImage': profileImage,
      'programsManaged': programsManaged,
      'gender': gender,
    };
  }

  DoctorModel copyWith({
    String? fullName,
    String? email,
    String? specialization,
    int? yearsOfExperience,
    String? certificate,
    String? additionalInformation,
    bool? isVerified,
    DateTime? createdAt,
    String? status,
    String? profileImage,
    List<String>? programsManaged,
    String? gender,
  }) {
    return DoctorModel(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      certificate: certificate ?? this.certificate,
      additionalInformation:
          additionalInformation ?? this.additionalInformation,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      programsManaged: programsManaged ?? this.programsManaged,
      gender: gender ?? this.gender,
    );
  }
}
