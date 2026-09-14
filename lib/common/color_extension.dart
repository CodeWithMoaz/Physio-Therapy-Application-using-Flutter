import 'package:flutter/material.dart';

class TColor {
  static Color get primaryColor1 => const Color(0xff6d6492);
  static Color get primaryColor2 => const Color(0xffA882DD);

  static Color get secondaryColor1 => const Color(0xffC58BF2);
  static Color get secondaryColor2 => const Color(0xffEEA4CE);

  static List<Color> get primaryG => [primaryColor2, primaryColor1];
  static List<Color> get secondaryG => [secondaryColor2, secondaryColor1];

  static Color get black => const Color(0xff1D1617);
  static Color get red => const Color.fromARGB(255, 227, 0, 34);
  static Color get gray => const Color(0xff786F72);
  static Color get white => const Color.fromARGB(255, 255, 248, 245);
  static Color get lightGray => const Color(0xffF7F8F8);
  static Color get lighthighGray => const Color.fromARGB(255, 222, 222, 222);
  static Color get realWhite => const Color.fromARGB(255, 255, 255, 255);
  static Color get ivory => const Color.fromARGB(255, 255, 235, 231);
}
