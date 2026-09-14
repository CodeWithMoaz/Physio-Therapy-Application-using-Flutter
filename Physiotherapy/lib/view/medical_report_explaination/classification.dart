import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physiotherapy/view/rehabilitation/way_of_rehab.dart';
import '../../common/color_extension.dart';
import '../../common_widget/round_button.dart';
import 'dart:math' as math;

class ClassificationView extends StatefulWidget {
  final Map<String, dynamic>? injuryData;
  final Map<String, dynamic>? extractedData;

  const ClassificationView({
    Key? key,
    this.injuryData,
    this.extractedData,
  }) : super(key: key);

  @override
  State<ClassificationView> createState() => _ClassificationViewState();
}

class _ClassificationViewState extends State<ClassificationView>
    with TickerProviderStateMixin {
  late String injuryName;
  late String description;
  late List<String> symptoms;
  late List<String> supportingEvidence;
  late List<String> recommendations;
  bool isLoading = false;

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
    _initializeData();
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

  void _initializeData() {
    if (widget.injuryData != null) {
      injuryName = widget.injuryData!['injury_name'] ?? 'Unknown Injury';
      description =
          widget.injuryData!['description'] ?? 'No description available.';

      if (widget.injuryData!['symptoms'] is List) {
        symptoms = List<String>.from(widget.injuryData!['symptoms'] ?? []);
      } else {
        symptoms = [];
      }

      if (widget.injuryData!['supporting_evidence'] is List) {
        supportingEvidence =
            List<String>.from(widget.injuryData!['supporting_evidence'] ?? []);
      } else {
        supportingEvidence = [];
      }

      if (widget.injuryData!['recommendations'] is List) {
        recommendations =
            List<String>.from(widget.injuryData!['recommendations'] ?? []);
      } else {
        recommendations = [];
      }

      print(
          "Initialized data: $injuryName, symptoms: ${symptoms.length}, evidence: ${supportingEvidence.length}, recommendations: ${recommendations.length}");
    } else {
      injuryName = 'Unknown Injury';
      description = 'No description available.';
      symptoms = [];
      supportingEvidence = [];
      recommendations = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  TColor.primaryColor1.withOpacity(0.1),
                                  TColor.primaryColor2.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: TColor.primaryColor1.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              "Diagnosis Result",
                              style: TextStyle(
                                color: TColor.primaryColor1,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: media.width * 0.02),
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: _gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: Text(
                              injuryName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(height: media.width * 0.02),
                          Text(
                            "Based on your medical report analysis, here's what we found about your condition",
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
                      child: isLoading
                          ? _buildLoadingView()
                          : _buildContentView(media),
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
                        title: "View Rehabilitation Plans",
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RehabilitationWayView(),
                            ),
                          );
                        },
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
              "Loading diagnosis details...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(Size media) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedCard(
            title: "Common Symptoms",
            icon: Icons.health_and_safety_outlined,
            items: symptoms,
            color: TColor.primaryColor1,
            delay: 0,
          ),
          SizedBox(height: media.width * 0.04),
          if (supportingEvidence.isNotEmpty) ...[
            _buildAnimatedCard(
              title: "Evidence From Report",
              icon: Icons.fact_check_outlined,
              items: supportingEvidence,
              color: const Color(0xFF28A745),
              delay: 200,
            ),
            SizedBox(height: media.width * 0.04),
          ],
          _buildDescriptionCard(delay: 400),
          SizedBox(height: media.width * 0.04),
          if (recommendations.isNotEmpty) ...[
            _buildAnimatedCard(
              title: "Treatment Recommendations",
              icon: Icons.medical_services_outlined,
              items: recommendations,
              color: TColor.secondaryColor1,
              delay: 600,
            ),
          ],
          SizedBox(height: media.width * 0.05),
        ],
      ),
    );
  }

  Widget _buildAnimatedCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              color.withOpacity(0.1),
                              color.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ...items.asMap().entries.map((entry) {
                    int index = entry.key;
                    String item = entry.value;
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      tween: Tween(begin: 0.0, end: 1.0),
                      curve: Curves.easeOut,
                      builder: (context, itemValue, child) {
                        return Transform.translate(
                          offset: Offset(20 * (1 - itemValue), 0),
                          child: Opacity(
                            opacity: itemValue,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.only(
                                        top: 8, right: 12),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionCard({required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xffA882DD).withOpacity(0.05),
                    const Color(0xff6d6492).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xffA882DD).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 8),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffA882DD).withOpacity(0.2),
                              const Color(0xff6d6492).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: const Color(0xff6d6492),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "About This Injury",
                          style: TextStyle(
                            color: const Color(0xff6d6492),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
