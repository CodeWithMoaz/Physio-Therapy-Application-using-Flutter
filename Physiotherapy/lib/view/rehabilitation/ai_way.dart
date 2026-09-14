import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/view/rehabilitation/ai_plan_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class RehabPlansAIPage extends StatefulWidget {
  const RehabPlansAIPage({super.key});

  @override
  _RehabPlansAIPageState createState() => _RehabPlansAIPageState();
}

class _RehabPlansAIPageState extends State<RehabPlansAIPage>
    with TickerProviderStateMixin {
  String selectedInjury = "All";
  String searchQuery = "";
  bool filterApplied = false;

  // Categories for horizontal scrolling
  final List<String> categories = [
    "All",
    "Knee",
    "Ankle",
    "Shoulder",
    "Lower Back"
  ];

  List<Map<String, dynamic>> plans = [];
  List<Map<String, dynamic>> filteredPlans = [];

  // Animation controllers
  late AnimationController _backgroundAnimationController;
  late AnimationController _listAnimationController;
  late AnimationController _searchAnimationController;
  late AnimationController _categoryAnimationController;

  // Animations
  late Animation<double> _backgroundAnimation;
  late Animation<double> _searchPulseAnimation;
  late Animation<double> _categorySlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadPlans();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // List animation controller
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Search animation controller
    _searchAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Category animation controller
    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Background gradient animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    // Search pulse animation
    _searchPulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));

    // Category slide animation
    _categorySlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _categoryAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _backgroundAnimationController.repeat(reverse: true);
    _searchAnimationController.repeat(reverse: true);
    _categoryAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _listAnimationController.dispose();
    _searchAnimationController.dispose();
    _categoryAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('ai_programs').get();

      setState(() {
        plans = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            ...data,
            'id': doc.id,
          };
        }).toList();
        filteredPlans = plans;
      });
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }
  }

  void applyFilter() {
    setState(() {
      filteredPlans = plans.where((plan) {
        return (selectedInjury == "All" || plan["injury"] == selectedInjury) &&
            (searchQuery.isEmpty ||
                plan["injury"]
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                plan["description"]
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()));
      }).toList();
      filterApplied = true;
    });
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
                        const Color(0xffA882DD).withOpacity(0.15),
                        const Color(0xff6d6492).withOpacity(0.1),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.08),
                        const Color(0xffA882DD).withOpacity(0.2),
                        _backgroundAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),

          // Floating decorative elements
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _backgroundAnimationController,
              builder: (context, child) {
                return Positioned(
                  top: 80 +
                      (index * 140) +
                      (25 *
                          math.sin(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  left: (index.isEven ? -40 : media.width - 60) +
                      (15 *
                          math.cos(_backgroundAnimation.value * 2 * math.pi +
                              index)),
                  child: Container(
                    width: 60 + (index * 8),
                    height: 60 + (index * 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          TColor.primaryColor1.withOpacity(0.08),
                          const Color(0xffA882DD).withOpacity(0.03),
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
          Column(
            children: [
              // Enhanced AppBar
              _buildEnhancedAppBar(),

              // Enhanced Search Section
              _buildEnhancedSearchSection(),

              // Enhanced Category Section
              _buildEnhancedCategorySection(),

              // Results Section
              _buildResultsSection(),

              // Enhanced Plans List
              Expanded(
                child: _buildEnhancedPlansList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffA882DD),
            const Color(0xff6d6492),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Back button with animation
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 15),

            // Title with animation
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Plans",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Personalized Strengthening Plans",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // AI Icon with pulse animation
            AnimatedBuilder(
              animation: _searchPulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _searchPulseAnimation.value,
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchSection() {
    return AnimatedBuilder(
      animation: _searchPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _searchPulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xffA882DD).withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xffA882DD).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for plans...",
                hintStyle: TextStyle(
                  color: TColor.gray.withOpacity(0.6),
                  fontSize: 14,
                ),
                filled: false,
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search,
                    color: TColor.primaryColor1,
                    size: 17,
                  ),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.clear,
                            color: Colors.red.shade400,
                            size: 16,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            searchQuery = "";
                          });
                          applyFilter();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                applyFilter();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedCategorySection() {
    return AnimatedBuilder(
      animation: _categorySlideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            (1 - _categorySlideAnimation.value) * 100,
            0,
          ),
          child: Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedInjury == categories[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedInjury = categories[index];
                      });
                      applyFilter();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xffA882DD),
                                  const Color(0xff6d6492),
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  Colors.white,
                                  const Color(0xffA882DD).withOpacity(0.05),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xffA882DD).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xffA882DD).withOpacity(0.4)
                                : const Color(0xffA882DD).withOpacity(0.1),
                            blurRadius: isSelected ? 15 : 8,
                            offset: Offset(0, isSelected ? 6 : 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Text(
                            categories[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : TColor.black,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                              letterSpacing: 0.3,
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
        );
      },
    );
  }

  Widget _buildResultsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xffA882DD).withOpacity(0.1),
                  const Color(0xff6d6492).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xffA882DD).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: TColor.primaryColor1,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${filteredPlans.length} AI Plans Found",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TColor.primaryColor1,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (filterApplied)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextButton.icon(
                icon: Icon(Icons.refresh, size: 16, color: Colors.red.shade400),
                label: Text(
                  "Reset",
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    selectedInjury = "All";
                    searchQuery = "";
                    filteredPlans = plans;
                    filterApplied = false;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlansList() {
    if (filteredPlans.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withOpacity(0.1),
                      Colors.grey.withOpacity(0.05),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "No Plans Found",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: TColor.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Try adjusting your search criteria",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _listAnimationController,
      builder: (context, child) {
        return ListView.builder(
          itemCount: filteredPlans.length,
          padding: const EdgeInsets.only(bottom: 17, left: 14, right: 14),
          itemBuilder: (context, index) {
            var plan = filteredPlans[index];
            return AnimatedContainer(
              duration: Duration(milliseconds: 500 + (index * 100)),
              curve: Curves.easeOutBack,
              child: _buildEnhancedPlanCard(plan, index),
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedPlanCard(Map<String, dynamic> plan, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToDetails(plan),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header section
                Row(
                  children: [
                    // Image with enhanced styling
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xffA882DD).withOpacity(0.1),
                            const Color(0xff6d6492).withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                          color: const Color(0xffA882DD).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          plan["image"] ?? "assets/img/img_5.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "AI ${plan["injury"]} Plan",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: TColor.black,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.green.withOpacity(0.1),
                                      Colors.green.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "FREE",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade600,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan["description"],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: TColor.gray,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Action button
                Container(
                  width: double.infinity,
                  height: 43,
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
                        color: const Color(0xffA882DD).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _navigateToDetails(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "View Details",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
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
    );
  }

  void _navigateToDetails(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 600),
        pageBuilder: (context, animation, secondaryAnimation) =>
            RehabilitationAIPlan(plan: plan),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
