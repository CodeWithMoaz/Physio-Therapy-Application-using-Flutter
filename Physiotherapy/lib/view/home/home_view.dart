import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/common_widget/round_button.dart';
import 'package:physiotherapy/view/profile/profile_view.dart';
import 'package:physiotherapy/view/rehabilitation/doctors_way.dart';
import 'package:physiotherapy/view/rehabilitation/way_of_rehab.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:physiotherapy/view/medical_report_explaination/medical_report_data_extraction.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiotherapy/services/auth_service.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  int _currentSlide = 0;
  final PageController _pageController = PageController();
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _floatingElementsController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatingAnimation;

  bool _isLoaded = false;
  String userName = "Loading...";
  bool isLoading = true;
  List<Map<String, dynamic>> enrolledPlans = [];
  bool isLoadingPlans = true;

  final List<Map<String, String>> _carouselItems = [
    {
      "title": "Rehabilitation Plans",
      "buttonText": "View Plans",
      "routeName": "plans"
    },
    {
      "title": "Connect with Physiotherapist",
      "buttonText": "Connect",
      "routeName": "connect"
    },
    {
      "title": "Rehabilitation Plans",
      "buttonText": "View Plans",
      "routeName": "plans"
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAutoSlider();
    _loadUserData();
    _loadEnrolledPlans();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _floatingElementsController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_floatingElementsController);

    _backgroundAnimationController.repeat(reverse: true);
    _floatingElementsController.repeat();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (userQuery.docs.isNotEmpty && mounted) {
          final userData = userQuery.docs.first.data();
          setState(() {
            userName = userData['fullName'] ?? 'User';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          userName = 'User';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEnrolledPlans() async {
    if (!mounted) return;

    try {
      final user = AuthService().currentUser;
      if (user != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            .get();

        if (userQuery.docs.isNotEmpty && mounted) {
          final userData = userQuery.docs.first.data();
          final enrolledPrograms =
              userData['enrolledPrograms'] as Map<String, dynamic>? ?? {};

          List<Map<String, dynamic>> plans = [];

          for (String programId in enrolledPrograms.keys) {
            if (!mounted) return;

            final programDoc = await FirebaseFirestore.instance
                .collection('programs')
                .doc(programId)
                .get();

            if (programDoc.exists) {
              final programData = programDoc.data()!;
              final enrolledData =
                  enrolledPrograms[programId] as Map<String, dynamic>? ?? {};

              final lastCompletedDay = enrolledData['lastCompletedDay'] ?? 0;
              final totalDays = 30;
              final progress = lastCompletedDay / totalDays;

              plans.add({
                "title": programData['programName'] ?? 'Unknown Program',
                "duration": programData['duration'] ?? '4 weeks',
                "difficulty": programData['severity'] ?? 'Moderate',
                "image": _getProgramImage(programData['injury']),
                "progress": progress,
                "programId": programId,
              });
            }
          }

          if (mounted) {
            setState(() {
              enrolledPlans = plans;
              isLoadingPlans = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading enrolled plans: $e');
      if (mounted) {
        setState(() {
          isLoadingPlans = false;
        });
      }
    }
  }

  String _getProgramImage(String? injury) {
    if (injury == null) return "assets/img/knee.png";

    switch (injury.toLowerCase()) {
      case 'knee':
        return "assets/img/knee.png";
      case 'shoulder':
        return "assets/img/shoulder.png";
      case 'back':
        return "assets/img/back.png";
      case 'ankle':
        return "assets/img/ankle.png";
      default:
        return "assets/img/knee.png";
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    _backgroundAnimationController.dispose();
    _floatingElementsController.dispose();
    super.dispose();
  }

  void _startAutoSlider() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        if (_currentSlide < _carouselItems.length - 1) {
          _currentSlide++;
          _pageController.animateToPage(
            _currentSlide,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _currentSlide = 0;
          _pageController.jumpToPage(0);
        }
        _startAutoSlider();
      }
    });
  }

  void _navigateToRehabRoute(String routeName) {
    if (routeName == "plans") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RehabilitationWayView(),
        ),
      );
    } else if (routeName == "connect") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RehabPlansPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;

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
                        const Color(0xffA882DD).withOpacity(0.08),
                        const Color(0xff6d6492).withOpacity(0.12),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.05),
                        const Color(0xffA882DD).withOpacity(0.15),
                        _backgroundAnimation.value,
                      )!,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              );
            },
          ),
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Positioned(
                  top: 80 +
                      (index * 150) +
                      (25 *
                          math.sin(
                              _floatingAnimation.value * 2 * math.pi + index)),
                  left: (index.isEven ? -30 : mediaSize.width - 70) +
                      (15 *
                          math.cos(
                              _floatingAnimation.value * 2 * math.pi + index)),
                  child: Container(
                    width: 60 + (index * 8),
                    height: 60 + (index * 8),
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
            child: AnimationLimiter(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        mediaSize.height - MediaQuery.of(context).padding.top,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: !_isLoaded
                        ? SizedBox(
                            height: mediaSize.height * 0.8,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffA882DD)
                                          .withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xffA882DD),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : AnimationConfiguration.staggeredList(
                            position: 0,
                            duration: const Duration(milliseconds: 800),
                            child: FadeInAnimation(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 15),
                                  _buildEnhancedAppBar(mediaSize),
                                  SizedBox(height: mediaSize.height * 0.02),
                                  _buildEnhancedInjuryClassificationCard(
                                      mediaSize),
                                  SizedBox(height: mediaSize.height * 0.03),
                                  _buildEnhancedSectionHeader("Rehabilitation",
                                      onSeeMorePressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RehabilitationWayView(),
                                      ),
                                    );
                                  }),
                                  SizedBox(height: mediaSize.height * 0.02),
                                  _buildEnhancedRehabilitationCarousel(
                                      mediaSize),
                                  SizedBox(height: mediaSize.height * 0.03),
                                  _buildEnhancedSectionHeader(
                                      "Latest Enrolled Plans",
                                      onSeeMorePressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const RehabPlansPage(),
                                      ),
                                    );
                                  }),
                                  SizedBox(height: mediaSize.height * 0.02),
                                  _buildEnhancedLatestRehabPlans(mediaSize),
                                  SizedBox(height: mediaSize.height * 0.03),
                                  _buildEnhancedDailyTipCard(mediaSize),
                                  SizedBox(height: mediaSize.height * 0.03),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar(Size mediaSize) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xffA882DD).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: const Color(0xffA882DD).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios,
                  color: const Color(0xffA882DD), size: 15),
              padding: const EdgeInsets.only(left: 5),
              constraints: const BoxConstraints(),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -20, end: 0),
          const SizedBox(width: 15),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.9),
                    const Color(0xffA882DD).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffA882DD).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Back,",
                    style: TextStyle(
                      color: TColor.gray,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isLoading ? "Loading..." : userName,
                    style: TextStyle(
                      color: const Color(0xffA882DD),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -10, end: 0),
          const SizedBox(width: 15),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.05),
                child: child,
              );
            },
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileView()),
              ),
              child: Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xffA882DD),
                      const Color(0xff6d6492),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffA882DD).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    "assets/img/p_personal.png",
                    fit: BoxFit.fitHeight,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).slideX(begin: 20, end: 0),
        ],
      ),
    );
  }

  Widget _buildEnhancedInjuryClassificationCard(Size mediaSize) {
    return AnimatedBuilder(
      animation: _rotateController,
      builder: (context, child) {
        return Container(
          height: mediaSize.height * 0.19,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xffA882DD),
                const Color(0xff6d6492),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffA882DD).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  "assets/img/bg_dots.png",
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.3),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "AI Powered",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Medical Report\nExplanation",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Know more about\nyour injury.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 45,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MriClassificationView(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: const Color(0xffA882DD),
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Explain",
                              style: TextStyle(
                                color: const Color(0xffA882DD),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 800.ms).scaleXY(begin: 0.9, end: 1.0);
      },
    );
  }

  Widget _buildEnhancedSectionHeader(String title,
      {VoidCallback? onSeeMorePressed}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xff2c1810),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          if (onSeeMorePressed != null)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xffA882DD).withOpacity(0.1),
                    const Color(0xff6d6492).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xffA882DD).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: onSeeMorePressed,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      "See More",
                      style: TextStyle(
                        color: const Color(0xffA882DD),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 10,
                      color: const Color(0xffA882DD),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 1000.ms),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 10, end: 0);
  }

  Widget _buildEnhancedRehabilitationCarousel(Size mediaSize) {
    return Container(
      height: mediaSize.height * 0.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.05),
            const Color(0xff6d6492).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              itemCount: _carouselItems.length,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
              },
              itemBuilder: (context, index) {
                final item = _carouselItems[index];
                return _buildEnhancedCarouselItem(
                  title: item["title"]!,
                  buttonText: item["buttonText"]!,
                  routeName: item["routeName"]!,
                );
              },
            ),
          ),
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _carouselItems.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentSlide == index ? 24 : 8,
                  decoration: BoxDecoration(
                    gradient: _currentSlide == index
                        ? LinearGradient(
                            colors: [
                              const Color(0xffA882DD),
                              const Color(0xff6d6492),
                            ],
                          )
                        : null,
                    color: _currentSlide != index
                        ? TColor.gray.withOpacity(0.3)
                        : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1000.ms).moveY(begin: 15, end: 0);
  }

  Widget _buildEnhancedCarouselItem({
    required String title,
    required String buttonText,
    required String routeName,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xff2c1810),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 160,
          height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xffA882DD),
                const Color(0xff6d6492),
              ],
            ),
            borderRadius: BorderRadius.circular(21),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffA882DD).withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () => _navigateToRehabRoute(routeName),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(21),
              ),
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedLatestRehabPlans(Size mediaSize) {
    if (isLoadingPlans) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xffA882DD).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xffA882DD),
            ),
          ),
        ),
      );
    }

    if (enrolledPlans.isEmpty) {
      return _buildEmptyPlansCard(mediaSize);
    }

    return Container(
      height: mediaSize.height * 0.38,
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Latest Enrolled Plans",
            style: TextStyle(
              color: const Color(0xff2c1810),
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: mediaSize.height * 0.02),
          _buildEnhancedLatestRehabPlansList(mediaSize),
        ],
      ),
    ).animate().fadeIn(duration: 1200.ms).slideX(begin: 20, end: 0);
  }

  Widget _buildEmptyPlansCard(Size mediaSize) {
    return Container(
      height: mediaSize.height * 0.25,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD).withOpacity(0.1),
                  const Color(0xff6d6492).withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center_outlined,
              size: 34,
              color: const Color(0xffA882DD),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            "No Plans Yet",
            style: TextStyle(
              color: const Color(0xff2c1810),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 26,
            width: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD),
                  const Color(0xff6d6492),
                ],
              ),
              borderRadius: BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RehabilitationWayView(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                "Explore",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1000.ms).scaleXY(begin: 0.9, end: 1.0);
  }

  Widget _buildEnhancedLatestRehabPlansList(Size mediaSize) {
    return Container(
      height: mediaSize.height * 0.26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        itemCount: enrolledPlans.length,
        separatorBuilder: (context, index) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final plan = enrolledPlans[index];
          return _buildEnhancedRehabPlanCard(plan, mediaSize, index);
        },
      ),
    ).animate().fadeIn(duration: 1200.ms).slideX(begin: 20, end: 0);
  }

  Widget _buildEnhancedRehabPlanCard(
      Map<String, dynamic> plan, Size mediaSize, int index) {
    final progress = plan['progress'] ?? 0.0;
    final progressPercentage = (progress * 100).round();

    return Container(
      width: mediaSize.width * 0.64,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.03),
            const Color(0xff6d6492).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.15),
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
                width: 43,
                height: 43,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xffA882DD).withOpacity(0.2),
                      const Color(0xff6d6492).withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Image.asset(
                  plan['image'] ?? 'assets/img/knee_rehab.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.fitness_center,
                      color: const Color(0xffA882DD),
                      size: 20,
                    );
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan['title'] ?? 'Rehabilitation Plan',
                      style: TextStyle(
                        color: const Color(0xff2c1810),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 10,
                          color: TColor.gray,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          plan['duration'] ?? '4 weeks',
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(plan['difficulty']),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan['difficulty'] ?? 'Moderate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress",
                style: TextStyle(
                  color: const Color(0xff2c1810),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "$progressPercentage%",
                style: TextStyle(
                  color: const Color(0xffA882DD),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xffA882DD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xffA882DD),
                      const Color(0xff6d6492),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD),
                  const Color(0xff6d6492),
                ],
              ),
              borderRadius: BorderRadius.circular(21),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RehabPlansPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(21),
                ),
              ),
              child: Text(
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 200 * index))
        .fadeIn(duration: 800.ms)
        .slideX(begin: 30, end: 0);
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'hard':
      case 'severe':
        return Colors.red;
      default:
        return const Color(0xffA882DD);
    }
  }

  Widget _buildEnhancedDailyTipCard(Size mediaSize) {
    final tips = [
      {
        "title": "Stay Hydrated",
        "description":
            "Drink plenty of water throughout your rehabilitation process to help muscle recovery.",
        "icon": Icons.local_drink,
      },
      {
        "title": "Rest & Recovery",
        "description":
            "Allow adequate rest between sessions for optimal healing and muscle growth.",
        "icon": Icons.bedtime,
      },
      {
        "title": "Consistency is Key",
        "description":
            "Regular, consistent exercise is more effective than intense, sporadic sessions.",
        "icon": Icons.repeat,
      },
      {
        "title": "Listen to Your Body",
        "description":
            "Pay attention to pain signals and adjust your routine accordingly.",
        "icon": Icons.hearing,
      },
    ];

    final randomTip = tips[math.Random().nextInt(tips.length)];

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xff6d6492).withOpacity(0.1),
            const Color(0xffA882DD).withOpacity(0.05),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD),
                  const Color(0xff6d6492),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              randomTip['icon'] as IconData,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffA882DD).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Daily Tip",
                        style: TextStyle(
                          color: const Color(0xffA882DD),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  randomTip['title'] as String,
                  style: TextStyle(
                    color: const Color(0xff2c1810),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  randomTip['description'] as String,
                  style: TextStyle(
                    color: TColor.gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 1400.ms).slideY(begin: 20, end: 0);
  }
}
