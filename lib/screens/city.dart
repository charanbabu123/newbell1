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
      body: Stack( // Wrap with Stack to allow overlapping widgets
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
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: const Center(
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 30.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Which city do you live in?",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    focusNode: _cityFocusNode,
                    controller: cityController,
                    decoration: InputDecoration(
                      hintText: "Enter your city",
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.black, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: hasText ? () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) =>
                              EmailScreen(
                                name: widget.name,
                                city: cityController.text,
                              ),
                        ));
                      }
                    } : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasText ? Colors.green : const Color.fromRGBO(
                            212, 202, 191, 1),
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
          // Add Skip button at top right
          Positioned(
            top: 50.0, // Adjust this value to position vertically
            right: 20.0, // Adjust this value to position horizontally
            child: TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        EmailScreen(
                          name: widget.name,
                          city: cityController.text,
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