import 'package:flutter/material.dart';
import 'city.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  NameScreenState createState() => NameScreenState();
}

class NameScreenState extends State<NameScreen> {
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _nameFocusNode = FocusNode();
  bool hasText = false;

  @override
  void initState() {
    super.initState();
    nameController.addListener(_handleTextChange); // Add this line
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
  }

// Add this method
  void _handleTextChange() {
    setState(() {
      hasText = nameController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    nameController.removeListener(_handleTextChange); // Add this line
    nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 135.0, left: 45.0, right: 45.0, bottom: 45.0),
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
              const SizedBox(height: 14),
              const Center(
              child: Text(
                "What's your name?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
              const SizedBox(height: 30),
              TextFormField(
                controller: nameController,
                focusNode: _nameFocusNode, // Attach the FocusNode
                decoration: InputDecoration(
                  hintText: "Enter your name", // Add the placeholder
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Name is required";
                  } else if (value.length < 2) {
                    return null;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: hasText ? () {  // Only add the onTap function if hasText is true
                  if (_formKey.currentState!.validate()) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CityScreen(
                        name: nameController.text,
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
                    borderRadius: BorderRadius.circular(8),
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
    );
  }
}
