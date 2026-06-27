import 'package:flutter/material.dart';
import 'package:flutter_cc_evs/theme/custom_themes/appbar_theme.dart';
import 'package:flutter_cc_evs/theme/custom_themes/bottom_sheet_theme.dart';
import 'package:flutter_cc_evs/theme/custom_themes/checkbox_theme.dart';
import 'package:flutter_cc_evs/theme/custom_themes/elevated_button_theme.dart';
import 'package:flutter_cc_evs/theme/custom_themes/outlined_button_theme.dart';
import 'package:flutter_cc_evs/theme/custom_themes/text_field_theme.dart';
import 'package:flutter_cc_evs/theme/custom_themes/text_theme.dart';

class EVSAppTheme {
  EVSAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: EVSAppBarTheme.lightAppBarTheme,
    textTheme: EVSAppTextTheme.lightTextTheme,
    bottomSheetTheme: EVSBottomSheetTheme.lightBottomSheetTheme,
    checkboxTheme: EVSCheckboxTheme.lightCheckboxTheme,
    elevatedButtonTheme: EVSElevatedButtonTheme.lightElevatedButtonTheme,
    outlinedButtonTheme: EVSOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: EVSTextFormFieldTheme.lightInputDecorationTheme,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
      showSelectedLabels: true,
      type: BottomNavigationBarType.fixed
    )
  );


  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: EVSAppBarTheme.darkAppBarTheme,
    textTheme: EVSAppTextTheme.darkTextTheme,
    bottomSheetTheme: EVSBottomSheetTheme.darkBottomSheetTheme,
    checkboxTheme: EVSCheckboxTheme.darkCheckboxTheme,
    elevatedButtonTheme: EVSElevatedButtonTheme.darkElevatedButtonTheme,
    outlinedButtonTheme: EVSOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: EVSTextFormFieldTheme.darkInputDecorationTheme,
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 12,
      ),
      showSelectedLabels: true,
      type: BottomNavigationBarType.fixed
    )
  );
}