import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../login/login_phone_screen.dart';
import '../services/auth_service.dart';

class BottomNavBar1 extends StatefulWidget {
  const BottomNavBar1({super.key});

  @override
  _BottomNavBar1State createState() => _BottomNavBar1State();
}

class _BottomNavBar1State extends State<BottomNavBar1> {
  String profilePicUrl = '';

  @override
  void initState() {
    super.initState();
    fetchProfilePic();
  }

  Future<void> fetchProfilePic() async {
    try {
      final accessToken = await AuthService.getAuthToken();
      if (accessToken == null) {
        debugPrint('Access token not found. Please log in.');
        return;
      }

      final response = await http.get(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/profile/'),
        headers: {
          'Authorization': 'Bearer $accessToken', // Include the access token
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        setState(() {
          profilePicUrl =
              user['profile_picture'] ?? ''; // Set profile picture URL
        });
      } else {
        debugPrint('Failed to load profile picture: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching profile picture: $e');
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.white,
        child: SizedBox(
          height: 65, // Adjust the height to match LinkedIn's style
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    //splashColor: const Color(0xFFDCF8C7), // Green splash effect
                    borderRadius: BorderRadius.circular(50), // Circular splash
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.home_outlined,
                        color: Colors.black,
                        size: 26, // Adjust size to LinkedIn's icon size
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -7),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    child: const Text(
                      'Home',
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    //splashColor: const Color(0xFFDCF8C7), // Green splash effect
                    borderRadius: BorderRadius.circular(50), // Circular splash
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPhoneScreen()),
              );
            },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.search,
                        color: Colors.black,
                        size: 26, // Adjust size to LinkedIn's icon size
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -7),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    child: const Text(
                      'Search',
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    //splashColor: const Color(0xFFDCF8C7), // Green splash effect
                    borderRadius: BorderRadius.circular(50), // Circular splash
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPhoneScreen()),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.mail_outline_outlined,
                        color: Colors.black,
                        size: 26, // Adjust size to LinkedIn's icon size
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -7),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    child: const Text(
                      'Inbox',
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                  ),
                ],
              ),
            GestureDetector(
              onTap: _navigateToLogin, // Common navigation function
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    splashColor: const Color(0xFFDCF8C7), // Green splash effect
                    borderRadius: BorderRadius.circular(50), // Circular splash
                    onTap: _navigateToLogin, // Call same function
                    child: const CircleAvatar(
                      radius: 16, // Adjust size for profile picture
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2), // Space between profile icon and text
                  Transform.translate(
                    offset: const Offset(0, -5), // Move the text 5 pixels upward
                    child: InkWell(
                      onTap: _navigateToLogin, // Call same function for text
                      child: const Text(
                        'Profile',
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
          ),
        )
    );
  }
}
