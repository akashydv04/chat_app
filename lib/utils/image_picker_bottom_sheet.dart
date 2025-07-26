import 'package:flutter/material.dart';

/// Enum to differentiate image source
enum ImageSourceType { camera, gallery }

/// Shows a bottom sheet and returns the selected image source
Future<ImageSourceType?> showImagePickerBottomSheet(BuildContext context) {
  return showModalBottomSheet<ImageSourceType>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            "Choose Image Source",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Take a Photo"),
            onTap: () => Navigator.pop(ctx, ImageSourceType.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Choose from Gallery"),
            onTap: () => Navigator.pop(ctx, ImageSourceType.gallery),
          ),
          const SizedBox(height: 12),
        ],
      );
    },
  );
}
