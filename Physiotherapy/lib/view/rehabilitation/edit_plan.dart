import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/models/program_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPlanPage extends StatefulWidget {
  final ProgramModel? program;

  const EditPlanPage({super.key, this.program});

  @override
  State<EditPlanPage> createState() => _EditPlanPageState();
}

class _EditPlanPageState extends State<EditPlanPage>
    with TickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _maxPatientsController;
  String selectedInjury = "Knee";
  String selectedSeverity = "1st Degree";
  String selectedAgeGroup = "18-30";
  String selectedDuration = "4 Weeks";
  double _price = 0.0;

  late AnimationController _backgroundAnimationController;
  late Animation<double> _backgroundAnimation;

  final List<String> ageGroups = [
    "12-17",
    "18-30",
    "31-50",
  ];

  final List<String> durationOptions = [
    "2 Weeks",
    "4 Weeks",
    "6 Weeks",
    "8 Weeks",
    "12 Weeks",
    "16 Weeks",
  ];

  @override
  void initState() {
    super.initState();

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    _backgroundAnimationController.repeat(reverse: true);

    if (widget.program != null) {
      _titleController =
          TextEditingController(text: widget.program!.programName);
      _descriptionController =
          TextEditingController(text: widget.program!.description);
      _maxPatientsController =
          TextEditingController(text: widget.program!.maxPatients.toString());
      selectedInjury = widget.program!.injury;
      selectedSeverity = widget.program!.severity;
      selectedAgeGroup = widget.program!.ageGroup;
      selectedDuration = widget.program!.duration;
      _price = widget.program!.price;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _maxPatientsController = TextEditingController(text: "10");
      _price = 0.0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxPatientsController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  Future<void> savePlan(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final programData = {
        'programName': _titleController.text,
        'description': _descriptionController.text,
        'duration': selectedDuration,
        'maxPatients': int.tryParse(_maxPatientsController.text) ?? 10,
        'injury': selectedInjury,
        'severity': selectedSeverity,
        'ageGroup': selectedAgeGroup,
        'price': _price,
      };

      if (widget.program == null) {
        final docRef = await FirebaseFirestore.instance
            .collection('programs')
            .add(programData);

        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(user.uid)
            .update({
          'programsManaged': FieldValue.arrayUnion([docRef.id])
        });
      } else {
        await FirebaseFirestore.instance
            .collection('programs')
            .doc(widget.program!.programId)
            .update(programData);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving program: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                widget.program == null ? "Create New Plan" : "Edit Plan",
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTextField(
                            controller: _titleController,
                            labelText: "Plan Title",
                            icon: Icons.title,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _descriptionController,
                            labelText: "Description",
                            icon: Icons.description,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),

                          _buildDropdown(
                            label: "Injury Type",
                            value: selectedInjury,
                            items: ProgramModel.injuryTypes,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedInjury = newValue;
                                });
                              }
                            },
                            icon: Icons.healing,
                          ),
                          const SizedBox(height: 16),

                          _buildDropdown(
                            label: "Severity Level",
                            value: selectedSeverity,
                            items: ProgramModel.severityLevels,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedSeverity = newValue;
                                });
                              }
                            },
                            icon: Icons.warning,
                          ),
                          const SizedBox(height: 16),

                          _buildDropdown(
                            label: "Age Group",
                            value: selectedAgeGroup,
                            items: ageGroups,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedAgeGroup = newValue;
                                });
                              }
                            },
                            icon: Icons.group,
                          ),
                          const SizedBox(height: 16),

                          // Duration Dropdown
                          _buildDropdown(
                            label: "Program Duration",
                            value: selectedDuration,
                            items: durationOptions,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedDuration = newValue;
                                });
                              }
                            },
                            icon: Icons.calendar_today,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _maxPatientsController,
                            labelText: "Max Patients",
                            icon: Icons.people,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller:
                                TextEditingController(text: _price.toString()),
                            labelText: "Price (\$)",
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _price = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: () => savePlan(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TColor.primaryColor1,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  widget.program == null
                                      ? "Create Plan"
                                      : "Save Changes",
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
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
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: TColor.gray,
            fontSize: 14,
          ),
          prefixIcon: icon != null
              ? Container(
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
                )
              : null,
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: TColor.gray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                icon: Icon(Icons.arrow_drop_down, color: TColor.primaryColor1),
                items: items.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Container(
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
                            child: Icon(icon,
                                color: TColor.primaryColor1, size: 20),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          value,
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
