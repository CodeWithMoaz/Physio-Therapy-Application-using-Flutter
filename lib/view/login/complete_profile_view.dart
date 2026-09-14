import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/view/login/what_goal_view.dart';
import 'package:physiotherapy/common_widget/round_button.dart';
import 'package:physiotherapy/common_widget/round_textfield.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView>
    with TickerProviderStateMixin {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedGender;
  bool _isLoading = false;
  String _profileImage = 'assets/img/male_profile_pic.png';

  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _buttonAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

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
    _dateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xffA882DD),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('MMM dd, yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedGender == null ||
        _dateController.text.isEmpty ||
        _weightController.text.isEmpty ||
        _heightController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = {
        'gender': _selectedGender,
        'profileImage': _profileImage,
        'dob': Timestamp.fromDate(
            DateFormat('MMM dd, yyyy').parse(_dateController.text)),
        'weight': double.parse(_weightController.text),
        'height': double.parse(_heightController.text),
        'updated_at': Timestamp.now(),
      };

      await _firestore.collection('users').doc(user.uid).update(userData);

      if (!mounted) return;

      _navigateWithTransition(const WhatYourGoalView());
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateWithTransition(Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.5)),
        margin: const EdgeInsets.all(8.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
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
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: 85 +
                      (index * 102) +
                      (25.5 *
                          math.sin(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  left: (index.isEven ? -42.5 : media.width - 42.5) +
                      (17 *
                          math.cos(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  child: Container(
                    width: 68 + (index * 8.5),
                    height: 68 + (index * 8.5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xffA882DD).withOpacity(0.1),
                          const Color(0xff6d6492).withOpacity(0.05),
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
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    children: [
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 17, vertical: 12.75),
                          child: Row(
                            children: [
                              Container(
                                height: 38.25,
                                width: 38.25,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white,
                                      const Color(0xffA882DD).withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12.75),
                                  border: Border.all(
                                    color: const Color(0xffA882DD)
                                        .withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffA882DD)
                                          .withOpacity(0.1),
                                      blurRadius: 8.5,
                                      offset: const Offset(0, 4.25),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.arrow_back_ios_rounded,
                                    color: const Color(0xffA882DD),
                                    size: 17,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Complete Profile",
                                style: TextStyle(
                                  color: const Color(0xffA882DD),
                                  fontSize: 15.3,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 38.25),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.only(
                                top: 8.5, bottom: 8.5, left: 17, right: 17),
                            child: Column(
                              children: [
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 85,
                                          height: 85,
                                          margin: const EdgeInsets.only(
                                              bottom: 12.75),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xffA882DD),
                                                const Color(0xff6d6492),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(42.5),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xffA882DD)
                                                    .withOpacity(0.3),
                                                blurRadius: 17,
                                                offset: const Offset(0, 8.5),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(42.5),
                                            child: Image.asset(
                                              _profileImage,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        ShaderMask(
                                          shaderCallback: (bounds) {
                                            return LinearGradient(
                                              colors: [
                                                const Color(0xffA882DD),
                                                const Color(0xff6d6492),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ).createShader(bounds);
                                          },
                                          child: Text(
                                            "Complete your profile",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 23.8,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.425,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8.5),
                                        Text(
                                          "It will help us to know more about you!",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: TColor.gray,
                                            fontSize: 13.6,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 17),
                                SlideTransition(
                                  position: _slideAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.all(21.25),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(21.25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xffA882DD)
                                              .withOpacity(0.1),
                                          blurRadius: 17,
                                          offset: const Offset(0, 8.5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        _buildEnhancedGenderSelector(),
                                        const SizedBox(height: 17),
                                        _buildEnhancedDateSelector(),
                                        const SizedBox(height: 17),
                                        _buildEnhancedTextField(
                                          controller: _weightController,
                                          hintText: "Weight",
                                          icon: Icons.monitor_weight_outlined,
                                          keyboardType: TextInputType.number,
                                          suffix: "KG",
                                          inputFormatter: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                        const SizedBox(height: 17),
                                        _buildEnhancedTextField(
                                          controller: _heightController,
                                          hintText: "Height",
                                          icon: Icons.height_outlined,
                                          keyboardType: TextInputType.number,
                                          suffix: "CM",
                                          inputFormatter: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 25.5),
                                AnimatedBuilder(
                                  animation: _buttonScaleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _buttonScaleAnimation.value,
                                      child: _buildEnhancedNextButton(),
                                    );
                                  },
                                ),
                                const SizedBox(height: 17),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    String? suffix,
    List<TextInputFormatter>? inputFormatter,
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
        borderRadius: BorderRadius.circular(12.75),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.3),
          width: 1.275,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 8.5,
            offset: const Offset(0, 4.25),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(10.2),
            padding: const EdgeInsets.all(6.8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD).withOpacity(0.2),
                  const Color(0xff6d6492).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8.5),
            ),
            child: Icon(
              icon,
              color: const Color(0xffA882DD),
              size: 17,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatter,
              style: TextStyle(
                color: TColor.black,
                fontSize: 13.6,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: TColor.gray.withOpacity(0.7),
                  fontSize: 13.6,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8.5,
                  vertical: 15.3,
                ),
              ),
            ),
          ),
          if (suffix != null)
            Container(
              margin: const EdgeInsets.only(right: 10.2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10.2, vertical: 6.8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xffA882DD),
                    const Color(0xff6d6492),
                  ],
                ),
                borderRadius: BorderRadius.circular(6.8),
              ),
              child: Text(
                suffix,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGenderSelector() {
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
        borderRadius: BorderRadius.circular(12.75),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.3),
          width: 1.275,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 8.5,
            offset: const Offset(0, 4.25),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.all(10.2),
            padding: const EdgeInsets.all(6.8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD).withOpacity(0.2),
                  const Color(0xff6d6492).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8.5),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: const Color(0xffA882DD),
              size: 18.7,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender,
                isExpanded: true,
                hint: Text(
                  "Choose Gender",
                  style: TextStyle(
                    color: TColor.gray.withOpacity(0.7),
                    fontSize: 13.6,
                  ),
                ),
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 13.6,
                  fontWeight: FontWeight.w500,
                ),
                items: ["Male", "Female"]
                    .map(
                      (name) => DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                    _profileImage = value == "Male"
                        ? 'assets/img/male_profile_pic.png'
                        : 'assets/img/female_profile_pic.png';
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12.75),
        ],
      ),
    );
  }

  Widget _buildEnhancedDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xffA882DD).withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.75),
          border: Border.all(
            color: const Color(0xffA882DD).withOpacity(0.3),
            width: 1.275,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffA882DD).withOpacity(0.1),
              blurRadius: 8.5,
              offset: const Offset(0, 4.25),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.all(10.2),
              padding: const EdgeInsets.all(6.8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xffA882DD).withOpacity(0.2),
                    const Color(0xff6d6492).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.5),
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                color: const Color(0xffA882DD),
                size: 18.7,
              ),
            ),
            Expanded(
              child: AbsorbPointer(
                child: TextField(
                  controller: _dateController,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 13.6,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Date of Birth",
                    hintStyle: TextStyle(
                      color: TColor.gray.withOpacity(0.7),
                      fontSize: 13.6,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.5,
                      vertical: 15.3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12.75),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedNextButton() {
    return Container(
      width: double.infinity,
      height: 51,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffA882DD),
            const Color(0xff6d6492),
          ],
        ),
        borderRadius: BorderRadius.circular(25.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.4),
            blurRadius: 12.75,
            offset: const Offset(0, 6.8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.5),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.7,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12.75),
                  Text(
                    "Saving Profile...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.3,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.425,
                    ),
                  ),
                  const SizedBox(width: 6.8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
      ),
    );
  }
}
