import 'package:flutter/material.dart';
import 'package:physiotherapy/view/login/sign_up_view.dart';
import '../../common/color_extension.dart';

class OnBoardingView extends StatefulWidget {
  const OnBoardingView({super.key});

  @override
  State<OnBoardingView> createState() => OnBoardingViewState();
}

class OnBoardingViewState extends State<OnBoardingView>
    with SingleTickerProviderStateMixin {
  int selectPage = 0;
  late PageController controller;
  late AnimationController _animationController;
  late Animation<double> _nextButtonAnimation;
  late Animation<double> _pageIndicatorAnimation;

  final List<Color> _gradientColors = [
    Color(0xFF6A11CB),
    Color(0xFF2575FC),
    Color(0xFF8E2DE2),
    Color(0xFF4A00E0),
  ];

  @override
  void initState() {
    super.initState();
    controller = PageController();
    controller.addListener(() {
      selectPage = controller.page?.round() ?? 0;
      setState(() {});
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _nextButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _pageIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List pageArr = [
    {
      "title": "Diagnose Injury",
      "subtitle":
          "Identify your Injury degree for Proper Treatment and Faster Recovery.",
      "image": "assets/img/on1.png",
      "gradient": [Color(0xffA882DD), Color(0xff6d6492)],
    },
    {
      "title": "Meet Specialists",
      "subtitle":
          "Get Expert Guidance for Personalized Care and a Stronger Recovery.",
      "image": "assets/img/on2.png",
      "gradient": [Color(0xffA882DD), Color(0xff6d6492)],
    },
    {
      "title": "Get Back to Court",
      "subtitle":
          "Recover your injury fast and easily through our rehabilitation plans.",
      "image": "assets/img/on3.png",
      "gradient": [Color(0xffA882DD), Color(0xff6d6492)],
    },
    {
      "title": "Stay Fit",
      "subtitle":
          "Maintain an Active Lifestyle and Build Strength for Long-Term Health.",
      "image": "assets/img/on4.png",
      "gradient": [Color(0xffA882DD), Color(0xff6d6492)],
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _gradientColors[selectPage % _gradientColors.length]
                      .withOpacity(0.1),
                  _gradientColors[(selectPage + 1) % _gradientColors.length]
                      .withOpacity(0.1),
                ],
              ),
            ),
          ),
          PageView.builder(
              controller: controller,
              itemCount: pageArr.length,
              itemBuilder: (context, index) {
                var pObj = pageArr[index] as Map? ?? {};

                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    double value = 1.0;
                    if (controller.position.haveDimensions) {
                      value = (controller.page! - index).abs();
                      value = (1 - (value.clamp(0.0, 1.0))).toDouble();
                    }
                    return Transform.scale(
                      scale: Curves.easeInOut.transform(value),
                      child: Opacity(
                        opacity: Curves.easeIn.transform(value),
                        child: EnhancedOnBoardingPage(pObj: pObj),
                      ),
                    );
                  },
                );
              }),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _pageIndicatorAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pageArr.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 10,
                      width: selectPage == index ? 25 : 10,
                      decoration: BoxDecoration(
                        color: selectPage == index
                            ? TColor.primaryColor1
                            : TColor.primaryColor1.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: selectPage == index
                            ? [
                                BoxShadow(
                                  color: TColor.primaryColor1.withOpacity(0.5),
                                  blurRadius: 8 * _pageIndicatorAnimation.value,
                                  spreadRadius:
                                      2 * _pageIndicatorAnimation.value,
                                )
                              ]
                            : [],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: AnimatedBuilder(
              animation: _nextButtonAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _nextButtonAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TColor.primaryColor1,
                          TColor.primaryColor1.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: TColor.primaryColor1.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            color: Colors.white.withOpacity(0.9),
                            value: (selectPage + 1) / 4,
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        IconButton(
                          icon: selectPage < 3
                              ? Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 30,
                                ),
                          onPressed: () {
                            if (selectPage < 3) {
                              controller.animateToPage(
                                selectPage + 1,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      const SignUpView(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    var begin = const Offset(1.0, 0.0);
                                    var end = Offset.zero;
                                    var curve = Curves.easeInOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SignUpView(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              child: Text(
                "Skip",
                style: TextStyle(
                  color: TColor.primaryColor1,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedOnBoardingPage extends StatefulWidget {
  final Map pObj;
  const EnhancedOnBoardingPage({Key? key, required this.pObj})
      : super(key: key);

  @override
  State<EnhancedOnBoardingPage> createState() => _EnhancedOnBoardingPageState();
}

class _EnhancedOnBoardingPageState extends State<EnhancedOnBoardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _imageAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    List<Color> gradientColors =
        widget.pObj["gradient"] ?? [Color(0xFF6A11CB), Color(0xFF2575FC)];

    return Container(
      margin: EdgeInsets.only(top: media.height * 0.15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _imageAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _imageAnimation.value,
                child: Opacity(
                  opacity: _imageAnimation.value,
                  child: Container(
                    width: media.width * 0.9,
                    height: media.width * 0.9,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                        stops: const [0.2, 0.8],
                      ),
                      borderRadius: BorderRadius.circular(media.width * 0.375),
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(media.width * 0.12),
                    child: Image.asset(
                      widget.pObj["image"],
                      width: media.width * 0.65,
                      height: media.width * 0.65,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: media.width * 0.10),
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - _textAnimation.value)),
                child: Opacity(
                  opacity: _textAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(
                      children: [
                        Text(
                          widget.pObj["title"] ?? "",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TColor.primaryColor1,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: TColor.primaryColor1.withOpacity(0.2),
                                offset: const Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          widget.pObj["subtitle"] ?? "",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: TColor.gray,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
