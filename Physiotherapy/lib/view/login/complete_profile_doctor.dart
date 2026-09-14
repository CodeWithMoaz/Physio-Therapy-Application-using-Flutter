import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/common_widget/round_button.dart';
import 'package:physiotherapy/common_widget/round_textfield.dart';
import 'package:physiotherapy/view/login/sign_up_view.dart';
import 'package:physiotherapy/models/doctor_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class DoctorCompleteProfileView extends StatefulWidget {
  const DoctorCompleteProfileView({super.key});

  @override
  State<DoctorCompleteProfileView> createState() =>
      _DoctorCompleteProfileViewState();
}

class _DoctorCompleteProfileViewState extends State<DoctorCompleteProfileView>
    with TickerProviderStateMixin {
  TextEditingController txtClinicAddress = TextEditingController();
  TextEditingController txtSpecialization = TextEditingController();
  TextEditingController txtExperience = TextEditingController();
  TextEditingController txtCertificate = TextEditingController();
  String selectedGender = 'Not Specified';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  XFile? _pickedImage;
  bool _isLoading = false;

  late AnimationController _mainAnimationController;
  late AnimationController _backgroundAnimationController;
  late AnimationController _buttonAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundAnimationController);

    _buttonScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    _mainAnimationController.forward();
    _backgroundAnimationController.repeat(reverse: true);
    _buttonAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _buttonAnimationController.dispose();
    txtClinicAddress.dispose();
    txtSpecialization.dispose();
    txtExperience.dispose();
    txtCertificate.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _pickedImage = image;
        txtCertificate.text = image.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (txtClinicAddress.text.isEmpty ||
        txtSpecialization.text.isEmpty ||
        txtExperience.text.isEmpty ||
        txtCertificate.text.isEmpty ||
        selectedGender == 'Not Specified') {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doctorDoc =
          await _firestore.collection('doctors').doc(user.uid).get();
      if (!doctorDoc.exists) {
        throw Exception('Doctor document not found');
      }

      final existingDoctor = DoctorModel.fromFirestore(doctorDoc);

      final updatedDoctor = existingDoctor.copyWith(
        specialization: txtSpecialization.text,
        yearsOfExperience: int.parse(txtExperience.text),
        certificate: txtCertificate.text,
        programsManaged: [],
        gender: selectedGender,
      );

      await _firestore
          .collection('doctors')
          .doc(user.uid)
          .update(updatedDoctor.toFirestore());

      if (!mounted) return;
      _showValidationDialog(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error saving profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _showValidationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: Row(
            children: [
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
                child: Icon(
                  Icons.access_time,
                  color: TColor.primaryColor1,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Waiting for Validation",
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Text(
            "Your account is under review. You will be notified once it is validated.",
            style: TextStyle(color: TColor.gray, fontSize: 14),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xffA882DD),
                    const Color(0xff6d6492),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: SizedBox(
                  width: 100,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpView()),
                      );
                    },
                    child: Text(
                      "OK",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SignUpView()),
        );
        return false;
      },
      child: Scaffold(
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
                          const Color(0xffA882DD).withOpacity(0.1),
                          const Color(0xff6d6492).withOpacity(0.1),
                          _backgroundAnimation.value,
                        )!,
                        Color.lerp(
                          const Color(0xff6d6492).withOpacity(0.05),
                          const Color(0xffA882DD).withOpacity(0.15),
                          _backgroundAnimation.value,
                        )!,
                      ],
                    ),
                  ),
                );
              },
            ),
            ...List.generate(6, (index) {
              return AnimatedBuilder(
                animation: _backgroundAnimationController,
                builder: (context, child) {
                  return Positioned(
                    top: 100 +
                        (index * 120) +
                        (30 *
                            math.sin(_backgroundAnimation.value * 2 * math.pi +
                                index)),
                    left: (index.isEven ? -50 : media.width - 50) +
                        (20 *
                            math.cos(_backgroundAnimation.value * 2 * math.pi +
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
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            SlideTransition(
                              position: _slideAnimation,
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xffA882DD)
                                              .withOpacity(0.2),
                                          const Color(0xff6d6492)
                                              .withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xffA882DD)
                                              .withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.arrow_back_ios,
                                          color: TColor.primaryColor1),
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const SignUpView()),
                                        );
                                      },
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      "Doctor Profile",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: TColor.primaryColor1,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 102,
                                      height: 102,
                                      margin: const EdgeInsets.only(bottom: 15),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xffA882DD),
                                            const Color(0xff6d6492),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(60),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xffA882DD)
                                                .withOpacity(0.3),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.medical_services_outlined,
                                        size: 51,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "Complete Your Profile",
                                      style: TextStyle(
                                        color: TColor.primaryColor1,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color: TColor.primaryColor1
                                                .withOpacity(0.2),
                                            offset: const Offset(1, 1),
                                            blurRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Provide necessary details to verify your account",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: TColor.gray,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(21),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xffA882DD)
                                          .withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 10),
                                    _buildEnhancedTextField(
                                      controller: txtClinicAddress,
                                      hintText: "Clinic Address",
                                      icon: Icons.location_on_outlined,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildEnhancedTextField(
                                      controller: txtSpecialization,
                                      hintText: "Specialization",
                                      icon: Icons.medical_information_outlined,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildEnhancedTextField(
                                      controller: txtExperience,
                                      hintText: "Years of Experience",
                                      icon: Icons.work_outline,
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildGenderSelector(),
                                    const SizedBox(height: 20),
                                    _buildEnhancedCertificateUpload(),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            AnimatedBuilder(
                              animation: _buttonScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _buttonScaleAnimation.value,
                                  child: _buildEnhancedSubmitButton(),
                                );
                              },
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
      ),
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          color: TColor.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: TColor.gray.withOpacity(0.7),
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
            child: Icon(
              icon,
              color: TColor.primaryColor1,
              size: 19,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: maxLines > 1 ? 15 : 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCertificateUpload() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
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
              child: Icon(
                Icons.description_outlined,
                color: TColor.primaryColor1,
                size: 19,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                txtCertificate.text.isEmpty
                    ? "Upload Certificate"
                    : txtCertificate.text,
                style: TextStyle(
                  color: txtCertificate.text.isEmpty
                      ? TColor.gray.withOpacity(0.7)
                      : TColor.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 15),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xffA882DD),
                    const Color(0xff6d6492),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffA882DD).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Insert",
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
      ),
    );
  }

  Widget _buildEnhancedSubmitButton() {
    return Container(
      width: double.infinity,
      height: 47,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffA882DD),
            const Color(0xff6d6492),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    "Submitting...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : Text(
                "Submit for Verification",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xffA882DD).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xffA882DD).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffA882DD).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
                  child: Icon(
                    Icons.person_outline,
                    color: TColor.primaryColor1,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  "Gender",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption('Male', Icons.male),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGenderOption('Female', Icons.female),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String gender, IconData icon) {
    final isSelected = selectedGender == gender;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = gender;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xffA882DD),
                    const Color(0xff6d6492),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : const Color(0xffA882DD).withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : TColor.primaryColor1,
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              gender,
              style: TextStyle(
                color: isSelected ? Colors.white : TColor.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
