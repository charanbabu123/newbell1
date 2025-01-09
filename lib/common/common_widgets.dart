import 'package:flutter/material.dart';

class CommonWidgets
{
  static Padding recordVideoButton({required void Function()? onPressed}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.emergency_recording, color: Colors.pink),
        label: const Text(
          "Record Video",
          style: TextStyle(
            color: Colors.pink,
          ),
        ),
      ),
    );
  }
}