import 'dart:io';
import '../../screens/yoe.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePictureScreen extends StatefulWidget {
  final String name;
  final String city;
  final String email;
  const ProfilePictureScreen({
    super.key,
    required this.name,
    required this.city,
    required this.email,
  });

  @override
  _ProfilePictureScreenState createState() => _ProfilePictureScreenState();
}

class _ProfilePictureScreenState extends State<ProfilePictureScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to pick image: $error"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 65.0, left: 45.0, right: 45.0, bottom: 45.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.green, // Green background
                shape: BoxShape.circle, // Make the background circular
              ),
              padding: const EdgeInsets.all(12.0), // Padding around the icon
              child: const Center( // Center widget to center the icon
                child: Icon(
                  Icons.person_outline_rounded, // Person icon
                  color: Colors.white, // Icon color
                  size: 30.0, // Icon size
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Upload your profile picture",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600, // Slightly lighter weight
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFEEEEEE), // Light grey color from image
                      radius: 60, // Make it larger
                      child: _profileImage == null
                          ? const Icon(Icons.person_outline,
                          size: 50, color: Colors.grey)
                          : ClipOval(
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                          width: 120.0,
                          height: 120.0,
                        ),
                      ),
                    ),
                  ),
                  if (_profileImage == null)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50), // Match the green from top icon
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera, // Changed to camera icon
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  if (_profileImage != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _profileImage = null;
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 35),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ExperienceScreen(
                    name: widget.name,
                    city: widget.city,
                    email: widget.email,
                    profileImage: _profileImage,
                  ),
                ));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50), // Match the green color
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => ExperienceScreen(
                    name: widget.name,
                    city: widget.city,
                    email: widget.email,
                    profileImage: _profileImage,
                  ),
                ));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4CAF50), // Green border
                    width: 1,
                  ),
                ),
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Color(0xFF4CAF50), // Green text
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
