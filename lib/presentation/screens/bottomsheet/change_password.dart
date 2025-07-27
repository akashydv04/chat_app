import 'package:chat_app/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

Future<void> changePassword(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  String? oldPassword;
  String? newPassword;
  bool isLoading = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext ctx) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 15,
              right: 15,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Change Password",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: "assets/fonts/Chat-app_medium.otf",
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "Old Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    onSaved: (value) => oldPassword = value,
                    validator: (value) => value == null || value.isEmpty
                        ? "Enter old password"
                        : null,
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: "New Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                    onSaved: (value) => newPassword = value,
                    validator: (value) => value == null || value.length < 6
                        ? "New password must be at least 6 characters"
                        : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: app_main_color,
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (formKey.currentState?.validate() ?? false) {
                              formKey.currentState?.save();
                              setModalState(() => isLoading = true);
                              try {
                                await updatePassword(
                                  context,
                                  oldPassword!,
                                  newPassword!,
                                );
                              } catch (_) {}
                              setModalState(() => isLoading = false);
                            }
                          },
                    child: isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            "Change",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> updatePassword(
  BuildContext context,
  String currentPassword,
  String newPassword,
) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('No user is currently signed in.');
  }

  final cred = EmailAuthProvider.credential(
    email: user.email!,
    password: currentPassword,
  );

  try {
    // Re-authenticate the user
    await user.reauthenticateWithCredential(cred);

    // Update the password
    await user.updatePassword(newPassword);

    print("Password changed successfully.");
    Utils.showSnackBar(context, "Password changed Successfully!!");
    Navigator.of(context).pop();
  } on FirebaseAuthException catch (e) {
    print("Error: ${e.message}");
    if (e.code == 'wrong-password') {
      Utils.showSnackBar(context, "The current password is incorrect.!!");
      throw Exception("The current password is incorrect.");
    } else {
      Utils.showSnackBar(context, "Failed to change password: ${e.message}");
      throw Exception("Failed to change password: ${e.message}");
    }
  } catch (e) {
    print("Unexpected error: $e");
    Utils.showSnackBar(context, "Something went wrong.");
    throw Exception("Something went wrong.");
  }
}
