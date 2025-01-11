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
      final response = await http.get(
        Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/profile/'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profilePicUrl = data['profile_pic'] ?? ''; // Ensure profile_pic exists
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
      height: 70, // Increase the height to accommodate the text
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.home_filled, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(height: 2), // Reduce the space between icon and text
              const Text('Home', style: TextStyle(color: Colors.white)),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(height: 2), // Reduce the space between icon and text
              const Text('Search', style: TextStyle(color: Colors.white)),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                padding: EdgeInsets.zero, // Remove default padding
                icon: const Icon(Icons.forward_to_inbox, color: Colors.white),
                onPressed: () {},
              ),
              const SizedBox(height: 2), // Reduce the space between icon and text
              const Text('Inbox', style: TextStyle(color: Colors.white)),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed('/profile');
            },
            child: CircleAvatar(
              radius: 18,
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
          ),
        ],
      ),
    );
  }
}
