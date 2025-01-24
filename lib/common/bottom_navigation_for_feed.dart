import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/profile/'),
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
          profilePicUrl = user['profile_picture'] ?? ''; // Set profile picture URL
        });
      } else {
        debugPrint('Failed to load profile picture: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching profile picture: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      height: 65, // Adjust the height to match LinkedIn's style
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.home_filled, color: Colors.white, size: 26), // Adjust size to LinkedIn's icon size
                onPressed: () {},
              ),
              Transform.translate(
                offset: const Offset(0, -5), // Move the text 5 pixels upward
                child: const Text(
                  'Home',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.search, color: Colors.white, size: 26), // Adjust size
                onPressed: () {},
              ),
              Transform.translate(
                offset: const Offset(0, -5), // Move the text 5 pixels upward
                child: const Text(
                  'Search',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.forward_to_inbox, color: Colors.white, size: 26), // Adjust size
                onPressed: () {},
              ),

              Transform.translate(
                offset: const Offset(0, -5), // Move the text 5 pixels upward
                child: const Text(
                  'Inbox',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/login');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 16, // Adjust size for the profile picture
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person, // Displays the person icon
                    color: Colors.grey, // Icon color
                    size: 24, // Adjust size of the icon if needed
                  ),
                ),

                const SizedBox(height: 4), // Space between profile icon and text
                Transform.translate(
                  offset: const Offset(0, -0), // Move the text 5 pixels upward
                  child: const Text(
                    'Profile',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}