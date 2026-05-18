import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PhotoAvatar extends StatelessWidget {
  final String? photoPath;
  final String initials;
  final double radius;

  const PhotoAvatar({
    super.key,
    this.photoPath,
    required this.initials,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && File(photoPath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: FileImage(File(photoPath!)),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.purple.withOpacity(0.2),
      child: Text(
        initials.isEmpty ? '?' : initials[0].toUpperCase(),
        style: TextStyle(
          color: AppColors.purple,
          fontSize: radius * 0.75,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
