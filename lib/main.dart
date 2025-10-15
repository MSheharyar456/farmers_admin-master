import 'package:farmers_admin/repositories/user_repository.dart';
import 'package:farmers_admin/viewmodels/dashboard_viewmodel.dart';
import 'package:farmers_admin/viewmodels/post_viewmodel.dart';
import 'package:farmers_admin/viewmodels/user_viewmodel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'constants/app_colors.dart';
import 'constants/constants.dart';
import 'screens/dashboard/dashboard.dart';
import 'auth/auth_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent duplicate initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [

        ChangeNotifierProvider(create: (_) => UserScreenViewModel(repository: UserRepository(),)),
        ChangeNotifierProvider(create: (_) => PostViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),

        // You can add more providers here if needed later
      ],
      child: const MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    textTheme: GoogleFonts.poppinsTextTheme(
      ThemeData(brightness: Brightness.light).textTheme,
    ),
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    extensions: <ThemeExtension<dynamic>>[
      AppColors(
        sidebarBackground: sideBarBackground,
        brandColor: Colors.white,
        activeMenuBackground: buttonBackground,
        inactiveMenuText: Colors.white,
        settingsHeaderText: Colors.grey[700],
        cardBackgroundColor: cardBackgroundColor,
        cardBackgroundColor2: cardBackgroundColor2,
        formFieldBorderColor: formFieldBorderColor,
        applyFilterButtonColor: buttonBackground,
      ),
    ],
  );

  // Dark Theme (Original Style)
  // static final _darkTheme = ThemeData(
  //   brightness: Brightness.dark,
  //   fontFamily: 'Inter',
  //   scaffoldBackgroundColor: const Color(0xFF1E2828),
  //   extensions: <ThemeExtension<dynamic>>[
  //     AppColors(
  //       sidebarBackground: const Color(0xFF2D3A3A),
  //       brandColor: Colors.white,
  //       activeMenuBackground: const Color(0xFF1ABC9C),
  //       inactiveMenuText: Colors.grey[400],
  //       settingsHeaderText: Colors.grey,
  //       cardBackgroundColor: cardBackgroundColor,
  //       cardBackgroundColor2: cardBackgroundColor2,
  //     ),
  //   ],
  // );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Farmer's Hub Admin",
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,      // Set the light theme as the default
      // darkTheme: _darkTheme,   // Set the dark theme
      // themeMode: ThemeMode.system, // Automatically switch based on system settings
      // home: DashboardScreen(),
      home: const AuthWrapper(),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Always show AuthScreen (no StreamBuilder, no auto redirect)
    return const AuthScreen();
  }
}