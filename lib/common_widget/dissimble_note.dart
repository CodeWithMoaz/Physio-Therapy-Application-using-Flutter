import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';
import 'package:physiotherapy/common_widget/round_button.dart';

class DismissibleNote extends StatefulWidget {
  const DismissibleNote({super.key});

  @override
  _DismissibleNoteState createState() => _DismissibleNoteState();
}

class _DismissibleNoteState extends State<DismissibleNote>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    _sizeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutExpo,
      ),
    );

    // Add a short delay before showing
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  void _closeContainer() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: -1.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          decoration: BoxDecoration(
            color: TColor.primaryColor2.withOpacity(0.3),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Important Note:",
                    style: TextStyle(
                      color: TColor.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeContainer,
                    child: Icon(Icons.close, color: TColor.black),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                "If you experience a serious injury, we recommend you to connect with a physiotherapist for an accurate diagnosis, proper treatment, and effective recovery to prevent complications.",
                textAlign: TextAlign.justify,
                style: TextStyle(color: TColor.gray, fontSize: 12),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: RoundButton(
                  title: "Connect with Physiotherapist",
                  type: RoundButtonType.bgGradient,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
