import 'package:flutter/material.dart';

class UsacMapTheme {
  final Color primaryColor;
  final Color accentColor;
  final Color buildingDefaultColor;
  final Color buildingBorderColor;
  final Color buildingSelectedColor;
  final Color buildingSelectedBorderColor;
  final Color routeStandardColor;
  final Color routeStairsColor;
  final Color routeCoveredColor;
  final double routeWidth;
  final Color userLocationColor;
  final Color boundaryFillColor;
  final Color boundaryBorderColor;
  final String tileUrlTemplate;
  final String userAgentPackageName;

  const UsacMapTheme({
    this.primaryColor = const Color(0xFF002B49),
    this.accentColor = const Color(0xFFD4AF37),
    this.buildingDefaultColor = const Color(0x35002B49),
    this.buildingBorderColor = const Color(0xFF002B49),
    this.buildingSelectedColor = const Color(0x80D4AF37),
    this.buildingSelectedBorderColor = const Color(0xFFB8860B),
    this.routeStandardColor = const Color(0xFF005BAC),
    this.routeStairsColor = const Color(0xFFE65100),
    this.routeCoveredColor = const Color(0xFF2E7D32),
    this.routeWidth = 5.0,
    this.userLocationColor = const Color(0xFF0288D1),
    this.boundaryFillColor = const Color(0x15002B49),
    this.boundaryBorderColor = const Color(0x40002B49),
    this.tileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    this.userAgentPackageName = 'gt.edu.usac.campus_map',
  });

  UsacMapTheme copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? buildingDefaultColor,
    Color? buildingBorderColor,
    Color? buildingSelectedColor,
    Color? buildingSelectedBorderColor,
    Color? routeStandardColor,
    Color? routeStairsColor,
    Color? routeCoveredColor,
    double? routeWidth,
    Color? userLocationColor,
    Color? boundaryFillColor,
    Color? boundaryBorderColor,
    String? tileUrlTemplate,
    String? userAgentPackageName,
  }) {
    return UsacMapTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      buildingDefaultColor: buildingDefaultColor ?? this.buildingDefaultColor,
      buildingBorderColor: buildingBorderColor ?? this.buildingBorderColor,
      buildingSelectedColor:
          buildingSelectedColor ?? this.buildingSelectedColor,
      buildingSelectedBorderColor:
          buildingSelectedBorderColor ?? this.buildingSelectedBorderColor,
      routeStandardColor: routeStandardColor ?? this.routeStandardColor,
      routeStairsColor: routeStairsColor ?? this.routeStairsColor,
      routeCoveredColor: routeCoveredColor ?? this.routeCoveredColor,
      routeWidth: routeWidth ?? this.routeWidth,
      userLocationColor: userLocationColor ?? this.userLocationColor,
      boundaryFillColor: boundaryFillColor ?? this.boundaryFillColor,
      boundaryBorderColor: boundaryBorderColor ?? this.boundaryBorderColor,
      tileUrlTemplate: tileUrlTemplate ?? this.tileUrlTemplate,
      userAgentPackageName: userAgentPackageName ?? this.userAgentPackageName,
    );
  }
}
