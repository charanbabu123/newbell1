import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../services/auth_service.dart';

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchProfilePic();
  }


  Future<void> fetchProfilePic() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? savedImagePath = prefs.getString('profile_picture');

      if (savedImagePath != null && savedImagePath.isNotEmpty) {
        setState(() {
          profilePicUrl = savedImagePath;
        });
      } else {
        // If no local image is found, fetch from API
        final accessToken = await AuthService.getAuthToken();
        if (accessToken == null) return;

        final response = await http.get(
          Uri.parse('https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/profile/'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final user = data['user'];
          String fetchedProfilePic = user['profile_picture'] ?? '';

          setState(() {
            profilePicUrl = fetchedProfilePic;
          });

          // Save it locally for future use
          await prefs.setString('profile_picture', fetchedProfilePic);
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile picture: $e');
    }
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
                    splashColor: const Color(0xFFDCF8C7), // Green splash effect
                    borderRadius: BorderRadius.circular(50), // Circular splash
                    onTap: () {
                      // No additional logic here, just the splash effect
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
                    child: const Text(
                      'Home',
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    splashColor: const Color(0xFFDCF8C7), // Green splash effect
                    borderRadius: BorderRadius.circular(50), // Circular splash
                    onTap: () {
                      // No additional logic here, just the splash effect
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
                    child: const Text(
                      'Search',
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    splashColor: const Color(0xFFDCF8C7), // Green splash effect
                    borderRadius: BorderRadius.circular(50), // Circular splash
                    onTap: () {
                      // No additional logic here, just the splash effect
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
                    child: const Text(
                      'Inbox',
                      style: TextStyle(color: Colors.black, fontSize: 12),
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
                    InkWell(
                      splashColor: const Color(0xFFDCF8C7), // Green splash effect
                      borderRadius: BorderRadius.circular(50), // Circular splash
                      onTap: () {
                        // No additional logic here, just the splash effect
                      },
                      child: CircleAvatar(
                        radius: 16, // Adjust size for profile picture
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: profilePicUrl.isNotEmpty
                              ? (profilePicUrl.startsWith('http')
                              ? Image.network(
                            profilePicUrl,
                            fit: BoxFit.cover,
                            width: 30,
                            height: 30,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person_outline_rounded, color: Colors.black);
                            },
                          )
                              : Image.file(
                            File(profilePicUrl),
                            fit: BoxFit.cover,
                            width: 30,
                            height: 30,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person_outline_rounded, color: Colors.black);
                            },
                          ))
                              : const Icon(Icons.person_outline_rounded, color: Colors.black), // Fallback
                        ),
                      ),

                    ),
                    const SizedBox(height: 2), // Space between profile icon and text
                    Transform.translate(
                      offset: const Offset(0, -5), // Move the text 5 pixels upward
                      child: const Text(
                        'Profile',
                        style: TextStyle(color: Colors.black, fontSize: 12),
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
