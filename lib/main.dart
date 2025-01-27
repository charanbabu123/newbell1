import 'package:bell_app1/screens/static_feedscreen.dart';
import 'package:bell_app1/splash/JobSearchApp.dart';
import 'package:bell_app1/splash/spalsh1.dart';

import '../../profile/user_profile_screen.dart';
import '../../providers/video_section_provider.dart';
import '../../screens/feed_screen.dart';
import '../../login/login_phone_screen.dart';
import '../../splash/splash.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';

import 'screens/reel_uploader_screen.dart';
import 'screens/name.dart';
import 'login/otp_screen.dart';
import 'splash/product_tour_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VideoSectionsProvider()),
      ],
      child: MyApp(
        cameras: cameras,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dynamic UI App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen1(),
        '/tour': (context) => const ProductTourScreen(),
        '/login': (context) => const LoginPhoneScreen(),
        '/otp': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return OtpScreen(phoneNumber: args['phoneNumber']);
        },
        '/details': (context) => const NameScreen(),
        '/reel': (context) => const ReelUploaderScreen(),
        '/feed': (context) => const FeedScreen(),
        '/profile': (context) => const UserProfileScreen(),
      },
    );
  }
}
