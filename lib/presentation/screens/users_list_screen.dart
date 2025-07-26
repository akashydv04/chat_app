import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../model/user_data.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<AppUser> list = [];
  Future<void> getUsersList() async {
    try {
      var currentUserEmail = await FirebaseAuth.instance.currentUser?.email
          .toString();
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        list = querySnapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .toList();
        list.removeWhere((user) => user.email == currentUserEmail);
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  @override
  void initState() {
    getUsersList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users List')),
      body: ListView.builder(
        itemCount: list.length, // Sample users
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              gotoProfileDetails(list[index].email);
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Profile Image
                    GestureDetector(
                      onTap: () {
                        gotoProfileDetails(list[index].email);
                      },
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: list[index].profileImageUrl.isNotEmpty
                            ? NetworkImage(list[index].profileImageUrl)
                            : list[index].gender == 'Male'
                            ? const AssetImage('assets/images/man.png')
                            : const AssetImage(
                                'assets/images/woman.png',
                              ), // or use NetworkImage
                        // backgroundImage: NetworkImage(userImageUrl),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name and Gender
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list[index].name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            list[index].gender,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    // Chat icon
                    IconButton(
                      onPressed: () {
                        findUserID(list[index].email);
                      },
                      icon: const Icon(Icons.chat, color: Colors.blueAccent),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> findUserID(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('User found with ID: ${querySnapshot.docs.first.id}');
        final selectedUserId = querySnapshot.docs.first.id;
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          await createOrGetChatRoom(currentUserId, selectedUserId);
        }
      }
    } catch (e) {
      print('Error getting user ID: $e');
    }
  }

  Future<void> createOrGetChatRoom(
    String currentUserId,
    String selectedUserId,
  ) async {
    // Sort the user IDs to keep the ID consistent for both users
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
    print(chatRoomId);
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

  void gotoProfileDetails(String email) async {
    try {
      final querySnapshot = FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();
      querySnapshot.then((querySnapshot) {
        if (querySnapshot.docs.isNotEmpty) {
          final selectedUserId = querySnapshot.docs.first.id;
          Navigator.pushNamed(
            context,
            '/profile',
            arguments: {"friendId": selectedUserId},
          );
        }
      });
    } catch (e) {
      print('Error getting user ID: $e');
    }
  }
}
