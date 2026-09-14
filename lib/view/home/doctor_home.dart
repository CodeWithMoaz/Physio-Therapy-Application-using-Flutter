import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/view/login/login_view.dart';

import 'package:physiotherapy/view/rehabilitation/manage_rehabilitation.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiotherapy/services/auth_service.dart';

class DoctorHomeView extends StatefulWidget {
  const DoctorHomeView({super.key});

  @override
  State<DoctorHomeView> createState() => _DoctorHomeViewState();
}

class _DoctorHomeViewState extends State<DoctorHomeView>
    with TickerProviderStateMixin {
  bool isManageRehabCardPressed = false;
  bool isPatientChatsCardPressed = false;
  String doctorName = "Loading...";
  bool isLoading = true;
  int managedProgramsCount = 0;
  int totalPlansCount = 0;

  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _pulseController;
  late AnimationController _cardAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _cardFloatAnimation;

  final List<GlobalKey> _cardKeys = [GlobalKey(), GlobalKey()];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDoctorData();
    _startAnimations();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
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
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _cardFloatAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(
          parent: _cardAnimationController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    _backgroundAnimationController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
    _cardAnimationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playStaggeredAnimations();
    });
  }

  void _playStaggeredAnimations() {
    for (int i = 0; i < _cardKeys.length; i++) {
      Future.delayed(Duration(milliseconds: 600 + (300 * i)), () {
        final BuildContext? context = _cardKeys[i].currentContext;
        if (context != null) {
          setState(() {});
        }
      });
    }
  }

  Future<void> _loadDoctorData() async {
    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final doctorQuery = await FirebaseFirestore.instance
            .collection('doctors')
            .where('email', isEqualTo: user.email)
            .get();

        if (doctorQuery.docs.isNotEmpty) {
          final doctorData = doctorQuery.docs.first.data();
          setState(() {
            doctorName = doctorData['fullName'] ?? 'Doctor';
          });

          final programsManaged =
              List<String>.from(doctorData['programsManaged'] ?? []);
          setState(() {
            managedProgramsCount = programsManaged.length;
          });

          await _loadTotalPlansCount(programsManaged);
        }
      }
    } catch (e) {
      print('Error loading doctor data: $e');
      setState(() {
        doctorName = 'Doctor';
        managedProgramsCount = 0;
        totalPlansCount = 0;
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadTotalPlansCount(List<String> programIds) async {
    try {
      int totalPlans = 0;

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final enrolledPrograms =
            userData['enrolledPrograms'] as Map<String, dynamic>? ?? {};

        for (String programId in programIds) {
          if (enrolledPrograms.containsKey(programId)) {
            totalPlans++;
          }
        }
      }

      setState(() {
        totalPlansCount = totalPlans;
      });
    } catch (e) {
      print('Error loading total plans count: $e');
      setState(() {
        totalPlansCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _pulseController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
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
                        const Color(0xffA882DD).withOpacity(0.15),
                        const Color(0xff6d6492).withOpacity(0.1),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.08),
                        const Color(0xffA882DD).withOpacity(0.12),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        TColor.ivory.withOpacity(0.95),
                        Colors.white.withOpacity(0.98),
                        _backgroundAnimation.value,
                      )!,
                    ],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              );
            },
          ),
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: 80 +
                      (index * 100) +
                      (25 *
                          math.sin(_backgroundAnimation.value * 2 * math.pi +
                              index * 0.7)),
                  left: (index.isEven ? -60 : media.width - 40) +
                      (30 *
                          math.cos(_backgroundAnimation.value * 2 * math.pi +
                              index * 0.5)),
                  child: Container(
                    width: 60 + (index * 8),
                    height: 60 + (index * 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xffA882DD).withOpacity(0.08),
                          const Color(0xff6d6492).withOpacity(0.04),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xffA882DD).withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
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
                );
              },
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: child,
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white,
                                      const Color(0xffA882DD).withOpacity(0.02),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xffA882DD)
                                        .withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffA882DD)
                                          .withOpacity(0.15),
                                      blurRadius: 25,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (context,
                                                            animation,
                                                            secondaryAnimation) =>
                                                        const LoginView(),
                                                    transitionsBuilder:
                                                        (context,
                                                            animation,
                                                            secondaryAnimation,
                                                            child) {
                                                      return FadeTransition(
                                                        opacity: animation,
                                                        child: SlideTransition(
                                                          position:
                                                              Tween<Offset>(
                                                            begin: const Offset(
                                                                -1.0, 0.0),
                                                            end: Offset.zero,
                                                          ).animate(animation),
                                                          child: child,
                                                        ),
                                                      );
                                                    },
                                                    transitionDuration:
                                                        const Duration(
                                                            milliseconds: 600),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(8),
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
                                                      color: const Color(
                                                              0xffA882DD)
                                                          .withOpacity(0.3),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.arrow_back,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              width: 80,
                                              height: 68,
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
                                                    color:
                                                        const Color(0xffA882DD)
                                                            .withOpacity(0.3),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.person_outline,
                                                color: Colors.white,
                                                size: 34,
                                              ),
                                            ),
                                            SizedBox(width: 40),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      isLoading
                                          ? "Loading..."
                                          : "Welcome, Dr. $doctorName!",
                                      style: TextStyle(
                                        color: TColor.black,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Manage your patients and rehabilitation plans efficiently with advanced tools.",
                                      style: TextStyle(
                                        color: TColor.gray,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  _buildEnhancedStatCard(
                                    "Programs",
                                    managedProgramsCount.toString(),
                                    Icons.medical_services_outlined,
                                    [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600
                                    ],
                                    0,
                                  ),
                                  const SizedBox(width: 15),
                                  _buildEnhancedStatCard(
                                    "Total Plans",
                                    totalPlansCount.toString(),
                                    Icons.assignment_outlined,
                                    [
                                      Colors.orange.shade400,
                                      Colors.orange.shade600
                                    ],
                                    100,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 21,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xffA882DD),
                                          const Color(0xff6d6492),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    "Quick Actions",
                                    style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          _buildEnhancedActionCard(
                            key: _cardKeys[0],
                            icon: Icons.assignment_outlined,
                            title: "Manage Rehab Plans",
                            subtitle:
                                "Create and update rehabilitation plans for your patients with comprehensive tools.",
                            gradientColors: [
                              const Color(0xffA882DD),
                              const Color(0xff6d6492),
                            ],
                            isPressed: isManageRehabCardPressed,
                            onTapDown: () {
                              setState(() {
                                isManageRehabCardPressed = true;
                              });
                            },
                            onTapUp: () {
                              setState(() {
                                isManageRehabCardPressed = false;
                              });
                              _navigateWithTransition(
                                  const ManageRehabPlansView());
                            },
                            delay: 0,
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

  void _navigateWithTransition(Widget destination) {
    Navigator.push(
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

  Widget _buildEnhancedActionCard({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 1000 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedBuilder(
          animation: _cardFloatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _cardFloatAnimation.value),
              child: child,
            );
          },
          child: GestureDetector(
            onTapDown: (_) => onTapDown(),
            onTapUp: (_) => onTapUp(),
            onTapCancel: () {
              setState(() {
                isPressed = false;
              });
            },
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: isPressed ? 0.95 : 1.0,
              child: Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 51,
                      height: 51,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    String title,
    String value,
    IconData icon,
    List<Color> gradientColors,
    int delay,
  ) {
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 800 + delay),
        curve: Curves.easeOutBack,
        builder: (context, animValue, child) {
          return Transform.scale(
            scale: animValue,
            child: Opacity(
              opacity: animValue.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _cardFloatAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _cardFloatAnimation.value * 0.5),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  gradientColors.first.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: gradientColors.first.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors.first.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 19),
                ),
                const SizedBox(height: 15),
                Text(
                  value,
                  style: TextStyle(
                    color: gradientColors.first,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
