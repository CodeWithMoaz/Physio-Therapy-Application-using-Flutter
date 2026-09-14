import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/view/rehabilitation/doctors_plan_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiotherapy/models/doctor_model.dart';
import 'package:physiotherapy/models/program_model.dart';
import 'dart:math' as math;

class RehabPlansPage extends StatefulWidget {
  const RehabPlansPage({super.key});

  @override
  _RehabPlansPageState createState() => _RehabPlansPageState();
}

class _RehabPlansPageState extends State<RehabPlansPage>
    with TickerProviderStateMixin {
  String selectedInjury = "All";
  String selectedSeverity = "All";
  String selectedSort = "Relevance";
  String searchQuery = "";
  bool filterApplied = false;
  bool isFilterVisible = false;
  List<Map<String, dynamic>> plans = [];
  List<Map<String, dynamic>> filteredPlans = [];
  bool isLoading = true;

  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _filterAnimationController;
  late AnimationController _cardAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchPulseAnimation;
  late Animation<double> _categorySlideAnimation;
  late Animation<double> _filterAnimation;
  late Animation<double> _cardStaggerAnimation;

  // Categories for horizontal scrolling
  final List<String> categories = [
    "All",
    "Knee",
    "Ankle",
    "Shoulder",
    "Lower Back"
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _loadPrograms();
  }

  void _initializeAnimations() {
    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Main animation controller for page entrance
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Filter animation controller
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Card animation controller
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Background gradient animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    // Search pulse animation
    _searchPulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeInOut,
    ));

    // Category slide animation
    _categorySlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.elasticOut,
    ));

    // Filter animation
    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    // Card stagger animation
    _cardStaggerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_cardAnimationController);
  }

  void _startAnimations() {
    _backgroundAnimationController.repeat(reverse: true);
    _mainAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _filterAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPrograms() async {
    try {
      setState(() {
        isLoading = true;
      });
      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic> userEnrollments = {};
      if (user != null) {
        // Get user's enrolled programs
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          userEnrollments = userDoc.data()?['enrolledPrograms'] ?? {};
        }
      }
      // Get all programs
      final programsSnapshot =
          await FirebaseFirestore.instance.collection('programs').get();
      // Get all doctors who manage programs
      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('programsManaged', isNotEqualTo: []).get();
      // Create a map of doctor data by their ID
      final doctorsMap = {
        for (var doc in doctorsSnapshot.docs)
          doc.id: DoctorModel.fromFirestore(doc)
      };
      // Create a map of program IDs to doctor IDs
      final programToDoctorMap = <String, String>{};
      for (var doctorDoc in doctorsSnapshot.docs) {
        final doctor = DoctorModel.fromFirestore(doctorDoc);
        for (var programId in doctor.programsManaged) {
          programToDoctorMap[programId] = doctor.id;
        }
      }
      List<Map<String, dynamic>> loadedPlans = [];
      for (var programDoc in programsSnapshot.docs) {
        final program = ProgramModel.fromFirestore(programDoc);
        final programId = program.programId;
        // Find the doctor who manages this program
        DoctorModel? managingDoctor;
        if (programToDoctorMap.containsKey(programId)) {
          final doctorId = programToDoctorMap[programId];
          managingDoctor = doctorsMap[doctorId];
        }
        loadedPlans.add({
          "id": programId,
          "programName": program.programName,
          "injury": program.injury,
          "severity": program.severity,
          "maxPatients": program.maxPatients,
          "ageGroup": program.ageGroup,
          "duration": program.duration,
          "description": program.description,
          "price": program.price,
          "doctor": managingDoctor?.fullName ?? "Unknown Doctor",
          "doctorImage": managingDoctor?.profileImage ??
              (managingDoctor?.gender.toLowerCase() == 'female'
                  ? 'assets/img/doctor1.jpg'
                  : 'assets/img/doctor3.jpg'),
          "specialization": managingDoctor?.specialization ?? "General",
          "experience": "${managingDoctor?.yearsOfExperience ?? 0} years",
          "rating": 4.5,
          "bio": managingDoctor?.additionalInformation ?? "",
          "patients": 0,
          "isEnrolled": userEnrollments.containsKey(programId),
        });
      }
      setState(() {
        plans = loadedPlans;
        filteredPlans = List.from(plans);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading programs: $e');
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error loading programs: $e');
    }
  }

  Future<void> enrollInProgram(Map<String, dynamic> plan) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showErrorSnackBar('Please login to enroll in a program');
        return;
      }
      // Update user's enrolled programs
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'enrolledPrograms.${plan["id"]}': {
          'enrolledAt': FieldValue.serverTimestamp(),
          'progress': 0.0,
          'lastVisit': DateTime.now().toString().split(' ')[0],
        }
      });
      // Update program's enrolled patients count
      await FirebaseFirestore.instance
          .collection('programs')
          .doc(plan["id"])
          .update({'enrolledPatients': FieldValue.increment(1)});
      _showSuccessSnackBar(
          'Successfully enrolled in ${plan["doctor"]}\'s program');
      // Refresh the programs list
      await _loadPrograms();
    } catch (e) {
      print('Error enrolling in program: $e');
      _showErrorSnackBar('Error enrolling in program: $e');
    }
  }

  void applyFilter() {
    setState(() {
      filteredPlans = plans.where((plan) {
        final planInjury = plan["injury"] ?? 'General';
        final injuryMatch = (selectedInjury == "All" ||
            planInjury.toLowerCase() == selectedInjury.toLowerCase());
        return injuryMatch &&
            (selectedSeverity == "All" ||
                plan["severity"] == selectedSeverity) &&
            (searchQuery.isEmpty ||
                plan["doctor"]
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                plan["injury"]
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()) ||
                plan["description"]
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()));
      }).toList();
      sortPlans();
      filterApplied = true;
    });
  }

  void sortPlans() {
    if (selectedSort == "Price: Low to High") {
      filteredPlans.sort((a, b) => a["price"].compareTo(b["price"]));
    } else if (selectedSort == "Price: High to Low") {
      filteredPlans.sort((a, b) => b["price"].compareTo(a["price"]));
    } else if (selectedSort == "Rating") {
      filteredPlans.sort((a, b) => b["rating"].compareTo(a["rating"]));
    } else if (selectedSort == "Duration") {
      filteredPlans.sort((a, b) {
        int getDurationValue(String duration) {
          if (duration.contains("Week")) {
            return int.parse(duration.split(" ")[0]);
          } else if (duration.contains("Month")) {
            return int.parse(duration.split(" ")[0]) * 4;
          }
          return 0;
        }

        return getDurationValue(a["duration"])
            .compareTo(getDurationValue(b["duration"]));
      });
    }
  }

  void toggleFilterVisibility() {
    setState(() {
      isFilterVisible = !isFilterVisible;
      if (isFilterVisible) {
        _filterAnimationController.forward();
      } else {
        _filterAnimationController.reverse();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Widget buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == rating.floor() && rating % 1 > 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
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
            animation: _fadeAnimation,
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
                        _fadeAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.08),
                        const Color(0xffA882DD).withOpacity(0.2),
                        _fadeAnimation.value,
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
                          math.sin(_backgroundAnimationController.value *
                                  2 *
                                  math.pi +
                              index)),
                  left: (index.isEven ? -40 : media.width - 60) +
                      (15 *
                          math.cos(_backgroundAnimationController.value *
                                  2 *
                                  math.pi +
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
        top: (MediaQuery.of(context).padding.top + 10) * 0.85,
        left: 17,
        right: 17,
        bottom: 8,
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
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 17,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Doctor Programs",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
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
                    "Expert-Led Recovery Plans",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedBuilder(
              animation: _searchPulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _searchPulseAnimation.value,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 20,
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
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: const Color(0xffA882DD).withOpacity(0.3),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffA882DD).withOpacity(0.15),
                  blurRadius: 17,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search programs, doctors, conditions...",
                hintStyle: TextStyle(
                  color: TColor.gray.withOpacity(0.6),
                  fontSize: 14,
                ),
                filled: false,
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(7),
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
                    Icons.search,
                    color: TColor.primaryColor1,
                    size: 17,
                  ),
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.clear,
                            color: Colors.red.shade400,
                            size: 14,
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
                  horizontal: 17,
                  vertical: 15,
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
            (1 - _categorySlideAnimation.value) * 85,
            0,
          ),
          child: Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedInjury == categories[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
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
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : const Color(0xffA882DD).withOpacity(0.3),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xffA882DD).withOpacity(0.4)
                                : const Color(0xffA882DD).withOpacity(0.1),
                            blurRadius: isSelected ? 13 : 7,
                            offset: Offset(0, isSelected ? 5 : 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 7),
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
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
                  "${filteredPlans.length} Plans Found",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TColor.primaryColor1,
                    fontSize: 14,
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
                    selectedSeverity = "All";
                    selectedSort = "Relevance";
                    searchQuery = "";
                    filteredPlans = List.from(plans);
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
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
                borderRadius: BorderRadius.circular(30),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Loading rehabilitation plans...",
              style: TextStyle(
                fontSize: 16,
                color: TColor.primaryColor1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

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
      animation: _cardStaggerAnimation,
      builder: (context, child) {
        return ListView.builder(
          itemCount: filteredPlans.length,
          padding: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
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
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.15),
            blurRadius: 17,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 600),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    RehabPlanDetailsPage(plan: plan),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
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
          },
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'doctor_${plan["id"]}',
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
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
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            plan["doctorImage"],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xffA882DD),
                                      const Color(0xff6d6492),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 34,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  plan["doctor"],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: TColor.black,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xffA882DD).withOpacity(0.1),
                                      const Color(0xff6d6492).withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(
                                    color: const Color(0xffA882DD)
                                        .withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "\$${plan["price"]}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: TColor.primaryColor1,
                                    fontSize: 12,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            plan["specialization"],
                            style: TextStyle(
                              fontSize: 12,
                              color: TColor.gray,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              buildRatingStars(plan["rating"]),
                              const SizedBox(width: 7),
                              Text(
                                "${plan["rating"]}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "(${plan["patients"]})",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xffA882DD).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              plan["programName"] ?? "Rehabilitation Program",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: TColor.primaryColor1,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(plan["severity"])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getSeverityColor(plan["severity"])
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              plan["severity"],
                              style: TextStyle(
                                color: _getSeverityColor(plan["severity"]),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
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
                      const SizedBox(height: 13),
                      Row(
                        children: [
                          _buildEnhancedInfoChip(
                            Icons.medical_services,
                            plan["injury"],
                            const Color(0xff4CAF50),
                          ),
                          const SizedBox(width: 8),
                          _buildEnhancedInfoChip(
                            Icons.schedule,
                            plan["duration"],
                            const Color(0xff2196F3),
                          ),
                          const SizedBox(width: 8),
                          _buildEnhancedInfoChip(
                            Icons.group,
                            "${plan["maxPatients"]} max",
                            const Color(0xffFF9800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffA882DD).withOpacity(0.05),
                              const Color(0xff6d6492).withOpacity(0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              color: TColor.primaryColor1,
                              size: 20,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Experience",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan["experience"],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TColor.primaryColor1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xffA882DD).withOpacity(0.05),
                              const Color(0xff6d6492).withOpacity(0.03),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              color: TColor.primaryColor1,
                              size: 20,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "Age Group",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              plan["ageGroup"] ?? "All Ages",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TColor.primaryColor1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
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
                    borderRadius: BorderRadius.circular(13),
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
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 600),
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  RehabPlanDetailsPage(plan: plan),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
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
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          plan["isEnrolled"]
                              ? Icons.play_circle_outline
                              : Icons.visibility,
                          color: Colors.white,
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plan["isEnrolled"]
                              ? "Continue Program"
                              : "View Details",
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

  Widget _buildEnhancedInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case '1st degree':
        return const Color(0xff4CAF50);
      case '2nd degree':
        return const Color(0xffFF9800);
      case '3rd degree':
        return const Color(0xffF44336);
      default:
        return const Color(0xff2196F3);
    }
  }
}
