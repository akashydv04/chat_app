import 'dart:io';

import 'package:chat_app/model/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../utils/firebase_storage_service_utils.dart';
import '../../utils/image_picker_bottom_sheet.dart';
import '../../utils/utils.dart';

class ProfileScreen extends StatefulWidget {
  final dynamic currentUser;
  const ProfileScreen({super.key, this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  dynamic get user => widget.currentUser;
  String friendName = "";
  String userId = "";
  AppUser? userData;
  bool isCurrentUser = false;
  bool isLoading = true;
  bool isBlocked = false;
  bool _isLoading = false;
  String _uploadedFile = "";
  double _uploadProgress = 0.0;
  String? _selectedImageUrl;
  final ImagePicker picker = ImagePicker();

  var currentUser = FirebaseAuth.instance.currentUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      userId = arguments['friendId'];
      getFriendDetails();
    }
  }

  @override
  void initState() {
    super.initState();
    getFriendDetails();
  }

  Future<void> getFriendDetails() async {
    if (user == null && userId.isEmpty) return;
    if (userId.isEmpty) userId = user;

    try {
      final userRef = FirebaseFirestore.instance.collection('users');
      final res = await userRef.doc(userId).get();
      final currentUserDoc = await userRef.doc(currentUser!.uid).get();

      if (res.exists && currentUserDoc.exists) {
        final data = res.data();
        final currentData = currentUserDoc.data();
        final blockedList = List<String>.from(
          currentData?['blockedUsers'] ?? [],
        );

        setState(() {
          userData = AppUser.fromFirestore(res);
          friendName = data?['name'] ?? "Chat Room";
          isCurrentUser = userId == currentUser?.uid;
          isBlocked = blockedList.contains(userId);
        });
      }
    } catch (e) {
      print("Error getting friend details: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void logOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, "/login");
  }

  void _onPickImage(BuildContext context) async {
    final selectedSource = await showImagePickerBottomSheet(context);

    if (selectedSource == null) return;

    // Do something based on selection
    if (selectedSource == ImageSourceType.camera) {
      _pickImage(ImageSource.camera);
    } else if (selectedSource == ImageSourceType.gallery) {
      // _pickImage(ImageSource.gallery);
      _uploadImageFromGallery();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? selectedImage = await picker.pickImage(source: source);
      if (selectedImage != null) {
        // Read the image as bytes and encode it to Base64
        final File imageFile = File(selectedImage.path);
        final bytes = await imageFile.readAsBytes();

        if (selectedImage != null)
          print("Picked from camera: ${selectedImage.path}");
      }
    } catch (e) {
      Utils.showSnackBar(context, "Error picking image: $e");
    }
  }

  Future<void> _uploadImageFromGallery() async {
    setState(() {
      _isLoading = true;
    });

    final fileName = 'image_${currentUser?.uid}.jpg';
    final downloadUrl = await FirebaseStorageService.uploadImage(
      folder: 'uploads',
      fileName: fileName,
      source: ImageSource.gallery,
    );

    setState(() {
      _isLoading = false;
    });

    if (downloadUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
      updateProfileImage(downloadUrl);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage:
                          (userData != null &&
                              userData!.profileImageUrl.isNotEmpty)
                          ? NetworkImage(userData!.profileImageUrl)
                          : AssetImage(
                                  userData != null && userData!.gender == 'Male'
                                      ? 'assets/images/man.png'
                                      : 'assets/images/woman.png',
                                )
                                as ImageProvider,
                    ),
                    if (isCurrentUser)
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            _onPickImage(context);
                          },
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue,
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  friendName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+61 0404 123 456',
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 30),
                isCurrentUser
                    ? Expanded(
                        child: ListView(
                          children: [
                            _buildOption(Icons.person_outline, 'My account'),
                            _buildOption(
                              Icons.notifications_none,
                              'Notifications',
                            ),
                            _buildOption(
                              Icons.shield_outlined,
                              'Privacy and safety',
                            ),
                            _buildOption(
                              Icons.pie_chart_outline,
                              'Data and storage',
                            ),
                            _buildOption(Icons.devices_other, 'Devices'),
                            _buildOption(Icons.help_outline, 'FAQ'),
                            _buildOption(Icons.settings_outlined, 'Settings'),
                            _buildOption(
                              Icons.logout,
                              'Logout',
                              onTap: () => logOut(context),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      createOrGetChatRoom(
                                        currentUser!.uid,
                                        userId,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      elevation: 1,
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black87,
                                      shadowColor: Colors.black12,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      "Message Now",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => toggleBlockUser(userId),
                                    style: ElevatedButton.styleFrom(
                                      elevation: 1,
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.redAccent,
                                      shadowColor: Colors.black12,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: Color(0xFFE0E0E0),
                                        ),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator()
                                        : Text(
                                            isBlocked ? "Unblock" : "Block",
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ],
            ),
    );
  }

  Widget _buildOption(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  Future<void> createOrGetChatRoom(
    String currentUserId,
    String selectedUserId,
  ) async {
    List<String> participants = [currentUserId, selectedUserId]..sort();
    String chatRoomId = "${participants[0]}_${participants[1]}";

    DocumentReference chatRoomRef = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId);

    DocumentSnapshot chatRoomSnapshot = await chatRoomRef.get();

    if (!chatRoomSnapshot.exists) {
      await chatRoomRef.set({
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    Navigator.pushNamed(
      context,
      '/chat',
      arguments: {
        'chatId': chatRoomId,
        'friendId': selectedUserId,
        'currentUserId': currentUserId,
      },
    );
  }

  Future<void> toggleBlockUser(String targetUserId) async {
    setState(() {
      _isLoading = true; // Add this to your state variables
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to perform this action.'),
          ),
        );
        return;
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);

      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User document not found.')),
        );
        return;
      }

      final data = userDoc.data() as Map<String, dynamic>?;
      final blockedUsers = List<String>.from(data?['blockedUsers'] ?? []);

      bool blocked;

      if (blockedUsers.contains(targetUserId)) {
        await userDocRef.update({
          'blockedUsers': FieldValue.arrayRemove([targetUserId]),
        });
        blocked = false;
      } else {
        await userDocRef.update({
          'blockedUsers': FieldValue.arrayUnion([targetUserId]),
        });
        blocked = true;
      }

      setState(() {
        isBlocked = blocked;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            blocked
                ? 'User blocked successfully.'
                : 'User unblocked successfully.',
          ),
          backgroundColor: blocked ? Colors.red : Colors.green,
        ),
      );
    } on FirebaseException catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Firebase error: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error toggling block user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void updateProfileImage(String downloadUrl) async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser?.uid);
      await userDocRef.update({'profileImageUrl': downloadUrl});
      setState(() {
        userData!.profileImageUrl = downloadUrl;
      });
    } catch (e) {
      print("Error updating profile image: $e");
    }
  }
}
