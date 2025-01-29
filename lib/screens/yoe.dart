import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ExperienceScreen extends StatefulWidget {
  final String name;
  final String city;
  final String email;
  final File? profileImage;

  const ExperienceScreen({
    super.key,
    required this.name,
    required this.city,
    required this.email,
    this.profileImage,
  });

  @override
  _ExperienceScreenState createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends State<ExperienceScreen> {
  final TextEditingController experienceController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _yoeFocusNode = FocusNode();

  bool _isSubmitLoading = false;
  bool _isSkipLoading = false;

  @override
  void initState() {
    super.initState();
    experienceController.addListener(() {
      setState(() {}); // Rebuild UI when text changes
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_yoeFocusNode);
    });
  }

  @override
  void dispose() {
    experienceController.removeListener(() { setState(() {}); });
    experienceController.dispose();
    _yoeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitDetails({bool isSkipped = false}) async {
    const String apiUrl =
        'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/register/';

    setState(() {
      if (isSkipped) {
        _isSkipLoading = true;
      } else {
        _isSubmitLoading = true;
      }
    });

    try {
      final accessToken = await AuthService.getAuthToken();
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Prepare body with non-null string values
      var body = {
        'name': widget.name,
        'email': widget.email,
        'city': widget.city,
        if (!isSkipped) 'yoe': experienceController.text,
      };

      var headerData = {
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.fields.addAll(body.map((key, value) => MapEntry(key, value)));
      request.headers.addAll(headerData);
      if (widget.profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          widget.profileImage!.path,
        ));
      }

      final postResponse = await request.send();
      final response = await http.Response.fromStream(postResponse);

      print("Response: ${response.body}");
      if (response.statusCode == 200 || response.statusCode == 201 ) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text("Details Submitted Successfully!"),
            duration: Duration(seconds: 1),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pushNamed('/reel');
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit details: ${response.statusCode}"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $error"),
          duration: const Duration(seconds: 1),
        ),
      );
    } finally {
      setState(() {
        _isSubmitLoading = false;
        _isSkipLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 90.0, left: 45.0, right: 45.0, bottom: 45.0),
        child: Form(
          key: _formKey,
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
              const SizedBox(height: 20),
              const Center(
              child:  Text(
                "How many years of experience do you have?",
                textAlign: TextAlign.center, // Center align the text
                style: TextStyle(
                  fontSize: 26, // Reduce font size
                  fontWeight: FontWeight.w500, // Use medium weight instead of bold
                  color: Colors.black,
                ),
              ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                focusNode: _yoeFocusNode,
                controller: experienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "Enter years of experience", // Add placeholder text
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                  contentPadding: const EdgeInsets.all(16), // Increase padding
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  if (!_isSubmitLoading && experienceController.text.isNotEmpty) {
                    _submitDetails(isSkipped: false);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: experienceController.text.isEmpty
                        ? const Color.fromRGBO(212, 202, 191, 1)  // Beige when empty
                        : Colors.green, // Green when has input
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isSubmitLoading
                      ? const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    experienceController.text.isEmpty ? "Continue" : "Submit",  // Change text based on input
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),  // Reduced spacing
              GestureDetector(
                onTap: () {
                  if (!_isSkipLoading) {
                    _submitDetails(isSkipped: true);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF10B981)),  // Green border
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isSkipLoading
                      ? const SizedBox(
                    width: 25,
                    height: 25,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.green,  // Green text
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
