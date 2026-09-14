class InjuryClassification {
  final String injuryName;
  final String description;
  final List<String> symptoms;
  final List<String> supportingEvidence;
  final List<String> recommendations;
  final String severity;
  final String bodyPart;
  final DateTime diagnosisDate;
  final List<String> contraindications;
  final Map<String, dynamic> recoveryMetrics;

  InjuryClassification({
    required this.injuryName,
    required this.description,
    required this.symptoms,
    required this.supportingEvidence,
    required this.recommendations,
    this.severity = 'Unknown',
    this.bodyPart = 'Unknown',
    DateTime? diagnosisDate,
    List<String>? contraindications,
    Map<String, dynamic>? recoveryMetrics,
  })  : this.diagnosisDate = diagnosisDate ?? DateTime.now(),
        this.contraindications = contraindications ?? [],
        this.recoveryMetrics = recoveryMetrics ??
            {
              'expectedRecoveryTime': 'Unknown',
              'successRate': 0.0,
              'riskLevel': 'Unknown',
              'recurrenceRate': 0.0
            };

  factory InjuryClassification.fromMap(Map<String, dynamic> map) {
    return InjuryClassification(
      injuryName: map['injury_name'] ?? 'Unknown Injury',
      description: map['description'] ?? 'No description available.',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      supportingEvidence: List<String>.from(map['supporting_evidence'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      severity: map['severity'] ?? 'Unknown',
      bodyPart: map['body_part'] ?? 'Unknown',
      diagnosisDate: map['diagnosis_date'] != null
          ? DateTime.parse(map['diagnosis_date'])
          : DateTime.now(),
      contraindications: List<String>.from(map['contraindications'] ?? []),
      recoveryMetrics: Map<String, dynamic>.from(map['recovery_metrics'] ??
          {
            'expectedRecoveryTime': 'Unknown',
            'successRate': 0.0,
            'riskLevel': 'Unknown',
            'recurrenceRate': 0.0
          }),
    );
  }

  factory InjuryClassification.empty() {
    return InjuryClassification(
      injuryName: 'Unknown Injury',
      description: 'No description available.',
      symptoms: [],
      supportingEvidence: [],
      recommendations: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'injury_name': injuryName,
      'description': description,
      'symptoms': symptoms,
      'supporting_evidence': supportingEvidence,
      'recommendations': recommendations,
      'severity': severity,
      'body_part': bodyPart,
      'diagnosis_date': diagnosisDate.toIso8601String(),
      'contraindications': contraindications,
      'recovery_metrics': recoveryMetrics,
    };
  }

  double getRecoveryProgress() {
    if (recoveryMetrics['successRate'] != null) {
      return recoveryMetrics['successRate'] as double;
    }
    return 0.0;
  }

  bool get isSevere => severity.toLowerCase() == 'severe';

  String get expectedRecoveryTime =>
      recoveryMetrics['expectedRecoveryTime'] ?? 'Unknown';

  String get riskLevel => recoveryMetrics['riskLevel'] ?? 'Unknown';
}
