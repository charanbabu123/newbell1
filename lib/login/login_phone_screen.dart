import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert';

import 'otp_screen.dart';

class LoginPhoneScreen extends StatefulWidget {
  const LoginPhoneScreen({super.key});

  @override
  State<LoginPhoneScreen> createState() => _LoginPhoneScreenState();
}

class _LoginPhoneScreenState extends State<LoginPhoneScreen> {
  final TextEditingController phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isButtonEnabled = false; // Initially, the button will be disabled
  bool isLoading = false; // To manage loading state of the button

  @override
  void initState() {
    super.initState();
    phoneController.addListener(_onPhoneNumberChanged);
  }

  @override
  void dispose() {
    phoneController.removeListener(_onPhoneNumberChanged);
    super.dispose();
  }

  void _onPhoneNumberChanged() {
    setState(() {
      isButtonEnabled = phoneController.text.length == 10;
    });
  }

  // Import to use jsonEncode()

  Future<void> _requestOtp() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Validate phone number before sending
      if (phoneController.text.isEmpty) {
        _showSnackbar('Please enter a valid phone number');
        return;
      }

      // Ensure proper phone number formatting
      String phoneNumber = phoneController.text.trim();
      // Add +91 if not already present (adjust based on your country code requirement)
      if (!phoneNumber.startsWith('+91')) {
        phoneNumber = '+91$phoneNumber';
      }

      const String apiUrl =
          'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/request-otp/';

      final Map<String, dynamic> body = {
        'phone_number': phoneNumber,
      };

      debugPrint('Sending request to: $apiUrl'); // Detailed logging
      debugPrint('Request Body: $body'); // Log the exact body being sent

      final http.Response response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          // Optional: Add any additional headers if required by the API
          //'Authorization': 'Bearer YOUR_TOKEN_IF_NEEDED',
        },
        body: jsonEncode(body),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body: ${response.body}');

      // More detailed error handling
      if (response.statusCode == 200) {
        // Parse the response to confirm OTP generation
        final responseBody = jsonDecode(response.body);

        // Check for specific success indicators in the response
        if (responseBody['status'] == 'success' ||
            responseBody.containsKey('otp_request_id')) {
          Navigator.pushNamed(context, '/otp');
          _showSnackbar('OTP sent successfully!');
        } else {
          _showSnackbar('OTP sent successfully!');
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OtpScreen(phoneNumber: phoneNumber)),
            );
          });
        }
      } else {
        // More granular error handling
        final errorMessage = response.body;
        debugPrint('Full error response: $errorMessage');

        _showSnackbar(
            'Failed to send OTP. Status code: ${response.statusCode}. '
            'Please check your number and try again.');
      }
    } on SocketException catch (e) {
      // Handle network connectivity issues
      debugPrint('Network error: $e');
      _showSnackbar('No internet connection. Please check your network.');
    } on FormatException catch (e) {
      // Handle JSON parsing errors
      debugPrint('JSON parsing error: $e');
      _showSnackbar('Error processing server response');
    } catch (e) {
      debugPrint('Unexpected error: $e');
      _showSnackbar('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// 🔥 **Show a SnackBar**
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F7),
      body: Stack(
        children: [
          Positioned(
            top: 22,
            right: 10,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // Text color
                  backgroundColor: Colors.green, // Button background color set to green
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Padding for a better look
                ),
                child: const Text("For Employees"),
              ),


          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Access Limitless Possibilities With Your Mobile Number",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        wordSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      autofocus: false,
                      decoration: const InputDecoration(
                        prefixText: "+91 ",
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black, width: 1),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Phone number is required";
                        } else if (value.length != 10 ||
                            !RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return "Enter a valid 10-digit phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "We will send the OTP to this number",
                      style: TextStyle(fontSize: 14, color: Colors.black45),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                     // without api call
                      // onTap: isButtonEnabled && !isLoading
                      //     ? () {
                      //         if (_formKey.currentState!.validate()) {
                      //           _requestOtp();
                      //         }
                      //       }
                      //     : null,
                      onTap: isButtonEnabled && !isLoading
                          ? () {
                        if (_formKey.currentState!.validate()) {
                          // Add +91 to the phone number
                          String phoneNumber = phoneController.text.trim();
                          if (!phoneNumber.startsWith('+91')) {
                            phoneNumber = '+91$phoneNumber';
                          }

                          // Navigate to the OTP screen directly with the updated phone number
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtpScreen(phoneNumber: phoneNumber),
                            ),
                          );
                        }
                      }
                          : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isButtonEnabled
                              ? Colors.green
                              : const Color.fromRGBO(212, 202, 191, 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text(
                                "Generate OTP",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
