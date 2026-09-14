import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String gender;
  final DateTime dob;
  final double weight;
  final double height;
  final String? profileImage;
  final Map<String, dynamic> enrolledPrograms;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.dob,
    required this.weight,
    required this.height,
    this.profileImage,
    required this.enrolledPrograms,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Map<String, dynamic> enrolledProgramsData = {};
    if (data['enrolledPrograms'] is Map) {
      enrolledProgramsData =
          Map<String, dynamic>.from(data['enrolledPrograms']);
    }

    enrolledProgramsData.forEach((programId, programData) {
      if (programData is Map) {
        if (!programData.containsKey('plan') || !(programData['plan'] is Map)) {
          programData['plan'] = <String, List<String>>{};
        } else {
          final planMap = Map<String, dynamic>.from(programData['plan']);
          programData['plan'] = planMap.map((day, exercises) =>
              MapEntry(day, List<String>.from(exercises ?? [])));
        }
      } else {
        enrolledProgramsData[programId] = {
          'enrolledAt': null,
          'progress': 0.0,
          'lastVisit': null,
          'lastCompletedDay': 0,
          'plan': <String, List<String>>{},
        };
      }
    });

    return UserModel(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      dob: (data['dob'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      height: (data['height'] as num?)?.toDouble() ?? 0.0,
      profileImage: data['profileImage'],
      enrolledPrograms: enrolledProgramsData,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> enrolledProgramsData = {};
    enrolledPrograms.forEach((programId, programData) {
      if (programData is Map) {
        enrolledProgramsData[programId] = Map.from(programData);
        if (enrolledProgramsData[programId].containsKey('plan') &&
            enrolledProgramsData[programId]['plan'] is Map) {
          (enrolledProgramsData[programId]['plan'] as Map)
              .forEach((day, exercises) {
            if (exercises is List) {
              enrolledProgramsData[programId]['plan'][day] =
                  exercises.map((e) => e.toString()).toList();
            } else {
              enrolledProgramsData[programId]['plan'][day] = <String>[];
            }
          });
        } else {
          enrolledProgramsData[programId]['plan'] = <String, List<String>>{};
        }
      } else {
        enrolledProgramsData[programId] = {
          'enrolledAt': null,
          'progress': 0.0,
          'lastVisit': null,
          'lastCompletedDay': 0,
          'plan': <String, List<String>>{},
        };
      }
    });

    return {
      'fullName': fullName,
      'email': email,
      'gender': gender,
      'dob': Timestamp.fromDate(dob),
      'weight': weight,
      'height': height,
      'profileImage': profileImage,
      'enrolledPrograms': enrolledProgramsData,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? gender,
    DateTime? dob,
    double? weight,
    double? height,
    String? profileImage,
    Map<String, dynamic>? enrolledPrograms,
  }) {
    return UserModel(
      id: this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      profileImage: profileImage ?? this.profileImage,
      enrolledPrograms: enrolledPrograms ??
          Map.from(this.enrolledPrograms), // Deep copy for the map
    );
  }
}
