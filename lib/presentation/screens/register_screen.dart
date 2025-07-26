import 'package:chat_app/utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _name;
  String? _email;
  String? _password;
  String? _gender = 'Male'; // Default gender

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Lottie.asset(
                  "assets/lottie/signup_anim.json",
                  fit: BoxFit.fitHeight,
                  height: 250,
                ),
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: app_color_b3b3b3, width: 1),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
                onSaved: (value) => _name = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: app_color_b3b3b3, width: 1),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: app_color_b3b3b3, width: 1),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                onSaved: (value) => _password = value,
              ),
              const SizedBox(height: 16),
              const Text('Gender'),
              Row(
                children: [
                  Radio<String>(
                    value: 'Male',
                    activeColor: app_main_color,
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text('Male'),
                  Radio<String>(
                    value: 'Female',
                    activeColor: app_main_color,
                    groupValue: _gender,
                    onChanged: (value) {
                      setState(() {
                        _gender = value;
                      });
                    },
                  ),
                  const Text('Female'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: app_main_color,
                ),
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();
                    // Here, call Firebase Registration Logic
                    debugPrint('Name: $_name');
                    debugPrint('Email: $_email');
                    debugPrint('Password: $_password');
                    debugPrint('Gender: $_gender');
                    // Navigate to users list after success

                    signUpUSer(_email!, _password!, context, _name!, _gender!);
                  }
                },
                child: Text(
                  'Register',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void signUpUSer(
    String email,
    String password,
    BuildContext context,
    String name,
    String gender,
  ) async {
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': name,
        'email': email,
        'gender': gender,
        'created_at': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'weak-password' => 'The password is too weak.',
        'email-already-in-use' => 'This email is already registered.',
        _ => 'Registration failed. Try again.',
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      print(msg);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      print('Error: ${e.toString()}');
    }
  }
}
