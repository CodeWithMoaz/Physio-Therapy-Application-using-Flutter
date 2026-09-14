import 'dart:math';

class MedicalReportDataCleaner {
  static Map<String, dynamic> cleanData(Map<String, dynamic> extractedData) {
    final cleanedData = Map<String, dynamic>.from(extractedData);

    cleanedData.removeWhere((key, value) =>
        value == null ||
        (value is String && value.isEmpty) ||
        (value is List && value.isEmpty) ||
        (value is Map && value.isEmpty));

    cleanedData.forEach((key, value) {
      if (value is String) {
        final cleanValue = _cleanValueByFieldType(key, value);

        if (_isValueMeaningful(cleanValue)) {
          cleanedData[key] = cleanValue;
        } else {
          cleanedData.remove(key);
        }
      }
    });

    _consolidateDuplicateInformation(cleanedData);

    _inferMissingValues(cleanedData);

    cleanedData['metadata'] = {
      'processed_date': DateTime.now().toIso8601String(),
      'data_quality_score': _calculateDataQualityScore(cleanedData),
      'confidence_level': _calculateConfidenceLevel(cleanedData),
      'version': '2.0'
    };

    return cleanedData;
  }

  static double _calculateDataQualityScore(Map<String, dynamic> data) {
    double score = 0.0;
    int totalFields = 0;
    int filledFields = 0;

    final essentialFields = [
      'Patient Name',
      'Age',
      'Gender',
      'Date of Exam',
      'Report Type',
      'Findings',
      'Impression',
      'Diagnosis'
    ];

    for (final field in essentialFields) {
      totalFields++;
      if (data.containsKey(field) &&
          data[field] != null &&
          data[field].toString().isNotEmpty) {
        filledFields++;
      }
    }

    score = filledFields / totalFields;

    if (data.containsKey('Injury Location')) score += 0.1;
    if (data.containsKey('Injury Severity')) score += 0.1;
    if (data.containsKey('Recommendations')) score += 0.1;
    if (data.containsKey('Imaging Results')) score += 0.1;

    return score.clamp(0.0, 1.0);
  }

  static String _calculateConfidenceLevel(Map<String, dynamic> data) {
    final score = _calculateDataQualityScore(data);

    if (score >= 0.9) return 'High';
    if (score >= 0.7) return 'Medium';
    if (score >= 0.5) return 'Low';
    return 'Very Low';
  }

  static String _cleanValueByFieldType(String fieldName, String value) {
    String cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');

    cleaned = cleaned.replaceAll(
        RegExp(r'N/A|None|nil|not applicable', caseSensitive: false), '');

    switch (fieldName) {
      case 'Patient Name':
        cleaned = cleaned.replaceAll(
            RegExp(r'(Mr\.|Mrs\.|Dr\.|Miss|Ms\.)\s*', caseSensitive: false),
            '');
        cleaned = _toTitleCase(cleaned);
        break;

      case 'Age':
        cleaned = cleaned.replaceAll(RegExp(r'[^\d]'), '');
        break;

      case 'Gender':
        cleaned = cleaned.toLowerCase();
        if (cleaned.contains('m'))
          cleaned = 'Male';
        else if (cleaned.contains('f'))
          cleaned = 'Female';
        else
          cleaned = _toTitleCase(cleaned);
        break;

      case 'Date of Exam':
        try {
          final date = DateTime.parse(cleaned);
          cleaned = date.toIso8601String().split('T')[0];
        } catch (e) {}
        break;

      case 'Injury Severity':
        cleaned = cleaned.toLowerCase();
        if (cleaned.contains('mild'))
          cleaned = 'Mild';
        else if (cleaned.contains('moderate'))
          cleaned = 'Moderate';
        else if (cleaned.contains('severe'))
          cleaned = 'Severe';
        else
          cleaned = _toTitleCase(cleaned);
        break;

      case 'Findings':
      case 'Impression':
      case 'Diagnosis':
      case 'Recommendations':
        cleaned = cleaned.replaceAll(RegExp(r'\.\s*\.'), '.');
        cleaned = cleaned.replaceAll(RegExp(r'\s*,\s*'), ', ');
        break;
    }

    return cleaned;
  }

  static bool _isValueMeaningful(String value) {
    if (value.isEmpty) return false;

    if (value.length < 2) return false;

    final nonMeaningfulPatterns = [
      r'^[-\.,:;\s]*$',
      r'^N/?A$',
      r'^Unknown$',
      r'^Not (specified|available|applicable)$',
      r'^None$',
      r'^Nil$',
    ];

    for (final pattern in nonMeaningfulPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(value)) {
        return false;
      }
    }

    return true;
  }

  static void _consolidateDuplicateInformation(Map<String, dynamic> data) {
    final fieldGroups = [
      ['Findings', 'Observations', 'Key Findings', 'Imaging Results'],
      ['Impression', 'Diagnosis', 'Conclusion'],
      ['History', 'Clinical Information', 'Clinical History'],
      ['Recommendations', 'Clinical Exam'],
    ];

    for (final group in fieldGroups) {
      String combinedValue = '';
      String? primaryKey;

      for (final key in group) {
        if (data.containsKey(key) && data[key]!.isNotEmpty) {
          if (primaryKey == null) {
            primaryKey = key;
            combinedValue = data[key]!.toString();
          } else {
            if (!combinedValue.contains(data[key]!.toString())) {
              combinedValue = '$combinedValue ${data[key]!.toString()}';
            }

            data.remove(key);
          }
        }
      }

      if (primaryKey != null && combinedValue.isNotEmpty) {
        data[primaryKey] = combinedValue.trim();
      }
    }
  }

  static void _inferMissingValues(Map<String, dynamic> data) {
    if (!data.containsKey('Report Type') || data['Report Type']!.isEmpty) {
      if (data.containsKey('Procedure')) {
        final procedure = data['Procedure']!.toLowerCase();
        if (procedure.contains('mri')) {
          data['Report Type'] = 'MRI Report';
        } else if (procedure.contains('x-ray') || procedure.contains('xray')) {
          data['Report Type'] = 'X-Ray Report';
        } else if (procedure.contains('ct')) {
          data['Report Type'] = 'CT Scan Report';
        } else if (procedure.contains('ultrasound')) {
          data['Report Type'] = 'Ultrasound Report';
        }
      }
    }

    if (!data.containsKey('Injury Location') && data.containsKey('Findings')) {
      final bodyParts = [
        'shoulder',
        'knee',
        'ankle',
        'elbow',
        'wrist',
        'hip',
        'spine',
        'neck',
        'lower back',
        'upper back',
        'cervical',
        'lumbar',
        'thoracic',
        'hand',
        'foot',
        'leg',
        'arm'
      ];

      for (final part in bodyParts) {
        if (data['Findings']!.toLowerCase().contains(part)) {
          data['Injury Location'] = _toTitleCase(part);
          break;
        }
      }
    }
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return text;

    final words = text.split(' ');
    final capitalized = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });

    return capitalized.join(' ');
  }

  static Map<String, Map<String, dynamic>> categorizeData(
      Map<String, dynamic> cleanedData) {
    final Map<String, Map<String, dynamic>> categorizedData = {
      "Patient Information": {},
      "Clinical Information": {},
      "Medical Findings": {},
      "Diagnosis & Recommendations": {},
      "Provider Information": {},
    };

    final categoryMapping = {
      "Patient Information": [
        'Patient Name',
        'Age',
        'Gender',
        'Date of Exam',
        'Date',
        'Report Type'
      ],
      "Clinical Information": [
        'History',
        'Clinical Information',
        'Clinical History',
        'Clinical Exam',
        'Procedure',
        'Technique',
        'Comparison'
      ],
      "Medical Findings": [
        'Findings',
        'Observations',
        'Imaging Results',
        'Key Findings',
        'Injury Location',
        'Injury Severity'
      ],
      "Diagnosis & Recommendations": [
        'Impression',
        'Diagnosis',
        'Conclusion',
        'Recommendations'
      ],
      "Provider Information": [
        'Physician',
        'Referred By',
        'Doctor',
        'Radiologist'
      ],
    };

    cleanedData.forEach((key, value) {
      bool fieldAssigned = false;

      for (final category in categoryMapping.keys) {
        if (categoryMapping[category]!.any((field) =>
            field.toLowerCase() == key.toLowerCase() ||
            key.toLowerCase().contains(field.toLowerCase()))) {
          categorizedData[category]![key] = value;
          fieldAssigned = true;
          break;
        }
      }

      if (!fieldAssigned) {
        if (key.toLowerCase().contains('patient') ||
            key.toLowerCase().contains('name') ||
            key.toLowerCase().contains('age')) {
          categorizedData["Patient Information"]![key] = value;
        } else if (key.toLowerCase().contains('finding') ||
            key.toLowerCase().contains('observation')) {
          categorizedData["Medical Findings"]![key] = value;
        } else if (key.toLowerCase().contains('recommend') ||
            key.toLowerCase().contains('diagnosis') ||
            key.toLowerCase().contains('impression')) {
          categorizedData["Diagnosis & Recommendations"]![key] = value;
        } else if (key.toLowerCase().contains('doctor') ||
            key.toLowerCase().contains('physician')) {
          categorizedData["Provider Information"]![key] = value;
        } else {
          categorizedData["Clinical Information"]![key] = value;
        }
      }
    });

    categorizedData.removeWhere((key, value) => value.isEmpty);

    return categorizedData;
  }
}
