import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/view/rehabilitation/edit_plan.dart';
import 'package:physiotherapy/view/rehabilitation/editpatientplan.dart';
import 'package:physiotherapy/models/program_model.dart';
import 'package:physiotherapy/models/doctor_model.dart';

class ManageRehabPlansView extends StatefulWidget {
  const ManageRehabPlansView({super.key});

  @override
  State<ManageRehabPlansView> createState() => _ManageRehabPlansViewState();
}

class _ManageRehabPlansViewState extends State<ManageRehabPlansView>
    with TickerProviderStateMixin {
  String? selectedInjury;
  String? selectedSeverity;
  String? selectedAgeGroup;
  String searchQuery = "";
  bool filterApplied = false;
  bool isAddButtonPressed = false;
  bool showFilterOptions = false;
  bool isLoading = true;
  List<ProgramModel> programs = [];
  List<String> _doctorProgramsManagedIds = [];

  // Animation controllers
  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _filterController;
  late AnimationController _dropdownController;
  late AnimationController _cardAnimationController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _filterAnimation;
  late Animation<double> _dropdownAnimation;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDoctorPrograms();
  }

  void _initializeAnimations() {
    // Main animation controller for page entrance
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Background animation controller
    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Filter animation controller
    _filterController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Dropdown animation controller
    _dropdownController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Card animation controller
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation for overall opacity
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Slide animation for form elements
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    // Scale animation for interactive elements
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    // Background gradient animation
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    // Filter animation
    _filterAnimation = CurvedAnimation(
      parent: _filterController,
      curve: Curves.elasticOut,
    );

    // Dropdown animation
    _dropdownAnimation = CurvedAnimation(
      parent: _dropdownController,
      curve: Curves.easeInOut,
    );

    // Card animation
    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    );

    // Start animations
    _mainAnimationController.forward();
    _backgroundAnimationController.repeat(reverse: true);
    _dropdownController.forward();
    _cardAnimationController.forward();
  }

  Future<void> _loadDoctorPrograms() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        setState(() => isLoading = false);
        return;
      }

      print('👤 Loading programs for doctor: ${user.uid}');

      // Get doctor document
      final doctorDoc = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(user.uid)
          .get();

      if (!doctorDoc.exists) {
        print('❌ Doctor document does not exist');
        setState(() => isLoading = false);
        return;
      }

      // Print raw doctor data for debugging
      print('📋 Raw doctor data: ${doctorDoc.data()}');

      final doctor = DoctorModel.fromFirestore(doctorDoc);
      print('📋 Doctor data loaded: ${doctor.fullName}');
      print('📋 Programs managed: ${doctor.programsManaged}');

      // Store the programsManaged list and update state
      setState(() {
        _doctorProgramsManagedIds = List<String>.from(doctor.programsManaged);
        isLoading = false;
      });

      print('✅ Programs managed IDs loaded successfully');
    } catch (e) {
      print('❌ Error loading doctor programs: $e'); // Updated log message
      print('❌ Stack trace: ${e.toString()}');
      setState(() {
        isLoading = false;
      });
    }
  }

  void applyFilter() {
    // This method is less critical now as filtering is done in the stream
    // We might keep it to trigger a UI update if filter options change, which will rebuild the StreamBuilder
    setState(() {
      filterApplied = true;
    });
  }

  void resetFilter() {
    setState(() {
      selectedInjury = null; // Reset to null to indicate no filter
      selectedSeverity = null; // Reset to null to indicate no filter
      selectedAgeGroup = null; // Assuming you add age group filtering later
      searchQuery = "";
      filterApplied = false;
      showFilterOptions = false;
      _filterController.reverse();
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _filterController.dispose();
    _dropdownController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
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
                "Manage Rehabilitation Plans",
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
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Filter Plans",
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildFilterDropdown(
                                  value: selectedInjury,
                                  items: ["All", ...ProgramModel.injuryTypes],
                                  hint: "Select Injury",
                                  onChanged: (value) {
                                    setState(() {
                                      selectedInjury = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildFilterDropdown(
                                  value: selectedSeverity,
                                  items: [
                                    "All",
                                    ...ProgramModel.severityLevels
                                  ],
                                  hint: "Select Severity",
                                  onChanged: (value) {
                                    setState(() {
                                      selectedSeverity = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rehabilitation Plans",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const EditPlanPage(program: null),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: TColor.primaryColor1,
                          ),
                          label: Text(
                            "Create",
                            style: TextStyle(
                              color: TColor.primaryColor1,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    StreamBuilder<QuerySnapshot>(
                      stream: _getFilteredProgramsStream(),
                      builder: (context, snapshot) {
                        // Print managed IDs to check its state
                        print(
                            '🔄 _doctorProgramsManagedIds: $_doctorProgramsManagedIds');

                        if (isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(color: TColor.red),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          // Print snapshot data info
                          if (snapshot.hasData) {
                            print(
                                'Snapshot has data but is empty. Doc count: ${snapshot.data!.docs.length}');
                          } else {
                            print('Snapshot has no data.');
                          }

                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: TColor.gray,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No rehabilitation plans found',
                                  style: TextStyle(
                                    color: TColor.gray,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // If we reach here, we have data and programsManagedIds is loaded (checked by isLoading)
                        print(
                            'Snapshot has data. Doc count: ${snapshot.data!.docs.length}');

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var doc = snapshot.data!.docs[index];
                            var program = ProgramModel.fromFirestore(doc);
                            return _buildRehabPlanCard(
                              program: program,
                              onEdit: () => _editProgram(doc.id, program),
                              onDelete: () => _showDeleteConfirmationDialog(
                                  program), // Pass the program object
                              onPatientPlan: () => _viewPatientPlan(
                                  doc.id), // Pass program.programId
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: TColor.primaryColor1.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              color: TColor.gray,
              fontSize: 14,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(ProgramModel program) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, anim1, anim2) => ScaleTransition(
        scale: CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Plan?"),
          content: Text(
              "Are you sure you want to delete '${program.programName}'? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: TColor.gray),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('programs')
                      .doc(program.programId)
                      .delete();

                  // Remove program from doctor's programsManaged array
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('doctors')
                        .doc(user.uid)
                        .update({
                      'programsManaged':
                          FieldValue.arrayRemove([program.programId])
                    });
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadDoctorPrograms();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting program: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRehabPlanCard({
    required ProgramModel program,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onPatientPlan,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TColor.primaryColor1.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TColor.primaryColor1,
                  TColor.primaryColor2,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.3),
                  radius: 21,
                  child: Icon(
                    Icons.healing,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.programName,
                        style: TextStyle(
                          color: TColor.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "${program.injury} - ${program.severity}",
                        style: TextStyle(
                          color: TColor.white.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    "\$${program.price.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: TColor.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.healing,
                            label: "Injury",
                            value: program.injury,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.warning,
                            label: "Severity",
                            value: program.severity,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.group,
                            label: "Age Group",
                            value: program.ageGroup,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: "Duration",
                            value: program.duration,
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.people,
                            label: "Max Patients",
                            value: program.maxPatients.toString(),
                          ),
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            icon: Icons.attach_money,
                            label: "Price",
                            value: "\$${program.price.toStringAsFixed(2)}",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: "Edit",
                        color: TColor.primaryColor1,
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete,
                        label: "Delete",
                        color: TColor.red,
                        onPressed: onDelete,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.visibility,
                        label: "View",
                        color: Colors.green,
                        onPressed: onPatientPlan,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: TColor.primaryColor1.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 15, color: TColor.primaryColor1),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: TColor.gray,
                fontSize: 10,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: TColor.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 15, color: Colors.white),
      label: Text(
        label,
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredProgramsStream() {
    // If the doctor manages no programs, return an empty stream immediately.
    if (_doctorProgramsManagedIds.isEmpty) {
      print('ℹ️ Doctor manages no programs, returning empty stream.');
      return Stream.fromIterable([]);
    }

    // If programsManagedIds is not empty, construct and return the Firestore query.
    Query query = FirebaseFirestore.instance.collection('programs');

    // Filter by programs managed by the doctor using whereIn.
    // This is safe now because we've checked that _doctorProgramsManagedIds is not empty.
    query =
        query.where(FieldPath.documentId, whereIn: _doctorProgramsManagedIds);

    // Apply additional filters if selected
    if (selectedInjury != null && selectedInjury != "All") {
      query = query.where('injury', isEqualTo: selectedInjury);
    }

    if (selectedSeverity != null && selectedSeverity != "All") {
      query = query.where('severity', isEqualTo: selectedSeverity);
    }
    // Assuming you add age group and search filtering to the query later
    // if (selectedAgeGroup != null && selectedAgeGroup != "All") {
    //    query = query.where('ageGroup', isEqualTo: selectedAgeGroup);
    // }
    // if (searchQuery.isNotEmpty) {
    //    // Note: Full-text search is complex in Firestore, this would require more advanced techniques
    //    // e.g., using a dedicated search service or different data structure.
    // }
    print('Executing Firestore query for managed programs.');
    return query.snapshots();
  }

  void _editProgram(String programId, ProgramModel program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlanPage(program: program),
      ),
    );
  }

  void _deleteProgram(String programId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Program'),
        content: const Text('Are you sure you want to delete this program?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('programs')
                  .doc(programId)
                  .delete();
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: TColor.red),
            ),
          ),
        ],
      ),
    );
  }

  void _viewPatientPlan(String programId) {
    FirebaseFirestore.instance
        .collection('programs')
        .doc(programId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final program = ProgramModel.fromFirestore(doc);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientPlanDetailsPage(program: program),
          ),
        );
      }
    });
  }
}

class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color1;
  final Color color2;

  BackgroundPainter({
    required this.animation,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = color1
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = color2
      ..style = PaintingStyle.fill;

    final center1 = Offset(
      size.width * 0.2 + (animation.value * 50),
      size.height * 0.2 + (animation.value * 30),
    );
    final center2 = Offset(
      size.width * 0.8 - (animation.value * 40),
      size.height * 0.7 - (animation.value * 20),
    );

    canvas.drawCircle(center1, size.width * 0.3, paint1);
    canvas.drawCircle(center2, size.width * 0.25, paint2);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.color1 != color1 ||
        oldDelegate.color2 != color2;
  }
}
