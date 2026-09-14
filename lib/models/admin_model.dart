import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String id;
  final String fullName;
  final String email;

  AdminModel({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AdminModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'email': email,
    };
  }

  AdminModel copyWith({
    String? fullName,
    String? email,
  }) {
    return AdminModel(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
    );
  }
}
