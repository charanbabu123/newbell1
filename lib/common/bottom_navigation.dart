import 'dart:io';

import 'package:bell_app1/common/shared_preferences_util.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/auth_service.dart';

class BottomNavBar extends StatefulWidget {

  final VoidCallback? onProfileUpdated;

  const BottomNavBar({super.key, this.onProfileUpdated});


  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  String profilePicUrl = '';
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfilePicture();
    fetchProfilePic();
  }
  Future<void> _loadProfilePicture() async {
    final savedPath = await SharedPreferencesUtil.getProfilePicturePath();
    if (savedPath != null) {
      setState(() {
        _profileImage = File(savedPath);
      });
    }
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
                  _loadProfilePicture();
                  if (widget.onProfileUpdated != null) {
                    widget.onProfileUpdated!();
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      splashColor: const Color(0xFFDCF8C7),
                      borderRadius: BorderRadius.circular(50),
                      onTap: () {},
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: ClipOval(
                          child: _profileImage != null
                              ? Image.file(
                            _profileImage!,
                            fit: BoxFit.cover,
                            width: 30,
                            height: 30,
                          )
                              : (profilePicUrl.isNotEmpty
                              ? Image.network(
                            profilePicUrl,
                            fit: BoxFit.cover,
                            width: 30,
                            height: 30,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.black,
                              );
                            },
                          )
                              : const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.black,
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Transform.translate(
                      offset: const Offset(0, -5),
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
        ),
    );
  }
}
