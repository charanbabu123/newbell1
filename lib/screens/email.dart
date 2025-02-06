import 'package:bell_app1/screens/profile_pic.dart';
import 'package:flutter/material.dart';

class EmailScreen extends StatefulWidget {
  final String name;
  final String city;
  const EmailScreen({Key? key, required this.name, required this.city})
      : super(key: key);

  @override
  _EmailScreenState createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _emailFocusNode = FocusNode();
  bool hasText = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_handleTextChange); // Add this line
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

// Add this method
  void _handleTextChange() {
    setState(() {
      final email = emailController.text;
      // Regular expression for basic email validation
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{3,}$');

      // Check if the text is not empty and matches the email regex
      hasText = email.isNotEmpty && emailRegex.hasMatch(email);
    });
  }

  @override
  void dispose() {
    emailController.removeListener(_handleTextChange); // Add this line
    emailController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                top: 90.0, left: 45.0, right: 45.0, bottom: 45.0),
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
                    padding:
                        const EdgeInsets.all(12.0), // Padding around the icon
                    child: const Center(
                      // Center widget to center the icon
                      child: Icon(
                        Icons.person_outline_rounded, // Person icon
                        color: Colors.white, // Icon color
                        size: 30.0, // Icon size
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      "What's your email?",
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    focusNode: _emailFocusNode,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Enter Your Email", // Add the placeholder
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // No error if the field is empty
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return "Enter a valid email address"; // Error if not a valid email
                      }
                      return null; // No error if the email is valid
                    },
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: hasText
                        ? () {
                            // Only add the onTap function if hasText is true
                            if (_formKey.currentState!.validate()) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => ProfilePictureScreen(
                                  name: widget.name,
                                  city: widget.city,
                                  email: emailController.text,
                                ),
                              ));
                            }
                          }
                        : null, // Set to null when hasText is false to disable the button
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasText
                            ? Colors.green
                            : const Color.fromRGBO(212, 202, 191, 1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Text(
                        "Continue",
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
          const SizedBox(height: 25),
          Positioned(
            top: 50.0, // Adjust this value to position vertically
            right: 20.0, // Adjust this value to position horizontally
            child: TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProfilePictureScreen(
                      name: widget.name,
                      city: widget.city,
                      email: emailController.text,
                    ),
                  ));
                }
              },
              child: const Text(
                "Skip",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
