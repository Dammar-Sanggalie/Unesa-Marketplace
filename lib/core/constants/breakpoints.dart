import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobile = 768.0;
  static const double tablet = 1024.0;
  static const double desktop = 1280.0;
  static const double xlarge = 1440.0;

  static const double maxContentWidth = 1280.0;
  static const double maxChatWidth = 1200.0;
  static const double maxFormWidth = 1080.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;

  static bool isDesktopOrTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobile;

  static int getGridColumnCount(double width) {
    if (width >= xlarge) return 5;
    if (width >= desktop) return 4;
    if (width >= tablet) return 3;
    if (width >= mobile) return 3;
    return 2;
  }
}
