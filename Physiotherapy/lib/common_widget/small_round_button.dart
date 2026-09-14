import 'package:flutter/material.dart';
import 'package:physiotherapy/common/color_extension.dart';

enum SmallRoundButtonType { bgGradient, bgSGradient, textGradient }

class SmallRoundButton extends StatelessWidget {
  final String title;
  final SmallRoundButtonType type;
  final VoidCallback onPressed;
  final double fontSize;
  final double elevation;
  final FontWeight fontWeight;
  final double width;

  const SmallRoundButton({
    super.key,
    required this.title,
    this.type = SmallRoundButtonType.bgGradient,
    this.fontSize = 16,
    this.elevation = 1,
    this.fontWeight = FontWeight.w700,
    this.width = 200,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: type == SmallRoundButtonType.bgSGradient
              ? TColor.secondaryG
              : TColor.primaryG,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: type == SmallRoundButtonType.bgGradient ||
                type == SmallRoundButtonType.bgSGradient
            ? const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 0.5,
                  offset: Offset(0, 0.5),
                ),
              ]
            : null,
      ),
      child: MaterialButton(
        onPressed: onPressed,
        height: 50,
        minWidth: width,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        textColor: TColor.primaryColor1,
        elevation: type == SmallRoundButtonType.bgGradient ||
                type == SmallRoundButtonType.bgSGradient
            ? 0
            : elevation,
        color: type == SmallRoundButtonType.bgGradient ||
                type == SmallRoundButtonType.bgSGradient
            ? Colors.transparent
            : TColor.white,
        child: type == SmallRoundButtonType.bgGradient ||
                type == SmallRoundButtonType.bgSGradient
            ? Text(
                title,
                style: TextStyle(
                  color: TColor.white,
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
