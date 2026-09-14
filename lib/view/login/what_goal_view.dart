import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physiotherapy/view/home/home_view.dart';
import 'package:physiotherapy/view/rehabilitation/way_of_rehab.dart';
import 'package:physiotherapy/view/medical_report_explaination/medical_report_data_extraction.dart';

import '../../common/color_extension.dart';
import '../../common_widget/round_button.dart';
import 'dart:math' as math;

class WhatYourGoalView extends StatefulWidget {
  const WhatYourGoalView({super.key});

  @override
  State<WhatYourGoalView> createState() => WhatYourGoalViewState();
}

class WhatYourGoalViewState extends State<WhatYourGoalView>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.7);
  int _currentPage = 0;
  bool _isPressed = false;
  double _pageOffset = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Color> _gradientColors = [
    const Color(0xFF6F72CA),
    const Color(0xFF1E1466),
  ];

  List goalArr = [
    {
      "image": "assets/img/patient.png",
      "title": "Classify Injury",
      "subtitle":
          "I have done MRI on my injury and\n I can't read the report to\n know what I have",
    },
    {
      "image": "assets/img/doctor.png",
      "title": "Rehabilitation",
      "subtitle":
          "I want to start rehabilitation to aid\nmy recovery, but I'm unsure about\nthe best approach or how long it\nwill take to see progress.",
    },
  ];

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
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
          ...List.generate(6, (index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: 100 +
                      (index * 120) +
                      (30 *
                          math.sin(_animationController.value * 2 * math.pi +
                              index)),
                  left: (index.isEven ? -50 : media.width - 50) +
                      (20 *
                          math.cos(_animationController.value * 2 * math.pi +
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(290, 10, 20, 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTapDown: (details) {
                            setState(() {
                              _isPressed = true;
                            });
                          },
                          onTapUp: (details) {
                            setState(() {
                              _isPressed = false;
                            });
                            HapticFeedback.mediumImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeView(),
                              ),
                            );
                          },
                          onTapCancel: () {
                            setState(() {
                              _isPressed = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _isPressed
                                  ? TColor.primaryColor1
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: TColor.gray
                                      .withOpacity(_isPressed ? 0.1 : 0.2),
                                  offset: _isPressed
                                      ? const Offset(0, 1)
                                      : const Offset(0, 4),
                                  blurRadius: _isPressed ? 3 : 10,
                                ),
                              ],
                              border: Border.all(
                                color: TColor.gray.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            transform: Matrix4.identity()
                              ..translate(_isPressed ? 0.0 : 0.0,
                                  _isPressed ? 1.0 : 0.0),
                            child: Text(
                              "Skip",
                              style: TextStyle(
                                color: _isPressed
                                    ? TColor.white
                                    : TColor.primaryColor1,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: media.width * 0.02),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
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
                            "What is your goal?",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.03),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(goalArr.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 18 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: _currentPage == index
                              ? TColor.primaryColor1
                              : TColor.gray.withOpacity(0.2),
                          boxShadow: _currentPage == index
                              ? [
                                  BoxShadow(
                                    color:
                                        TColor.primaryColor1.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: media.width * 0.05),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: goalArr.length,
                    itemBuilder: (context, index) {
                      double scale = _currentPage == index ? 1.0 : 0.8;
                      return TweenAnimationBuilder(
                        duration: Duration(milliseconds: 300),
                        tween: Tween(begin: scale, end: scale),
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: TColor.primaryG,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: media.width * 0.1,
                            horizontal: 25,
                          ),
                          alignment: Alignment.center,
                          child: FittedBox(
                            child: Column(
                              children: [
                                Image.asset(
                                  goalArr[index]["image"].toString(),
                                  width: media.width * 0.5,
                                  fit: BoxFit.fitWidth,
                                ),
                                SizedBox(height: media.width * 0.1),
                                Text(
                                  goalArr[index]["title"].toString(),
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  width: media.width * 0.1,
                                  height: 1,
                                  color: TColor.white,
                                ),
                                SizedBox(height: media.width * 0.02),
                                Text(
                                  goalArr[index]["subtitle"].toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 12,
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
                SizedBox(height: media.width * 0.07),
                SizedBox(height: 10),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: media.width * 0.05),
                  child: SizedBox(
                    width: media.width * 0.9,
                    child: RoundButton(
                      title: "Confirm",
                      onPressed: () {
                        if (_currentPage == 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MriClassificationView(),
                            ),
                          );
                        } else if (_currentPage == 1) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RehabilitationWayView(),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.05),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
