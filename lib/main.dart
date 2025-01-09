import 'package:bell_app1/Profile/UserProfileScreen.dart';
import 'package:bell_app1/Screens/feedscreen.dart';
import 'package:bell_app1/login/LoginPhoneScreen.dart';
import 'package:bell_app1/splash/Splash.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'Screens/BasicDetailsScreen.dart';

import 'Screens/ReeluploaderScreen.dart';
import 'login/OtpScreen.dart';
import 'Screens/VideoUploadScreen.dart';
import 'splash/ProductTourScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
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
        '/': (context) =>  const SplashScreen(),
        '/tour': (context) => const ProductTourScreen(),
        '/login': (context) => const LoginPhoneScreen(),
        '/otp': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return OtpScreen(phoneNumber: args['phoneNumber']);
        },

        '/details': (context) => const BasicDetailsScreen(),
        '/reel': (context) => const ReelUploaderScreen(),
        '/feed': (context) => const FeedScreen(),
        '/profile': (context) => const UserProfileScreen(),

      },
    );
  }
}
