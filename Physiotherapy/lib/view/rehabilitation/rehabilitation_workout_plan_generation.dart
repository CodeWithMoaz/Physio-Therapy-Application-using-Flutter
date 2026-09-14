import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/models/user_model.dart';
import 'package:physiotherapy/view/rehabilitation/rehabilitation_workout_AI_screen.dart';
import 'package:physiotherapy/api_service/workout_plan_service.dart';
import 'package:physiotherapy/models/workout_plan_model.dart';
import 'dart:math' as math;

class RehabilitationWorkoutPlanGeneration extends StatefulWidget {
  final Map<String, dynamic> plan;
  final UserModel userModel;
  final String selectedGender;
  final double weight;
  final double height;
  final DateTime dob;
  final int planType;

  const RehabilitationWorkoutPlanGeneration({
    Key? key,
    required this.plan,
    required this.userModel,
    required this.selectedGender,
    required this.weight,
    required this.height,
    required this.dob,
    required this.planType,
  }) : super(key: key);

  @override
  State<RehabilitationWorkoutPlanGeneration> createState() =>
      _RehabilitationWorkoutPlanGenerationState();
}

class _RehabilitationWorkoutPlanGenerationState
    extends State<RehabilitationWorkoutPlanGeneration>
    with TickerProviderStateMixin {
  bool _isGeneratingPlan = false;
  bool _hasGeneratedPlan = false;
  int _selectedWeek = 1;
  int _selectedDay = 1;
  WorkoutPlan? _workoutPlan;
  final WorkoutPlanService _workoutPlanService = WorkoutPlanService();

  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _buttonAnimationController;
  late AnimationController _loadingAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _loadingRotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _generateWorkoutPlan();
  }

  void _initializeAnimations() {
    // Main animation controller for page entrance
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Button animation controller
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Loading animation controller
    _loadingAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Fade animation for overall opacity
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Slide animation for form elements
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    // Scale animation for interactive elements
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    // Background gradient animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    // Button scale animation
    _buttonScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    // Loading rotation animation
    _loadingRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_loadingAnimationController);
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    _backgroundAnimationController.repeat(reverse: true);
    _buttonAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _buttonAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  String _getPlanTypeName(int planType) {
    switch (planType) {
      case 1:
        return "Severe Thinness Plan";
      case 2:
        return "Moderate Thinness Plan";
      case 3:
        return "Standard Intensive Plan";
      case 4:
        return "Normal Weight Plan";
      case 5:
        return "Overweight Management Plan";
      case 6:
        return "Obesity Care Plan";
      case 7:
        return "Severe Obesity Gentle Plan";
      default:
        return "Custom Plan";
    }
  }

  String _getPlanDescription(int planType) {
    switch (planType) {
      case 1:
        return "Gentle strengthening-focused exercises with minimal intensity";
      case 2:
        return "Progressive strengthening with moderate intensity";
      case 3:
        return "Intensive strengthening with challenging exercises";
      case 4:
        return "Balanced approach for optimal strengthening";
      case 5:
        return "Weight management integrated with strengthening exercises";
      case 6:
        return "Structured plan for obesity considerations";
      case 7:
        return "Gentle, strengthening-focused safe exercises for severe obesity cases";
      default:
        return "Personalized strengthening plan";
    }
  }

  Future<void> _generateWorkoutPlan() async {
    setState(() {
      _isGeneratingPlan = true;
    });

    _loadingAnimationController.repeat();

    try {
      final age = DateTime.now().difference(widget.dob).inDays ~/ 365;

      final workoutPlan = await _workoutPlanService.generateWorkoutPlan(
        targetArea: widget.plan["injury"] ?? "knee",
        bodyType: _getBodyTypeFromPlanType(widget.planType),
        gender: widget.selectedGender,
        weight: widget.weight,
        height: widget.height,
        age: age,
      );

      setState(() {
        _workoutPlan = workoutPlan;
        _hasGeneratedPlan = true;
        _isGeneratingPlan = false;
      });

      _loadingAnimationController.stop();

      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('AI Workout plan generated successfully!', true),
      );
    } catch (e) {
      setState(() {
        _isGeneratingPlan = false;
      });
      _loadingAnimationController.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Error generating plan: $e', false),
      );
    }
  }

  String _getBodyTypeFromPlanType(int planType) {
    switch (planType) {
      case 1:
        return "Severe Thinness";
      case 2:
        return "Moderate Thinness";
      case 3:
        return "Mild Thinness";
      case 4:
        return "Normal";
      case 5:
        return "Overweight";
      case 6:
        return "Obese";
      case 7:
        return "Severe Obese";
      default:
        return "Normal";
    }
  }

  void _navigateToWorkout() {
    if (!_hasGeneratedPlan || _workoutPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Please wait for the plan to generate', false),
      );
      return;
    }

    final selectedWeek = _workoutPlan!.weeks.firstWhere(
      (week) => week.weekNumber == _selectedWeek,
      orElse: () => Week(weekNumber: 1, days: []),
    );

    final selectedDay = selectedWeek.days.firstWhere(
      (day) => day.dayNumber == _selectedDay,
      orElse: () => Day(dayNumber: 1, exercises: []),
    );

    if (selectedDay.exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('No exercises found for selected day', false),
      );
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            RehabilitationWorkoutAIScreen(
          exercises: selectedDay.exercises.map((e) => e.toMap()).toList(),
          injuryType: widget.plan["injury"],
          planType: _getPlanTypeName(widget.planType),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(1.0, 0.0);
          var end = Offset.zero;
          var curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  SnackBar _buildCustomSnackBar(String message, bool isSuccess) {
    return SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor:
          isSuccess ? const Color(0xff4CAF50) : const Color(0xffF44336),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      margin: const EdgeInsets.all(16),
      elevation: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _backgroundAnimation,
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
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.05),
                        const Color(0xffA882DD).withOpacity(0.15),
                        _backgroundAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating decorative elements
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: 100 +
                      (index * 120) +
                      (30 *
                          math.sin(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  left: (index.isEven ? -50 : media.width - 50) +
                      (20 *
                          math.cos(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  child: Container(
                    width: 80 + (index * 10),
                    height: 80 + (index * 10),
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

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Enhanced App Bar
                _buildEnhancedAppBar(),

                // Main content
                Expanded(
                  child: AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: _isGeneratingPlan
                            ? _buildLoadingView()
                            : _buildMainContent(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Enhanced back button
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xffA882DD).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: TColor.primaryColor1,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 15),

          // Enhanced title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Workout Plan",
                  style: TextStyle(
                    color: TColor.primaryColor1,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  "Personalized for you",
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated loading icon
                AnimatedBuilder(
                  animation: _loadingRotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loadingRotationAnimation.value * 2 * math.pi,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xffA882DD),
                              const Color(0xff6d6492),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                Text(
                  "Generating Your Plan",
                  style: TextStyle(
                    color: TColor.primaryColor1,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "AI is analyzing your profile and creating\na personalized workout plan...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 20),

                // Animated progress bar
                Container(
                  width: 200,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xffA882DD).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: AnimatedBuilder(
                    animation: _loadingAnimationController,
                    builder: (context, child) {
                      return Container(
                        width: 200 * _loadingRotationAnimation.value,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffA882DD),
                              const Color(0xff6d6492),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Plan Type Display
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xffA882DD),
                      const Color(0xff6d6492),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffA882DD).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            "Injury: ${widget.plan["injury"] ?? "General"}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Plan Type",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getPlanTypeName(widget.planType),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getPlanDescription(widget.planType),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Enhanced Week and Day Selection
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffA882DD).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Select Schedule",
                      style: TextStyle(
                        color: TColor.primaryColor1,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEnhancedDropdown(
                            value: _selectedWeek,
                            items: [1, 2],
                            hint: "Week",
                            icon: Icons.calendar_view_week,
                            onChanged: (value) {
                              setState(() {
                                _selectedWeek = value ?? 1;
                              });
                            },
                            itemBuilder: (value) => "Week $value",
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildEnhancedDropdown(
                            value: _selectedDay,
                            items: List.generate(7, (index) => index + 1),
                            hint: "Day",
                            icon: Icons.today,
                            onChanged: (value) {
                              setState(() {
                                _selectedDay = value ?? 1;
                              });
                            },
                            itemBuilder: (value) {
                              List<String> days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun'
                              ];
                              return "${days[value - 1]} $value";
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Enhanced Exercise Preview
            SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffA882DD).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xffA882DD).withOpacity(0.2),
                                const Color(0xff6d6492).withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: TColor.primaryColor1,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Today's Exercises",
                          style: TextStyle(
                            color: TColor.primaryColor1,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildExerciseList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Enhanced Start Workout Button
            AnimatedBuilder(
              animation: _buttonScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScaleAnimation.value,
                  child: _buildEnhancedStartButton(),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedDropdown<T>({
    required T value,
    required List<T> items,
    required String hint,
    required IconData icon,
    required Function(T?) onChanged,
    required String Function(T) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD).withOpacity(0.2),
                  const Color(0xff6d6492).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: TColor.primaryColor1,
              size: 18,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                items: items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemBuilder(item)),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    print('--- _buildExerciseList called ---');
    print('Workout Plan is null: ${_workoutPlan == null}');

    if (_workoutPlan == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xffA882DD).withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xffA882DD).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: TColor.gray,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "No exercises scheduled for this day",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedWeek = _workoutPlan!.weeks.firstWhere(
      (week) => week.weekNumber == _selectedWeek,
      orElse: () => Week(weekNumber: 1, days: []),
    );

    final selectedDay = selectedWeek.days.firstWhere(
      (day) => day.dayNumber == _selectedDay,
      orElse: () => Day(dayNumber: 1, exercises: []),
    );

    if (selectedDay.exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xffA882DD).withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xffA882DD).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: TColor.gray,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "No exercises scheduled for this day",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Week and Day Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xffA882DD).withOpacity(0.1),
                const Color(0xff6d6492).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: TColor.primaryColor1,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Week $_selectedWeek - Day $_selectedDay",
                style: TextStyle(
                  color: TColor.primaryColor1,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        // Exercises List
        ...selectedDay.exercises.map((exercise) {
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Exercise Header
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xffA882DD).withOpacity(0.1),
                        const Color(0xff6d6492).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: TColor.primaryColor1,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(exercise.difficulty),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          exercise.difficulty,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Exercise Details
                Container(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildExerciseDetail(
                        icon: Icons.repeat,
                        label: "Sets",
                        value: exercise.sets.toString(),
                      ),
                      _buildExerciseDetail(
                        icon: Icons.fitness_center,
                        label: "Reps",
                        value: exercise.reps.toString(),
                      ),
                      _buildExerciseDetail(
                        icon: Icons.timer,
                        label: "Duration",
                        value: exercise.duration,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildExerciseDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xffA882DD).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: TColor.primaryColor1,
            size: 18,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStartButton() {
    return Container(
      width: double.maxFinite,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffA882DD),
            const Color(0xff6d6492),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _navigateToWorkout,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "Start Workout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case "very easy":
        return Colors.green.shade400;
      case "easy":
        return Colors.blue.shade400;
      case "medium":
        return Colors.orange.shade400;
      case "hard":
        return Colors.red.shade400;
      case "very hard":
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }
}

class ExerciseUtils {
  static List<Map<String, dynamic>> getExercisesForDay(
    Map<String, dynamic> plan,
    int selectedWeek,
    int selectedDay,
  ) {
    if (plan == null || !plan.containsKey("weeks") || plan["weeks"] == null) {
      return [];
    }

    var selectedWeekData = plan["weeks"].firstWhere(
      (week) => week["week"] == selectedWeek,
      orElse: () => <String, Object>{},
    );

    if (selectedWeekData.isNotEmpty) {
      if (selectedWeekData.containsKey("days") &&
          selectedWeekData["days"] != null) {
        var selectedDayData = selectedWeekData["days"].firstWhere(
          (day) => day["day"] == selectedDay,
          orElse: () => <String, Object>{},
        );

        if (selectedDayData.isNotEmpty &&
            selectedDayData.containsKey("exercises") &&
            selectedDayData["exercises"] != null) {
          return List<Map<String, dynamic>>.from(selectedDayData["exercises"]);
        }
      }
    }

    return [];
  }
}
