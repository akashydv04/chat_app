import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../model/user_data.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  List<AppUser> list = [];
  bool isLoading = true;

  Future<void> getUsersList() async {
    try {
      final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      setState(() {
        list = querySnapshot.docs
            .map((doc) => AppUser.fromFirestore(doc))
            .where((user) => user.email != currentUserEmail)
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching users: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUsersList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Users List')),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 15))
            : list.isEmpty
            ? const Center(
                child: Text(
                  'No users found',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
              )
            : CupertinoScrollbar(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => Container(
                    height: 0.5,
                    color: CupertinoColors.separator,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  itemBuilder: (context, index) {
                    final user = list[index];
                    return CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => gotoProfileDetails(user.email),
                      child: Container(
                        color: CupertinoColors.systemGroupedBackground,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'profile_${user.email}',
                              child: CircleAvatar(
                                radius: 28,
                                backgroundImage: user.profileImageUrl.isNotEmpty
                                    ? NetworkImage(user.profileImageUrl)
                                    : AssetImage(
                                            user.gender == 'Male'
                                                ? 'assets/images/man.png'
                                                : 'assets/images/woman.png',
                                          )
                                          as ImageProvider,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.label,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.gender,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.systemGrey2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 0,
                              onPressed: () => findUserID(user.email),
                              child: const Icon(
                                CupertinoIcons.chat_bubble_2_fill,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
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

  void gotoProfileDetails(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final selectedUserId = querySnapshot.docs.first.id;
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {"friendId": selectedUserId},
        );
      }
    } catch (e) {
      print('Error getting user ID: $e');
    }
  }
}
