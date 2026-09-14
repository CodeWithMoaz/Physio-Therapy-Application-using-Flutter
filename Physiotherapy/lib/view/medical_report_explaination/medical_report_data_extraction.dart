import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:physiotherapy/common_widget/small_round_button.dart';
import 'package:physiotherapy/api_service/API_services.dart';
import 'package:physiotherapy/api_service/injury_classification.dart';
import 'package:physiotherapy/api_service/api_config.dart';
import 'package:physiotherapy/view/medical_report_explaination/classification.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:physiotherapy/view/medical_report_explaination/medical_report_data_cleaner.dart';
import 'dart:math' as math;

import '../../common/color_extension.dart';
import '../../common_widget/round_button.dart';

class MriClassificationView extends StatefulWidget {
  const MriClassificationView({super.key});

  @override
  State<MriClassificationView> createState() => _MriClassificationViewState();
}

class _MriClassificationViewState extends State<MriClassificationView>
    with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isLoading = false;
  String? _extractedText;
  Map<String, dynamic> _extractedData = {};
  bool _isProcessed = false;
  bool _isAnalyzingWithAI = false;
  Map<String, dynamic>? _injuryClassification;
  bool _isInjuryClassificationFailed = false;

  late final OpenRouterService _openRouterService;
  bool _isApiKeyConfigured = false;

  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  final List<Color> _gradientColors = [
    const Color(0xFF6F72CA),
    const Color(0xFF1E1466),
  ];

  @override
  void initState() {
    super.initState();
    _checkApiConfiguration();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _checkApiConfiguration() async {
    bool isConfigured = ApiConfig.isApiKeyConfigured();

    if (isConfigured) {
      _openRouterService = OpenRouterService(apiKey: ApiConfig.getApiKey());
    }

    setState(() {
      _isApiKeyConfigured = isConfigured;
    });
  }

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
    });

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _isProcessed = false;
          _extractedText = null;
          _extractedData = {};
          _injuryClassification = null;
          _isInjuryClassificationFailed = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a medical report first'),
          backgroundColor: Colors.orange.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _isInjuryClassificationFailed = false;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/extract-text/'),
      );

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _selectedImage!.path,
      ));
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      print("Response: $responseData");
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _extractedText = jsonResponse['extracted_text'];
          _isProcessed = true;

          if (jsonResponse.containsKey('parsed_data')) {
            var parsedData = jsonResponse['parsed_data'];

            Map<String, String> rawData = {
              'Patient Name': parsedData['patient_name'] ?? '',
              'Age': parsedData['patient_age'] ?? '',
              'Gender': parsedData['patient_sex'] ?? '',
              'Date of Exam': parsedData['date_of_exam'] ?? '',
              'Report Type': _determineReportType(parsedData),
              'Technique': parsedData['technique'] ?? '',
              'Findings': parsedData['findings'] ?? '',
              'Impression': parsedData['impression'] ?? '',
              'Diagnosis': parsedData['diagnosis'] ?? '',
              'Recommendations': parsedData['recommendations'] ?? '',
              'Referred By': parsedData['referred_by'] ?? '',
              'Injury Location': parsedData['injury_location'] ?? '',
              'Injury Severity': parsedData['injury_severity'] ?? '',
              'Imaging Results': parsedData['imaging_results'] ?? '',
              'Physician': parsedData['physician_name'] ?? '',
              'History': parsedData['history'] ?? '',
              'Clinical Exam': parsedData['clinical_exam'] ?? '',
              'Procedure': parsedData['procedure'] ?? '',
              'Comparison': parsedData['comparison'] ?? '',
              'Conclusion': parsedData['conclusion'] ?? '',
              'Clinical Information': parsedData['clinical_information'] ?? '',
              'Observations': parsedData['observations'] ?? '',
            };

            _extractedData = MedicalReportDataCleaner.cleanData(rawData);
          } else {
            _extractData(_extractedText!);
          }
        });

        await _analyzeWithOpenRouter();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${jsonResponse['error'] ?? "Unknown error"}'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error processing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _analyzeWithOpenRouter() async {
    if (_extractedData.isEmpty) {
      return;
    }

    setState(() {
      _isAnalyzingWithAI = true;
      _isInjuryClassificationFailed = false;
    });

    try {
      if (!_isApiKeyConfigured) {
        throw Exception("OpenRouter API key is not configured in .env file");
      }

      final InjuryClassification injuryData =
          await _openRouterService.classifyInjury(_extractedData);

      if (injuryData.injuryName == null ||
          injuryData.injuryName.isEmpty ||
          injuryData.injuryName.toLowerCase() == "unknown" ||
          injuryData.injuryName.toLowerCase() == "unidentified" ||
          injuryData.injuryName.toLowerCase().contains("unknown injury")) {
        setState(() {
          _isInjuryClassificationFailed = true;
          _injuryClassification = null;
          _isAnalyzingWithAI = false;
        });
        return;
      }

      setState(() {
        _injuryClassification = {
          'injury_name': injuryData.injuryName,
          'description': injuryData.description,
          'symptoms': injuryData.symptoms,
          'supporting_evidence': injuryData.supportingEvidence,
          'recommendations': injuryData.recommendations,
        };
        _isAnalyzingWithAI = false;
      });
    } catch (e) {
      print('Error analyzing with OpenRouter: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing injury: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() {
        _isAnalyzingWithAI = false;
        _isInjuryClassificationFailed = true;
      });
    }
  }

  String _determineReportType(Map<String, dynamic> data) {
    if (data['procedure'] != null &&
        data['procedure'].toString().contains('MRI')) {
      return 'MRI Report';
    } else if (data['technique'] != null &&
        data['technique'].toString().contains('X-ray')) {
      return 'X-Ray Report';
    } else if (data['technique'] != null &&
        data['technique'].toString().contains('CT')) {
      return 'CT Scan Report';
    } else {
      return 'Medical Report';
    }
  }

  void _extractData(String text) {
    final patternDict = {
      'Patient Name': RegExp(
          r"(?:PatientName|Patient Name|Name|Patient)\s*(?:\[|:)\s*([A-Za-z\s]+)",
          caseSensitive: false),
      'Age':
          RegExp(r"Age\s*:\s*(\d+\s*(?:Y|Years|Year)?)", caseSensitive: false),
      'Gender': RegExp(r"(?:Sex|Gender)\s*:\s*(\w+)", caseSensitive: false),
      'Technique': RegExp(
          r"(?:TECHNIQUE:|TECHNIQUE|Protocol):\s*(.*?)(?=\s*(?:OBSERVATION:|FINDINGS:|$))",
          multiLine: true,
          caseSensitive: false),
      'Findings': RegExp(
          r"(?:FINDINGS:|Findings:)\s*(.*?)(?=\s*(?:IMPRESSION:|Impression:|$))",
          multiLine: true,
          caseSensitive: false),
      'Impression': RegExp(
          r"(?:IMPRESSION:|Impression:)\s*(.*?)(?=\s*(?:Adv\.|$))",
          multiLine: true,
          caseSensitive: false),
      'Referred By': RegExp(
          r"(?:Referred by|Referring Physician)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          caseSensitive: false),
      'Injury Location': RegExp(
          r"(?:Injury Location|Site of pain|Region|Area)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          caseSensitive: false),
      'Injury Severity': RegExp(
          r"Injury Severity\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          caseSensitive: false),
      'Imaging Results': RegExp(
          r"Imaging Results\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          multiLine: true,
          caseSensitive: false),
      'Diagnosis': RegExp(
          r"(?:Diagnosis|Assessment)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          caseSensitive: false),
      'Recommendations': RegExp(
          r"(?:Adv\.|Recommendations|Plan|Treatment)\s*(.*?)(?=\s*(?:Reported by|$))",
          multiLine: true,
          caseSensitive: false),
      'Date of Exam': RegExp(
          r"(?:Report Time|Date|Exam Date)\s*(?::|=)?\s*([\d/\-\.]+(?:\s*[\d:]+)?)",
          caseSensitive: false),
      'Physician': RegExp(r"(?:DR\.|Doctor|Physician|Radiologist)\s*([^,\n]+)",
          caseSensitive: false),
      'History': RegExp(
          r"(?:History|Clinical History)\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          multiLine: true,
          caseSensitive: false),
      'Clinical Exam': RegExp(r"Clinical Exam\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          multiLine: true, caseSensitive: false),
      'Procedure': RegExp(
          r"(?:MRI of|MRI OF|MRI -|Examination|Procedure)\s*(.*?)(?=\s*\d|\n|Clinical|$)",
          caseSensitive: false),
      'Comparison': RegExp(r"Comparison\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          multiLine: true, caseSensitive: false),
      'Conclusion': RegExp(r"Conclusion\s*(?::|=)?\s*([^\.]+?)(?=\.|$)",
          multiLine: true, caseSensitive: false),
      'Clinical Information': RegExp(
          r"(?:Clinical Information|History|Clinical)\s*(?::|=)?\s*([^\.]+?)(?=\.|Findings:|$)",
          multiLine: true,
          caseSensitive: false),
      'Observations': RegExp(
          r"(?:OBSERVATION:|Observations:)\s*(.*?)(?=\s*(?:IMPRESSION:|Conclusion:|$))",
          multiLine: true,
          caseSensitive: false),
    };

    Map<String, String> rawData = {};
    patternDict.forEach((key, pattern) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        rawData[key] = match.group(1)!.trim();
      } else {
        rawData[key] = '';
      }
    });

    if (text.contains('MRI') ||
        (rawData['Procedure']?.contains('MRI') ?? false)) {
      rawData['Report Type'] = 'MRI Report';
    } else if (text.contains('X-ray') ||
        text.contains('X ray') ||
        (rawData['Technique']?.contains('X-ray') ?? false)) {
      rawData['Report Type'] = 'X-Ray Report';
    } else if (text.contains('CT Scan') ||
        (rawData['Technique']?.contains('CT') ?? false)) {
      rawData['Report Type'] = 'CT Scan Report';
    } else {
      rawData['Report Type'] = 'Medical Report';
    }

    setState(() {
      _extractedData = MedicalReportDataCleaner.cleanData(rawData);
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    bool showLoadingIndicator = _isLoading || _isAnalyzingWithAI;

    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.lerp(
                        const Color(0xffA882DD).withOpacity(0.1),
                        const Color(0xff6d6492).withOpacity(0.1),
                        _animationController.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.05),
                        const Color(0xffA882DD).withOpacity(0.15),
                        _animationController.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),
          ...List.generate(4, (index) {
            return AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Positioned(
                  top: 100 +
                      (index * 150) +
                      (20 *
                          math.sin(
                              _floatingController.value * 2 * math.pi + index)),
                  left: (index.isEven ? -30 : media.width - 70) +
                      (15 *
                          math.cos(
                              _floatingController.value * 2 * math.pi + index)),
                  child: Container(
                    width: 60 + (index * 8),
                    height: 60 + (index * 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TColor.primaryColor1.withOpacity(0.1),
                          const Color(0xffA882DD).withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
          SafeArea(
            child: Container(
              width: media.width,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: TColor.gray.withOpacity(0.1),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                            border: Border.all(
                              color: TColor.gray.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: TColor.primaryColor1,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: media.width * 0.03),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: _gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              "Medical Report Analysis",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: media.width * 0.02),
                          Text(
                            "Upload your medical report to extract important information for your therapy plan",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: TColor.gray,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: media.width * 0.05),
                  Expanded(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: showLoadingIndicator
                          ? _buildLoadingView()
                          : (_isProcessed
                              ? _buildResultsView(media)
                              : _buildUploadView(media)),
                    ),
                  ),
                  SizedBox(height: media.width * 0.02),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: TColor.primaryColor1.withOpacity(0.3),
                            offset: const Offset(0, 8),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: RoundButton(
                        title: _isProcessed
                            ? (_isInjuryClassificationFailed
                                ? "Upload Clearer Image"
                                : (!_isApiKeyConfigured
                                    ? "View Extracted Data"
                                    : (_injuryClassification != null
                                        ? "View Classification Results"
                                        : "Processing...")))
                            : "Process Medical Report",
                        onPressed: showLoadingIndicator
                            ? null
                            : (_isProcessed
                                ? (_isInjuryClassificationFailed ||
                                        !_isApiKeyConfigured ||
                                        (_injuryClassification != null &&
                                            _injuryClassification![
                                                    'injury_name']
                                                .toString()
                                                .toLowerCase()
                                                .contains("unknown"))
                                    ? () {
                                        if (_isInjuryClassificationFailed ||
                                            (_injuryClassification != null &&
                                                _injuryClassification![
                                                        'injury_name']
                                                    .toString()
                                                    .toLowerCase()
                                                    .contains("unknown"))) {
                                          setState(() {
                                            _isProcessed = false;
                                            _extractedText = null;
                                            _extractedData = {};
                                            _injuryClassification = null;
                                            _isInjuryClassificationFailed =
                                                false;
                                          });
                                          _pickImage();
                                        } else if (!_isApiKeyConfigured) {
                                          _showApiKeyDialog();
                                        }
                                      }
                                    : () {
                                        print(
                                            "Passing to ClassificationView: ${_injuryClassification.toString()}");
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ClassificationView(
                                              injuryData: _injuryClassification,
                                              extractedData: _extractedData,
                                            ),
                                          ),
                                        );
                                      })
                                : _processImage),
                      ),
                    ),
                  ),
                  SizedBox(height: media.width * 0.04),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TColor.primaryColor1.withOpacity(0.3),
                  TColor.primaryColor2.withOpacity(0.3),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: TColor.primaryColor1,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: Text(
              _isAnalyzingWithAI
                  ? "Analyzing report with AI..."
                  : "Processing image...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _isAnalyzingWithAI
                ? "Our AI is analyzing your medical report for injury classification"
                : "Extracting text and data from your medical report",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadView(Size media) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: media.width * 0.05),
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: media.width * 0.85,
                height: media.width * 0.9,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: TColor.primaryColor1.withOpacity(0.3), width: 2),
                  gradient: _selectedImage != null
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            TColor.lightGray.withOpacity(0.1),
                            TColor.primaryColor1.withOpacity(0.05),
                          ],
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: TColor.primaryColor1.withOpacity(0.1),
                      offset: const Offset(0, 10),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  TColor.primaryColor1.withOpacity(0.1),
                                  TColor.primaryColor2.withOpacity(0.1),
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.file_upload_outlined,
                              size: 50,
                              color: TColor.primaryColor1,
                            ),
                          ),
                          SizedBox(height: 20),
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: _gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              "Tap to upload report",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(Size media) {
    final categorizedData =
        MedicalReportDataCleaner.categorizeData(_extractedData);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: media.width * 0.03),
          if (_isInjuryClassificationFailed) ...[
            SizedBox(height: media.width * 0.04),
            _buildDiagnosticLimitations(media),
          ],
          if (_injuryClassification != null &&
              !_injuryClassification!['injury_name']
                  .toString()
                  .toLowerCase()
                  .contains("unknown")) ...[
            SizedBox(height: media.width * 0.04),
            _buildClassificationResults(media),
          ],
          SizedBox(height: media.width * 0.04),
          Text(
            "Extracted Information",
            style: TextStyle(
              color: TColor.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: media.width * 0.02),
          ...categorizedData.entries.map((category) {
            return Column(
              children: [
                _buildDataCard(category.key, category.value, media),
                SizedBox(height: media.width * 0.03),
              ],
            );
          }).toList(),
          SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() {
                  _isProcessed = false;
                  _extractedText = null;
                  _extractedData = {};
                  _injuryClassification = null;
                  _isInjuryClassificationFailed = false;
                });
                _pickImage();
              },
              icon: Icon(Icons.refresh, color: TColor.primaryColor1),
              label: Text(
                "Upload different report",
                style: TextStyle(color: TColor.primaryColor1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAnalysisContainerColor() {
    if (_isInjuryClassificationFailed || !_isApiKeyConfigured) {
      return Colors.amber.withOpacity(0.1);
    } else if (_injuryClassification != null) {
      return TColor.primaryColor1.withOpacity(0.1);
    }
    return Colors.grey.withOpacity(0.1);
  }

  Color _getAnalysisBorderColor() {
    if (_isInjuryClassificationFailed || !_isApiKeyConfigured) {
      return Colors.amber;
    } else if (_injuryClassification != null) {
      return TColor.primaryColor1;
    }
    return Colors.grey;
  }

  IconData _getAnalysisIconData() {
    if (_isInjuryClassificationFailed || !_isApiKeyConfigured) {
      return Icons.warning_amber_rounded;
    } else if (_injuryClassification != null) {
      return Icons.check_circle;
    }
    return Icons.info_outline;
  }

  Color _getAnalysisIconColor() {
    if (_isInjuryClassificationFailed || !_isApiKeyConfigured) {
      return Colors.amber;
    } else if (_injuryClassification != null) {
      return TColor.primaryColor1;
    }
    return Colors.grey;
  }

  String _getAnalysisStatusText() {
    if (!_isApiKeyConfigured) {
      return "Data extraction complete. AI analysis unavailable due to missing API key.";
    } else if (_isInjuryClassificationFailed) {
      return "Unable to determine diagnosis. Please provide a clearer image of the medical report.";
    } else if (_injuryClassification != null) {
      return "Report analysis completed successfully";
    }
    return "Report extracted. Analyzing with AI...";
  }

  Color _getAnalysisTextColor() {
    if (_isInjuryClassificationFailed || !_isApiKeyConfigured) {
      return Colors.amber.shade800;
    } else if (_injuryClassification != null) {
      return TColor.primaryColor1;
    }
    return Colors.grey.shade800;
  }

  Widget _buildDiagnosticLimitations(Size media) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Diagnostic Limitations",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "The analysis could not identify a conclusive diagnosis from the provided medical report due to one or more of the following factors:",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 12),
          _buildBulletPoint("Insufficient image clarity or resolution", media),
          _buildBulletPoint(
              "Critical diagnostic information may be missing or illegible",
              media),
          _buildBulletPoint(
              "The report format is not fully compatible with our analysis system",
              media),
          _buildBulletPoint(
              "Specialized or uncommon terminology that requires further clinical interpretation",
              media),
          SizedBox(height: 12),
          Text(
            "Please upload a clearer, more complete version of your medical report for accurate diagnosis and treatment recommendations.",
            style: TextStyle(
              color: TColor.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationResults(Size media) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TColor.primaryColor1.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TColor.primaryColor1.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "AI Classification Results",
            style: TextStyle(
              color: TColor.primaryColor1,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Injury: ${_injuryClassification!['injury_name']}",
            style: TextStyle(
              color: TColor.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          if (_injuryClassification!['symptoms'] != null &&
              (_injuryClassification!['symptoms'] as List).isNotEmpty)
            Text(
              "Common Symptoms: ${(_injuryClassification!['symptoms'] as List).length} symptoms identified",
              style: TextStyle(
                color: TColor.gray,
                fontSize: 14,
              ),
            ),
          if (_injuryClassification!['supporting_evidence'] != null &&
              (_injuryClassification!['supporting_evidence'] as List)
                  .isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "Supporting Evidence: ${(_injuryClassification!['supporting_evidence'] as List).length} findings from report",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 14,
                ),
              ),
            ),
          SizedBox(height: 8),
          Text(
            "Tap 'View Classification Results' for more details",
            style: TextStyle(
              color: TColor.primaryColor1,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, Size media) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "• ",
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: TColor.gray,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(String title, Map<String, dynamic> data, Size media) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: TColor.primaryColor1,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      entry.value.isEmpty
                          ? 'Not available'
                          : entry.value.toString(),
                      style: TextStyle(
                        color: TColor.black,
                        fontSize: 14,
                      ),
                    ),
                    if (entry.key != data.keys.last)
                      Divider(height: 16, color: TColor.gray.withOpacity(0.2)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('OpenRouter API Key Required'),
          content: Text(
            'To enable AI-powered injury classification, please add your '
            'OpenRouter API key to the .env file. This will allow the app to '
            'analyze your medical reports and provide detailed injury classifications.',
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text('OK'),
            )
          ],
        );
      },
    );
  }
}
