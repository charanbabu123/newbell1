import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String apiEndpoint =
      "https://rrrg77yzmd.ap-south-1.awsapprunner.com/api";

  @override
  void initState() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    super.initState();
    _checkAuthStatus();
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse('$apiEndpoint/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data[
            'refresh_token']; // In case the server sends a new refresh token too

        // Save the new tokens
        await AuthService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken ??
              refreshToken, // Use old refresh token if new one isn't provided
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      return false;
    }
  }

//splash -> login ->otp->verify->tour(->basic->upload->)/feed
  Future<void> _checkAuthStatus() async {
    bool shouldStayLoggedIn = false;

    // First check if we have an access token
    final hasAccessToken = await AuthService.isLoggedIn();

    if (hasAccessToken) {
      // We have an access token, try to use it
      shouldStayLoggedIn = true;
    } else {
      // No access token, try to refresh
      shouldStayLoggedIn = await _tryRefreshToken();
    }

    if (mounted) {
      Timer(const Duration(seconds: 4), () async {
        final prefs = await SharedPreferences.getInstance();

        final bool userExists = prefs.getBool("userExists") ?? false;
        debugPrint('User exists: $userExists');
        //Routing
        if (!userExists) {
          if (mounted) Navigator.of(context).pushReplacementNamed('/tour');
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      // Dismiss focus
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.pinkAccent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/demo_logo.png',
                    height: 150.0,
                  ),
                  SlideTransition(
                    position: _slideAnimation,
                    child: const Text(
                      'Be Limitless',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 29.0,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
