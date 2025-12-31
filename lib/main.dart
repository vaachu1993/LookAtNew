import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/email_sign_in_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/explore/explore_screen.dart';
import 'screens/bookmark/bookmark_screen.dart';
import 'screens/notifications/notifications_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: MaterialApp(
        title: 'LookAt',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE20035),
            primary: const Color(0xFFE20035),
          ),
          fontFamily: 'SF Pro Text',
          useMaterial3: true,
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const EmailSignInScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/explore': (context) => const ExploreScreen(),
          '/bookmark': (context) => const BookmarkScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verify-email') {
            final email = settings.arguments as String?;
            if (email != null) {
              return MaterialPageRoute(
                builder: (context) => VerifyEmailScreen(email: email),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}
