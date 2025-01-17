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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_yoeFocusNode);
    });
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.pinkAccent,
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
  void dispose() {
    experienceController.dispose();
    _yoeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F7),
      appBar: AppBar(
        title: const Text("Experience"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(45.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "How many years of experience do you have?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                focusNode: _yoeFocusNode,
                controller: experienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Years of Experience",
                  labelStyle: const TextStyle(color: Colors.pinkAccent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.pinkAccent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.pink, width: 2),
                  ),
                ),
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return "Experience is required";
                //   } else if (int.tryParse(value) == null ||
                //       int.parse(value) > 50) {
                //     return "Enter a valid experience (less than 50)";
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  if (!_isSubmitLoading && _formKey.currentState!.validate()) {
                    _submitDetails(isSkipped: false);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.pink, Colors.pinkAccent],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _isSubmitLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {
                  if (!_isSkipLoading) {
                    _submitDetails(isSkipped: true);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.pink, Colors.pinkAccent],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _isSkipLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Skip",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
