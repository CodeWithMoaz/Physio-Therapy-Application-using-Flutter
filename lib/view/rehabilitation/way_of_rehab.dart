import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
//import 'package:physiotherapy/view/home/home_view.dart';
import 'package:physiotherapy/view/rehabilitation/ai_way.dart';
import 'package:physiotherapy/view/rehabilitation/doctors_way.dart';
import 'dart:math' as math;

class RehabilitationWayView extends StatefulWidget {
  const RehabilitationWayView({super.key});

  @override
  State<RehabilitationWayView> createState() => _RehabilitationWayViewState();
}

class _RehabilitationWayViewState extends State<RehabilitationWayView>
    with SingleTickerProviderStateMixin {
  String? selectedOption;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  void _selectOption(String option) {
    setState(() {
      selectedOption = option;
    });
  }

  void _navigateToNextScreen() {
    if (selectedOption == "Physio") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RehabPlansPage()),
      );
    } else if (selectedOption != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RehabPlansAIPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated background gradient
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

          // Floating decorative elements
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

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: media.width * 0.02),
                  // Back Button and Title
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20, left: 20),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
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
                                      color: const Color(0xffA882DD)
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
                            SizedBox(width: media.width * 0.07),
                            Text(
                              "Rehabilitation Way",
                              style: TextStyle(
                                color: TColor.black,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: media.width * 0.05),
                  // Content
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: TColor.primaryColor1, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: TColor.primaryColor1.withOpacity(0.1),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Physiotherapist option (now first)
                            GestureDetector(
                              onTap: () => _selectOption("Physio"),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: MediaQuery.of(context).size.width * 0.7,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: selectedOption == "Physio"
                                      ? LinearGradient(colors: TColor.primaryG)
                                      : null,
                                  color: selectedOption == "Physio"
                                      ? null
                                      : TColor.lighthighGray,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    if (selectedOption == "Physio")
                                      BoxShadow(
                                        color: TColor.primaryColor1
                                            .withOpacity(0.6),
                                        blurRadius: 10,
                                        spreadRadius: 3,
                                      ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/img/doctor.png',
                                      width: 200,
                                      height: 150,
                                    ),
                                    SizedBox(height: 7),
                                    Text(
                                      "Supervised by Physiotherapist",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: selectedOption == "Physio"
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selectedOption == "Physio"
                                            ? Colors.white
                                            : TColor.black,
                                      ),
                                    ),
                                    Text(
                                      "(For Injury Treatment)",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: selectedOption == "Physio"
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        color: selectedOption == "Physio"
                                            ? Colors.white
                                            : TColor.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            // AI option (now second)
                            GestureDetector(
                              onTap: () => _selectOption("AI"),
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 200),
                                width: MediaQuery.of(context).size.width * 0.7,
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: selectedOption == "AI"
                                      ? LinearGradient(colors: TColor.primaryG)
                                      : null,
                                  color: selectedOption == "AI"
                                      ? null
                                      : TColor.lighthighGray,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    if (selectedOption == "AI")
                                      BoxShadow(
                                        color: TColor.primaryColor1
                                            .withOpacity(0.6),
                                        blurRadius: 10,
                                        spreadRadius: 3,
                                      ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/img/ai_supervise.png',
                                      width: 200,
                                      height: 150,
                                    ),
                                    SizedBox(height: 7),
                                    Text(
                                      "Supervised by Artificial Intelligence",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: selectedOption == "AI"
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: selectedOption == "AI"
                                            ? Colors.white
                                            : TColor.black,
                                      ),
                                    ),
                                    Text(
                                      "(For Injury Prevention)",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: selectedOption == "AI"
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                        color: selectedOption == "AI"
                                            ? Colors.white
                                            : TColor.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Select Button
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: _navigateToNextScreen,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TColor.primaryColor1,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: TColor.primaryColor1.withOpacity(0.5),
                          ),
                          child: Text(
                            "Select",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: TColor.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
