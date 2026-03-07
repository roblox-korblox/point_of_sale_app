import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1200;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 3;
    }
    return 2;
  }

  static int getGridCrossAxisCountForProducts(BuildContext context) {
    if (isDesktop(context)) {
      return 4;
    } else if (isTablet(context)) {
      return 3;
    }
    return 2;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(24.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20.0);
    }
    return const EdgeInsets.all(16.0);
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet ?? mobile * 1.2,
      desktop: desktop ?? mobile * 1.5,
    );
  }
}

