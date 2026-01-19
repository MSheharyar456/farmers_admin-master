import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brandColor,
    required this.sidebarBackground,
    required this.activeMenuBackground,
    required this.inactiveMenuText,
    required this.settingsHeaderText,
    required this.cardBackgroundColor,
    required this.cardBackgroundColor2,
    required this.formFieldBorderColor,
    required this.applyFilterButtonColor,
  });

  final Color? brandColor;
  final Color? sidebarBackground;
  final Color? activeMenuBackground;
  final Color? inactiveMenuText;
  final Color? settingsHeaderText;
  final Color? cardBackgroundColor;
  final Color? cardBackgroundColor2;
  final Color? formFieldBorderColor;
  final Color? applyFilterButtonColor;

  @override
  AppColors copyWith({
    Color? brandColor,
    Color? sidebarBackground,
    Color? activeMenuBackground,
    Color? inactiveMenuText,
    Color? settingsHeaderText,
    Color? cardBackgroundColor,
    Color? cardBackgroundColor2,
    Color? formFieldBorderColor,
    Color? applyFilterButtonColor,
  }) {
    return AppColors(
      brandColor: brandColor ?? this.brandColor,
      sidebarBackground: sidebarBackground ?? this.sidebarBackground,
      activeMenuBackground: activeMenuBackground ?? this.activeMenuBackground,
      inactiveMenuText: inactiveMenuText ?? this.inactiveMenuText,
      settingsHeaderText: settingsHeaderText ?? this.settingsHeaderText,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      cardBackgroundColor2: cardBackgroundColor2 ?? this.cardBackgroundColor2,
      formFieldBorderColor: formFieldBorderColor ?? this.formFieldBorderColor,
      applyFilterButtonColor: applyFilterButtonColor ?? this.applyFilterButtonColor,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    return AppColors(
      brandColor: Color.lerp(brandColor, other.brandColor, t),
      sidebarBackground: Color.lerp(sidebarBackground, other.sidebarBackground, t),
      activeMenuBackground: Color.lerp(activeMenuBackground, other.activeMenuBackground, t),
      inactiveMenuText: Color.lerp(inactiveMenuText, other.inactiveMenuText, t),
      settingsHeaderText: Color.lerp(settingsHeaderText, other.settingsHeaderText, t),
      cardBackgroundColor: Color.lerp(cardBackgroundColor, other.cardBackgroundColor, t),
      cardBackgroundColor2: Color.lerp(cardBackgroundColor2, other.cardBackgroundColor2, t),
      formFieldBorderColor: Color.lerp(formFieldBorderColor, other.formFieldBorderColor, t),
      applyFilterButtonColor: Color.lerp(applyFilterButtonColor, other.applyFilterButtonColor, t),
    );
  }
}
