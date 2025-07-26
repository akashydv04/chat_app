import 'package:flutter/material.dart';

class Utils {
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(); // Ensure no overlapping Snackbars
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16.0),
        ),
        backgroundColor: Colors.black,
        duration: duration,
      ),
    );
  }
}
