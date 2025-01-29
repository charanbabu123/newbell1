import 'package:flutter/material.dart';

import 'email.dart';

class CityScreen extends StatefulWidget {
  final String name;
  const CityScreen({super.key, required this.name});

  @override
  _CityScreenState createState() => _CityScreenState();
}

class _CityScreenState extends State<CityScreen> {
  final TextEditingController cityController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _cityFocusNode = FocusNode();
  bool hasText = false;

  @override
  void initState() {
    super.initState();
    cityController.addListener(_handleTextChange); // Add this line
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_cityFocusNode);
    });
  }

// Add this method
  void _handleTextChange() {
    setState(() {
      hasText = cityController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    cityController.removeListener(_handleTextChange); // Add this line
    cityController.dispose();
    cityController.dispose();
    super.dispose();
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
              const Text(
                "Which city do you live in?",
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 30),
              TextFormField(
                focusNode: _cityFocusNode,
                controller: cityController,
                decoration: InputDecoration(
                  hintText: "Enter your city", // Add the placeholder
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                // validator: (value) {
                //   if (value == null || value.isEmpty) {
                //     return "City is required";
                //   }
                //   return null;
                // },
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: hasText ? () {  // Only add the onTap function if hasText is true
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EmailScreen(
                        name: widget.name,
                        city: cityController.text,

                      ),
                    ));
                  }
                } : null,  // Set to null when hasText is false to disable the button
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
              const SizedBox(height: 25),
              GestureDetector(
                onTap: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => EmailScreen(
                        name: widget.name,
                        city: cityController.text,
                      ),
                    ));
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white, // White background
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                    border: Border.all(color: Colors.green, width: 1), // Green border
                  ),
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.green, // Green text
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