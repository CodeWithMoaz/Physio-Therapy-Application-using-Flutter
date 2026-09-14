import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/services/auth_service.dart';
import 'package:physiotherapy/view/login/complete_profile_view.dart';
import 'package:physiotherapy/view/login/complete_profile_doctor.dart';
import 'package:physiotherapy/view/login/login_view.dart';
import 'package:physiotherapy/models/doctor_model.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;

  final AuthService _authService = AuthService();

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.createUserWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );

      if (!mounted) return;

      if (userCredential == null || userCredential.user == null) {
        throw Exception('User creation failed');
      }

      final user = userCredential.user!;
      final timestamp = Timestamp.now();

      if (_selectedRole == 'user') {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'id': user.uid,
          'fullName': _nameController.text,
          'email': _emailController.text,
          'gender': '',
          'dob': timestamp,
          'weight': 0.0,
          'height': 0.0,
          'profileImage': null,
          'enrolledPrograms': {},
          'created_at': timestamp,
        });
        _navigateWithTransition(const CompleteProfileView());
      } else if (_selectedRole == 'doctor') {
        final doctor = DoctorModel(
          id: user.uid,
          fullName: _nameController.text,
          email: _emailController.text,
          specialization: '',
          yearsOfExperience: 0,
          certificate: null,
          additionalInformation: null,
          isVerified: false,
          createdAt: DateTime.now(),
          status: 'pending',
          programsManaged: [],
        );

        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .set(doctor.toFirestore());

        _navigateWithTransition(const DoctorCompleteProfileView());
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Sign up failed: ${e.toString()}');
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
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(17.0),
                      child: Column(
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: Column(
                                children: [
                                  Container(
                                    width: 102,
                                    height: 102,
                                    margin: const EdgeInsets.only(bottom: 17),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xffA882DD),
                                          const Color(0xff6d6492),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(51),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xffA882DD)
                                              .withOpacity(0.3),
                                          blurRadius: 17,
                                          offset: const Offset(0, 8.5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.person_add_outlined,
                                      size: 51,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: TColor.primaryColor1,
                                      fontSize: 27.2,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.425,
                                      shadows: [
                                        Shadow(
                                          color: TColor.primaryColor1
                                              .withOpacity(0.2),
                                          offset: const Offset(0.85, 0.85),
                                          blurRadius: 1.7,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6.8),
                                  Text(
                                    "Sign up to get started with your health journey",
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
                          const SizedBox(height: 34),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Container(
                              padding: const EdgeInsets.all(21.25),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(21.25),
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
                                  _buildEnhancedTextField(
                                    controller: _nameController,
                                    hintText: "Full Name",
                                    icon: Icons.person_outline,
                                    delay: 0,
                                  ),
                                  const SizedBox(height: 17),
                                  _buildEnhancedTextField(
                                    controller: _emailController,
                                    hintText: "Email Address",
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    delay: 100,
                                  ),
                                  const SizedBox(height: 17),
                                  _buildEnhancedTextField(
                                    controller: _passwordController,
                                    hintText: "Password",
                                    icon: Icons.lock_outline,
                                    obscureText: true,
                                    delay: 200,
                                  ),
                                  const SizedBox(height: 17),
                                  _buildEnhancedRoleSelector(),
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
                                child: _buildEnhancedSignUpButton(),
                              );
                            },
                          ),
                          const SizedBox(height: 17),
                          _buildSignInLink(),
                          const SizedBox(height: 1),
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

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int delay = 0,
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
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
          prefixIcon: Container(
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
              color: TColor.primaryColor1,
              size: 18.7,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 17,
            vertical: 15.3,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRoleSelector() {
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
              Icons.badge_outlined,
              color: TColor.primaryColor1,
              size: 18.7,
            ),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                hint: Text(
                  "Select Role",
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
                items: const [
                  DropdownMenuItem(
                    value: 'user',
                    child: Text('Patient/User'),
                  ),
                  DropdownMenuItem(
                    value: 'doctor',
                    child: Text('Doctor/Specialist'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedRole = value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12.75),
        ],
      ),
    );
  }

  Widget _buildEnhancedSignUpButton() {
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
        onPressed: _isLoading ? null : _signUp,
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
                    "Creating Account...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                "Create Account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.3,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.425,
                ),
              ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.75, horizontal: 17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(21.25),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 0.85,
        ),
      ),
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginView(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Already have an account? ",
              style: TextStyle(
                color: TColor.gray,
                fontSize: 13.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "Sign In",
              style: TextStyle(
                color: TColor.primaryColor1,
                fontSize: 13.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
