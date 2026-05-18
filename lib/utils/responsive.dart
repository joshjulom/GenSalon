import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext c) => MediaQuery.of(c).size.width < 600;
  static bool isTablet(BuildContext c) {
    final w = MediaQuery.of(c).size.width;
    return w >= 600 && w < 1024;
  }
  static bool isDesktop(BuildContext c) =>
      MediaQuery.of(c).size.width >= 1024;

  static int gridCols(BuildContext c) {
    if (isDesktop(c)) return 4;
    if (isTablet(c)) return 3;
    return 2;
  }
}

class MaxWidth extends StatelessWidget {
  final Widget child;
  final double max;
  const MaxWidth({super.key, required this.child, this.max = 1100});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}
