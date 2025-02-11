
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import 'JobSearchApp.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({Key? key}) : super(key: key);

  @override
  State<SplashScreen1> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen1> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();

    // Navigate to main screen after 9 seconds
    Future.delayed(const Duration(seconds: 10), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const JobSearchScreen()),
      );
    });
  }


  Future<void> _checkAuthStatus() async {
    bool shouldStayLoggedIn = false;

    // First check if we have an access token
    final hasAccessToken = await AuthService.isLoggedIn();

    if (hasAccessToken) {
      // We have an access token, try to use it
      shouldStayLoggedIn = true;
    }

    if (mounted) {
      Timer(const Duration(seconds: 4), () async {
        final prefs = await SharedPreferences.getInstance();

        final bool userExists = prefs.getBool("userExists") ?? false;
        debugPrint('User exists: $userExists');
        //Routing
        if (!userExists) {
          if (mounted) Navigator.of(context).pushReplacementNamed('/job');
        } else {
          if (shouldStayLoggedIn) {
            if (mounted) Navigator.of(context).pushReplacementNamed('/feed');
          } else {
            // Clear any old tokens if refresh failed
            AuthService.logout();
            if (mounted) Navigator.of(context).pushReplacementNamed('/login');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Centered GIF
          Center(
            child: Image.asset(
              'assets/splash.gif',
              width: 400, // Adjust size as needed
              height: 400,
              fit: BoxFit.contain,
            ),
          ),
          // Bell icon at the top-left corner
          Positioned(
            top: 30, // Adjust the distance from the top
            left: 20, // Adjust the distance from the left
            child: SvgPicture.asset(
              'assets/bell_image.svg', // Path to your SVG file
              width: 30, // Adjust size as needed
              height: 30,
            ),
          ),
        ],
      ),
    );
  }
}

