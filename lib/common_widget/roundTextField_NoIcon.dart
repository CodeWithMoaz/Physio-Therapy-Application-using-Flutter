import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';

class NoIconTextField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String hintText;
  final Widget? rightIcon;
  final bool obscureText;
  final EdgeInsets? margin;

  const NoIconTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.margin,
    this.keyboardType,
    this.obscureText = false,
    this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: TColor.realWhite,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide(color: TColor.gray.withOpacity(0.5), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: TColor.primaryColor2, width: 2),
          ),
          hintText: hintText,
          suffixIcon: rightIcon,
          hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
        ),
      ),
    );
  }
}
