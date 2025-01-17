import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/feed_screen.dart';
import '../screens/name.dart';
import '../services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  String enteredOtp = "";
  String? _errorMessage;
  bool isLoading = false;
  bool isSuccess = false;
  bool isError = false;
  bool? isNewUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    });
  }

  Future<bool> checkFirstTimeUser() async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/first-time/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone_number': widget.phoneNumber}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['exists'] && jsonResponse['has_profile'];
      }
      return true;
    } catch (error) {
      debugPrint("Error checking first time user: $error");
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8F7),
      appBar: AppBar(title: const Text("Enter OTP")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(36.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please Enter The One Time Password To Verify Your Account",
                style: TextStyle(
                    color: Colors.pink,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (index) => _otpBox(index)),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _isOtpComplete() && !isLoading ? _verifyOtp : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isOtpComplete()
                          ? [Colors.pinkAccent, Colors.pink]
                          : [Colors.grey, Colors.grey],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        )
                      : isSuccess
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 30,
                            )
                          : isError
                              ? const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : Text(
                                  "Verify OTP",
                                  style: TextStyle(
                                    color: _isOtpComplete()
                                        ? Colors.white
                                        : Colors.black38,
                                    fontWeight: FontWeight.bold,
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

  bool _isOtpComplete() {
    // Check if all OTP fields are filled
    return _controllers.every((controller) => controller.text.isNotEmpty);
  }

  void _verifyOtp() async {
    setState(() {
      isLoading = true;
      isSuccess = false;
      isError = false;
      _errorMessage = null;
    });

    enteredOtp = _controllers.map((controller) => controller.text).join();

    if (enteredOtp.isEmpty) {
      setState(() {
        isLoading = false;
        _errorMessage = "Please enter the OTP.";
      });
      return;
    }

    try {
      isNewUser = await checkFirstTimeUser();

      final response = await http.post(
        Uri.parse(
            'https://rrrg77yzmd.ap-south-1.awsapprunner.com/api/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': widget.phoneNumber,
          'otp': enteredOtp,
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('existing_user : $isNewUser ');
      final jsonResponse = jsonDecode(response.body);
      final sessionId = jsonResponse['sessionId'];
      final accessToken = jsonResponse['tokens']['access'];
      final refreshToken = jsonResponse['tokens']['refresh'];

      await AuthService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      await AuthService.savePhoneNumber(widget.phoneNumber);

      if (response.statusCode == 200 && sessionId == null) {
        setState(() {
          isLoading = false;
          isSuccess = true;
        });
        _showSnackbar('OTP verified successfully!');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("userExists", true);

        if (context.mounted) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    isNewUser! ? const FeedScreen() : const NameScreen(),
              ),
              (route) => false,
            );
          });
        }
      } else {
        setState(() {
          isLoading = false;
          isError = true;
          _errorMessage =
              jsonResponse['message'] ?? "Invalid OTP. Please try again.";
        });
        _showSnackbar(_errorMessage ?? "Invalid OTP. Please try again.");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        isError = true;
        _errorMessage = "Something went wrong. Please try again later.";
      });
      debugPrint("Error occurred: $error");
      _showSnackbar(_errorMessage!);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.pinkAccent,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 50,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty) {
            if (index > 0) {
              _controllers[index - 1].clear();
              FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
            }
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.pinkAccent),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _controllers[index].text.isNotEmpty
                    ? Colors.pink.shade800
                    : Colors.pink,
                width: 2.0,
              ),
            ),
            counterText: "",
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              if (index < 3) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              }
            }
            setState(() {});
          },
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    //
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
