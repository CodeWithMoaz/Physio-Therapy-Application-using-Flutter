import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';

class RoundTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String hitText;
  final String icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? rigtIcon;
  final String? Function(String?)? validator;

  const RoundTextField({
    super.key,
    this.controller,
    required this.hitText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.rigtIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TColor.lightGray,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Container(
            alignment: Alignment.center,
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(8),
            child: Image.asset(
              icon,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
              color: TColor.gray,
            ),
          ),
          border: InputBorder.none,
          hintText: hitText,
          hintStyle: TextStyle(color: TColor.gray, fontSize: 12),
          suffixIcon: rigtIcon,
        ),
      ),
    );
  }
}
