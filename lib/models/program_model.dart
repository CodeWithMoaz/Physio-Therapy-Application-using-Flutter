import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramModel {
  final String programId;
  final String programName;
  final String injury;
  final String severity;
  final int maxPatients;
  final String ageGroup;
  final String duration;
  final String description;
  final double price;

  static const List<String> injuryTypes = ['Knee', 'Ankle', 'Shoulder', 'Back'];

  static const List<String> severityLevels = [
    '1st Degree',
    '2nd Degree',
    '3rd Degree'
  ];

  ProgramModel({
    required this.programId,
    required this.programName,
    required this.injury,
    required this.severity,
    required this.maxPatients,
    required this.ageGroup,
    required this.duration,
    required this.description,
    required this.price,
  });

  factory ProgramModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ProgramModel(
      programId: doc.id,
      programName: data['programName'] ?? '',
      injury: data['injury'] ?? '',
      severity: data['severity'] ?? '1st Degree',
      maxPatients: (data['maxPatients'] as num?)?.toInt() ?? 0,
      ageGroup: data['ageGroup'] ?? '',
      duration: data['duration'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'programName': programName,
      'injury': injury,
      'severity': severity,
      'maxPatients': maxPatients,
      'ageGroup': ageGroup,
      'duration': duration,
      'description': description,
      'price': price,
    };
  }

  ProgramModel copyWith({
    String? programName,
    String? injury,
    String? severity,
    int? maxPatients,
    String? ageGroup,
    String? duration,
    String? description,
    double? price,
  }) {
    return ProgramModel(
      programId: this.programId,
      programName: programName ?? this.programName,
      injury: injury ?? this.injury,
      severity: severity ?? this.severity,
      maxPatients: maxPatients ?? this.maxPatients,
      ageGroup: ageGroup ?? this.ageGroup,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      price: price ?? this.price,
    );
  }
}
