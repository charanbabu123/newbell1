import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
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
              Navigator.of(context).pushNamed('/profile');
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16, // Adjust size for profile picture
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: profilePicUrl.isNotEmpty
                        ? Image.network(
                      profilePicUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          color: Colors.grey,
                        );
                      },
                    )
                        : const Icon(
                      Icons.person,
                      color: Colors.grey,
                    ), // Fallback for empty profilePicUrl
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