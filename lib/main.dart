import 'package:farmers_admin/repositories/user_repository.dart';
import 'package:farmers_admin/services/admin_dashboard_api_service.dart';
import 'package:farmers_admin/services/admin_post_service.dart';
import 'package:farmers_admin/services/admin_report_posts_api_service.dart';
import 'package:farmers_admin/services/admin_working_status_api_service.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/services/admin_crash_reports_api_service.dart';
import 'package:farmers_admin/services/deleted_users_api_service.dart';
import 'package:farmers_admin/services/admin_chat_service.dart';
import 'package:farmers_admin/services/farming_tip_api_service.dart';
import 'package:farmers_admin/services/slider_api_service.dart';
import 'package:farmers_admin/viewmodels/dashboard_viewmodel.dart';
import 'package:farmers_admin/viewmodels/user_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'constants/app_colors.dart';
import 'constants/constants.dart';
import 'auth/auth_screen.dart';
import 'firebase_options.dart';

// Custom page transitions builder with no animation
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Prevent duplicate initialization
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AdminServerAuthService>(
          create: (_) => AdminServerAuthService(),
        ),
        ProxyProvider<AdminServerAuthService, AdminPostService>(
          update: (_, auth, __) => AdminPostService(auth),
        ),
        ProxyProvider<AdminServerAuthService, SliderApiService>(
          update: (_, auth, __) => SliderApiService(auth),
        ),
        ProxyProvider<AdminServerAuthService, FarmingTipApiService>(
          update: (_, auth, __) => FarmingTipApiService(auth),
        ),
        ProxyProvider<AdminServerAuthService, UserRepository>(
          update: (_, auth, __) => UserRepository(auth),
        ),
        ProxyProvider<AdminServerAuthService, AdminDashboardApiService>(
          update: (_, auth, __) => AdminDashboardApiService(auth),
        ),
        ProxyProvider<AdminServerAuthService, AdminReportPostsApiService>(
          update: (_, auth, __) => AdminReportPostsApiService(auth),
        ),
        ProxyProvider<AdminServerAuthService, AdminWorkingStatusApiService>(
          update: (_, auth, __) => AdminWorkingStatusApiService(auth),
        ),
        ProxyProvider<AdminServerAuthService, DeletedUsersApiService>(
          update: (_, auth, __) => DeletedUsersApiService(auth),
        ),
        ProxyProvider<AdminServerAuthService, AdminCrashReportsApiService>(
          update: (_, auth, __) => AdminCrashReportsApiService(auth),
        ),
        ProxyProvider<AdminServerAuthService, AdminChatService>(
          update: (_, auth, __) => AdminChatService(auth),
        ),
        ChangeNotifierProxyProvider<UserRepository, UserScreenViewModel>(
          create: (context) => UserScreenViewModel(repository: context.read<UserRepository>()),
          update: (context, repo, previous) => previous ?? UserScreenViewModel(repository: repo),
        ),
        ChangeNotifierProxyProvider<AdminDashboardApiService, DashboardViewModel>(
          create: (context) => DashboardViewModel(context.read<AdminDashboardApiService>()),
          update: (context, apiService, previous) => previous ?? DashboardViewModel(apiService),
        ),

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
    textTheme: ThemeData(brightness: Brightness.light).textTheme,
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
      theme: _lightTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
            TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          },
        ),
      ),
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
