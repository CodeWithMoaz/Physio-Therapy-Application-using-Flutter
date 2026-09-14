import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';

enum RoundButtonType { bgGradient, bgSGradient, textGradient }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final VoidCallback? onPressed;
  final double fontSize;
  final double elevation;
  final FontWeight fontWeight;
  final bool disabled;

  const RoundButton({
    super.key,
    required this.title,
    this.type = RoundButtonType.bgGradient,
    this.fontSize = 16,
    this.elevation = 1,
    this.fontWeight = FontWeight.w700,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = disabled || onPressed == null;

    return Container(
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : LinearGradient(
                colors: type == RoundButtonType.bgSGradient
                    ? TColor.secondaryG
                    : TColor.primaryG,
              ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: (type == RoundButtonType.bgGradient ||
                    type == RoundButtonType.bgSGradient) &&
                !isDisabled
            ? const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 0.5,
                  offset: Offset(0, 0.5),
                ),
              ]
            : null,
        color: isDisabled
            ? Colors.grey.shade300
            : (type == RoundButtonType.bgGradient ||
                    type == RoundButtonType.bgSGradient
                ? null
                : TColor.white),
      ),
      child: MaterialButton(
        onPressed: isDisabled ? null : onPressed,
        height: 50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        textColor: TColor.primaryColor1,
        minWidth: double.maxFinite,
        elevation: type == RoundButtonType.bgGradient ||
                type == RoundButtonType.bgSGradient
            ? 0
            : elevation,
        color: type == RoundButtonType.bgGradient ||
                type == RoundButtonType.bgSGradient
            ? Colors.transparent
            : TColor.white,
        disabledColor: Colors.transparent,
        child: (type == RoundButtonType.bgGradient ||
                    type == RoundButtonType.bgSGradient) ||
                isDisabled
            ? Text(
                title,
                style: TextStyle(
                  color: isDisabled ? Colors.grey : TColor.white,
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                ),
              )
            : ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: TColor.primaryG,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(
                    Rect.fromLTRB(0, 0, bounds.width, bounds.height),
                  );
                },
                child: Text(
                  title,
                  style: TextStyle(
                    color: TColor.primaryColor1,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
              ),
      ),
    );
  }
}
