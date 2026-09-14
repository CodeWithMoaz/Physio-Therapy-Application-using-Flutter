import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/models/program_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:physiotherapy/view/rehabilitation/manage_patient_plan.dart';

class PatientPlanDetailsPage extends StatefulWidget {
  final ProgramModel program;

  const PatientPlanDetailsPage({super.key, required this.program});

  @override
  State<PatientPlanDetailsPage> createState() => _PatientPlanDetailsPageState();
}

class _PatientPlanDetailsPageState extends State<PatientPlanDetailsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;
  List<Map<String, dynamic>> enrolledUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Initialize background animation
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    _backgroundAnimationController.repeat(reverse: true);

    _loadEnrolledUsers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        const Color(0xffA882DD).withOpacity(0.5),
                        const Color(0xff6d6492).withOpacity(0.5),
                        _backgroundAnimation.value,
                      )!,
                      Color.lerp(
                        const Color(0xff6d6492).withOpacity(0.05),
                        const Color(0xffA882DD).withOpacity(0.4),
                        _backgroundAnimation.value,
                      )!,
                    ],
                  ),
                ),
              );
            },
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              title: Text(
                "Patient Plan Details",
                style: TextStyle(
                  color: TColor.primaryColor1,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: TColor.primaryColor1,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.info_outline, color: TColor.primaryColor1),
                  onPressed: () {
                    _showPlanInfoDialog();
                  },
                ),
              ],
            ),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xffA882DD).withOpacity(0.2),
                                  const Color(0xff6d6492).withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              Icons.healing,
                              color: TColor.primaryColor1,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.program.programName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: TColor.black,
                                  ),
                                ),
                                Text(
                                  "${enrolledUsers.length} patients enrolled",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: TColor.gray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: TColor.primaryColor1,
                          ),
                        )
                      : enrolledUsers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: TColor.gray.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    "No Patients Enrolled",
                                    style: TextStyle(
                                      color: TColor.gray,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: enrolledUsers.length,
                              itemBuilder: (context, index) {
                                final user = enrolledUsers[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          TColor.primaryColor1.withOpacity(0.1),
                                      child: Text(
                                        user['name'][0],
                                        style: TextStyle(
                                          color: TColor.primaryColor1,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user['name'],
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: TColor.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Progress: ${user['progress']}%",
                                      style: TextStyle(
                                        color: TColor.gray,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      color: TColor.primaryColor1,
                                      size: 16,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ManagePatientPlanPage(
                                            program: widget.program,
                                            userId: user['userId'],
                                            patientName: user['name'],
                                            plan: user['plan'],
                                            progress: user['progress'],
                                            lastVisit: user['lastVisit'],
                                          ),
                                        ),
                                      ).then((_) => _loadEnrolledUsers());
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlanInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xffA882DD).withOpacity(0.2),
                        const Color(0xff6d6492).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: TColor.primaryColor1,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.program.programName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TColor.black,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.program.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: TColor.gray,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoItem("Duration", widget.program.duration),
                    _infoItem("Patients", "${enrolledUsers.length}"),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.primaryColor1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "Close",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddPatientDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final conditionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Add New Patient",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: TColor.black,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(nameController, "Patient Name", Icons.person),
                const SizedBox(height: 12),
                _buildTextField(ageController, "Age", Icons.calendar_today,
                    isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(
                    conditionController, "Condition", Icons.healing),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: TColor.gray,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty &&
                            ageController.text.isNotEmpty &&
                            conditionController.text.isNotEmpty) {
                          setState(() {
                            enrolledUsers.add({
                              "name": nameController.text,
                              "age": int.tryParse(ageController.text) ?? 0,
                              "condition": conditionController.text,
                              "progress": 0.0,
                              "lastVisit":
                                  DateTime.now().toString().split(' ')[0],
                            });
                          });
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColor.primaryColor1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        "Add Patient",
                        style: TextStyle(
                          color: TColor.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: TColor.gray,
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
            child: Icon(icon, color: TColor.primaryColor1, size: 22),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _loadEnrolledUsers() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('enrolledPrograms.${widget.program.programId}', isNull: false)
          .get();

      setState(() {
        enrolledUsers = usersSnapshot.docs.map((doc) {
          final data = doc.data();
          final enrolledPrograms =
              data['enrolledPrograms'] as Map<String, dynamic>?;
          final programData = enrolledPrograms?[widget.program.programId]
              as Map<String, dynamic>?;

          return {
            'userId': doc.id,
            'name': data['fullName'] ?? 'Unknown',
            'email': data['email'] ?? '',
            'plan': programData?['plan'] ?? {},
            'progress': programData?['progress'] ?? 0.0,
            'lastVisit': programData?['lastVisit'] ??
                DateTime.now().toString().split(' ')[0],
          };
        }).toList();
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error loading enrolled users: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
}
