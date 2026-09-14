import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiotherapy/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:physiotherapy/view/rehabilitation/rehabilitation_workout_plan_generation.dart';
import 'dart:math' as math;

class ExerciseUtils {
  static List<Map<String, dynamic>> getExercisesForDay(
    Map<String, dynamic> plan,
    int selectedWeek,
    int selectedDay,
  ) {
    // Check if plan contains weeks
    if (plan == null || !plan.containsKey("weeks") || plan["weeks"] == null) {
      return []; // Return empty list if there are no weeks
    }

    var selectedWeekData = plan["weeks"].firstWhere(
      (week) => week["week"] == selectedWeek,
      orElse: () => <String, Object>{}, // Fixed: Using Map<String, Object>
    );

    if (selectedWeekData.isNotEmpty) {
      // Check if the map is not empty and contains days
      if (selectedWeekData.containsKey("days") &&
          selectedWeekData["days"] != null) {
        var selectedDayData = selectedWeekData["days"].firstWhere(
          (day) => day["day"] == selectedDay,
          orElse: () => <String, Object>{}, // Fixed: Using Map<String, Object>
        );

        if (selectedDayData.isNotEmpty &&
            selectedDayData.containsKey("exercises") &&
            selectedDayData["exercises"] != null) {
          return List<Map<String, dynamic>>.from(selectedDayData["exercises"]);
        }
      }
    }

    return []; // Return an empty list if no exercises are found
  }
}

class RehabilitationWorkoutAI extends StatefulWidget {
  final Map<String, dynamic> plan;

  const RehabilitationWorkoutAI({
    Key? key,
    required this.plan,
  }) : super(key: key);

  @override
  State<RehabilitationWorkoutAI> createState() =>
      _RehabilitationWorkoutAIState();
}

class _RehabilitationWorkoutAIState extends State<RehabilitationWorkoutAI>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _dobController;
  String _selectedGender = '';
  UserModel? _userModel;
  bool _isLoading = true;
  bool _hasGeneratedPlan = false;
  bool _isGeneratingPlan = false;
  int _selectedWeek = 1;
  int _selectedDay = 1;
  int _planType = 4; // Will be set by model prediction

  // Sample workout plan structure - replace with your AI-generated plan
  Map<String, dynamic> _workoutPlan = {};

  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _buttonAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    _dobController = TextEditingController();
    _initializeAnimations();
    _loadUserData();
    _checkForExistingPlan();
    _startAnimations();
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
    _weightController.dispose();
    _heightController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _checkForExistingPlan() {
    // Check if plan already has workout data
    if (widget.plan.containsKey("weeks") && widget.plan["weeks"] != null) {
      setState(() {
        _workoutPlan = widget.plan;
        _hasGeneratedPlan = true;
        // Extract plan type from existing plan if available
        if (widget.plan.containsKey("planType")) {
          _planType = widget.plan["planType"];
        }
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      // Get current user ID from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userModel = UserModel.fromFirestore(userDoc);
          _weightController.text = _userModel!.weight.toString();
          _heightController.text = _userModel!.height.toString();
          _dobController.text =
              DateFormat('yyyy-MM-dd').format(_userModel!.dob);
          _selectedGender = _userModel!.gender;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
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

  Color _getPlanTypeColor(int planType) {
    switch (planType) {
      case 1:
        return Colors.green.shade300;
      case 2:
        return Colors.blue.shade300;
      case 3:
        return Colors.orange.shade600;
      case 4:
        return Colors.purple.shade400;
      case 5:
        return Colors.amber.shade600;
      case 6:
        return Colors.red.shade400;
      case 7:
        return Colors.teal.shade300;
      default:
        return Colors.grey.shade400;
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      // Optional: Show loading indicator while updating and predicting
      // _isLoading = true; // Or a separate loading state for the update button
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          _buildCustomSnackBar('User not logged in', false),
        );
        // setState(() { _isLoading = false; }); // Hide loading
        return;
      }

      final updatedUser = _userModel!.copyWith(
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        dob: DateFormat('yyyy-MM-dd').parse(_dobController.text),
        gender: _selectedGender,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updatedUser.toFirestore());

      // --- Call the prediction model API after successful profile update ---

      // Calculate age from DOB
      final dob = DateFormat('yyyy-MM-dd').parse(_dobController.text);
      final age = DateTime.now().difference(dob).inDays ~/ 365;

      // Convert height from cm to meters
      final heightMeters = double.parse(_heightController.text) / 100;

      // Make API call to prediction endpoint
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'weight': double.parse(_weightController.text),
          'height_meters': heightMeters,
          'gender': _selectedGender,
          'age': age,
        }),
      );

      if (response.statusCode == 200) {
        final prediction = jsonDecode(response.body);
        setState(() {
          _userModel = updatedUser; // Update local user model
          _planType =
              prediction['plan_number']; // Update plan type from prediction
          _hasGeneratedPlan =
              false; // Disable current plan, require regeneration
          // _isLoading = false; // Hide loading
        });

        ScaffoldMessenger.of(context).showSnackBar(
          _buildCustomSnackBar(
              'Profile updated and plan type re-calculated!', true),
        );
      } else {
        // If prediction fails, still show profile update success but log prediction error
        ScaffoldMessenger.of(context).showSnackBar(
          _buildCustomSnackBar(
              'Profile updated, but failed to re-calculate plan type: ${response.body}',
              false),
        );
        // setState(() { _isLoading = false; }); // Hide loading
      }
    } catch (e) {
      // Handle errors during Firestore update or API call
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar(
            'Error updating profile or re-calculating plan type: $e', false),
      );
      setState(() {
        _isLoading = false;
      }); // Hide loading
    }
  }

  SnackBar _buildCustomSnackBar(String message, bool isSuccess) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _generateWorkoutPlan() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        _buildCustomSnackBar('Please complete your profile first', false),
      );
      return;
    }

    // Navigate to the plan generation page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RehabilitationWorkoutPlanGeneration(
          plan: widget.plan,
          userModel: _userModel!,
          selectedGender: _selectedGender,
          weight: double.parse(_weightController.text),
          height: double.parse(_heightController.text),
          dob: DateFormat('yyyy-MM-dd').parse(_dobController.text),
          planType: _planType,
        ),
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onTap: onTap,
        readOnly: readOnly,
        style: TextStyle(
          color: TColor.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: TColor.gray.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
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
              icon,
              color: TColor.primaryColor1,
              size: 15,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedGenderSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.person_outline,
              color: TColor.primaryColor1,
              size: 15,
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedGender.isEmpty ? null : _selectedGender,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Select Gender",
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 18,
                ),
              ),
              style: TextStyle(
                color: TColor.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              items: ['Male', 'Female', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue ?? '';
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select your gender';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildEnhancedButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    bool isLoading = false,
    Color? backgroundColor,
  }) {
    return AnimatedBuilder(
      animation: _buttonScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 51,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgroundColor != null
                    ? [backgroundColor, backgroundColor.withOpacity(0.8)]
                    : [
                        const Color(0xffA882DD),
                        const Color(0xff6d6492),
                      ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: (backgroundColor ?? const Color(0xffA882DD))
                      .withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Text(
                          "Processing...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: Colors.white,
                          size: 19,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
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

  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    if (_isLoading) {
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
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xffA882DD),
                          const Color(0xff6d6492),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(34),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xffA882DD),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Loading your AI personalized plan...",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

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
          ...List.generate(4, (index) {
            return AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: 100 +
                      (index * 150) +
                      (20 *
                          math.sin(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  left: (index.isEven ? -30 : media.width - 70) +
                      (15 *
                          math.cos(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  child: Container(
                    width: 58 + (index * 8),
                    height: 58 + (index * 8),
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
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(21.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Header
                          SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
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
                                      color: const Color(0xffA882DD)
                                          .withOpacity(0.3),
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
                                        // Back button
                                        InkWell(
                                          onTap: () => Navigator.pop(context),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_back_ios,
                                              color: Colors.white,
                                              size: 15,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "AI Personalized Plan",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                "Personalized plan journey",
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.psychology,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _getPlanTypeName(_planType),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Profile Information Form
                          SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              margin:
                                  const EdgeInsets.only(top: 30, bottom: 25),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Personal Information",
                                    style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Complete your profile for AI-powered recommendations",
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Enhanced Form
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  _buildEnhancedTextField(
                                    controller: _weightController,
                                    hintText: "Weight (kg)",
                                    icon: Icons.monitor_weight_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your weight';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      double weight = double.parse(value);
                                      if (weight < 30 || weight > 300) {
                                        return 'Please enter a realistic weight (30-300 kg)';
                                      }
                                      return null;
                                    },
                                  ),
                                  _buildEnhancedTextField(
                                    controller: _heightController,
                                    hintText: "Height (cm)",
                                    icon: Icons.height,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your height';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      double height = double.parse(value);
                                      if (height < 100 || height > 250) {
                                        return 'Please enter a realistic height (100-250 cm)';
                                      }
                                      return null;
                                    },
                                  ),
                                  _buildEnhancedTextField(
                                    controller: _dobController,
                                    hintText: "Date of Birth (YYYY-MM-DD)",
                                    icon: Icons.calendar_today_outlined,
                                    readOnly: true,
                                    onTap: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().subtract(
                                            const Duration(days: 365 * 25)),
                                        firstDate: DateTime(1950),
                                        lastDate: DateTime.now(),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary:
                                                    const Color(0xffA882DD),
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: TColor.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (pickedDate != null) {
                                        _dobController.text =
                                            DateFormat('yyyy-MM-dd')
                                                .format(pickedDate);
                                      }
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please select your date of birth';
                                      }
                                      try {
                                        DateTime dob = DateFormat('yyyy-MM-dd')
                                            .parse(value);
                                        int age = DateTime.now()
                                                .difference(dob)
                                                .inDays ~/
                                            365;
                                        if (age < 16 || age > 100) {
                                          return 'Age must be between 16 and 100 years';
                                        }
                                      } catch (e) {
                                        return 'Please enter a valid date';
                                      }
                                      return null;
                                    },
                                  ),
                                  _buildEnhancedGenderSelector(),
                                ],
                              ),
                            ),
                          ),

                          // Action Buttons
                          SlideTransition(
                            position: _slideAnimation,
                            child: Column(
                              children: [
                                _buildEnhancedButton(
                                  text: "Update & Recommend Plan",
                                  onPressed: _updateUserData,
                                  icon: Icons.person_outline,
                                  backgroundColor: const Color(0xff4CAF50),
                                ),

                                // Plan Generation Section
                                Container(
                                  width: double.maxFinite,
                                  padding: const EdgeInsets.all(25),
                                  margin: const EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        const Color(0xffA882DD)
                                            .withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xffA882DD)
                                          .withOpacity(0.2),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xffA882DD)
                                            .withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      // AI Icon with animated glow
                                      AnimatedBuilder(
                                        animation: _backgroundAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            width: 58,
                                            height: 58,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  const Color(0xffA882DD),
                                                  const Color(0xff6d6492),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xffA882DD)
                                                      .withOpacity(
                                                    0.3 +
                                                        (0.2 *
                                                            _backgroundAnimation
                                                                .value),
                                                  ),
                                                  blurRadius: 15 +
                                                      (10 *
                                                          _backgroundAnimation
                                                              .value),
                                                  spreadRadius: 2 +
                                                      (3 *
                                                          _backgroundAnimation
                                                              .value),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.auto_awesome,
                                              color: Colors.white,
                                              size: 29,
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 20),

                                      Text(
                                        "AI-Powered Workout Plan",
                                        style: TextStyle(
                                          color: TColor.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _getPlanTypeColor(_planType)
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getPlanTypeColor(_planType),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _getPlanDescription(_planType),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _getPlanTypeColor(_planType)
                                                .withOpacity(0.8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      Text(
                                        "Get a personalized strengthening plan based on your BMI",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: TColor.gray,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                _buildEnhancedButton(
                                  text: _hasGeneratedPlan
                                      ? "View Current Plan"
                                      : "Generate AI Plan",
                                  onPressed: _generateWorkoutPlan,
                                  icon: _hasGeneratedPlan
                                      ? Icons.visibility_outlined
                                      : Icons.auto_awesome,
                                  isLoading: _isGeneratingPlan,
                                ),

                                // Plan Status Indicator
                                if (_hasGeneratedPlan)
                                  Container(
                                    width: double.maxFinite,
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green.withOpacity(0.1),
                                          Colors.green.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                            size: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Plan Generated Successfully",
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                "Your personalized workout plan is ready",
                                                style: TextStyle(
                                                  color: Colors.green.shade600,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                const SizedBox(height: 30),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
