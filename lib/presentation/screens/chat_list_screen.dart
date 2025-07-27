import 'package:chat_app/model/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Chats')),
      child: SafeArea(
        child: currentUserId == null
            ? const Center(child: Text("Not logged in"))
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chatRooms')
                    .where('participants', arrayContains: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No chats found"));
                  }

                  final chatDocs = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: chatDocs.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.3),
                    itemBuilder: (context, index) {
                      final chat = chatDocs[index];
                      final participants = List<String>.from(
                        chat['participants'],
                      );
                      final friendId = participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      if (friendId.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(friendId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: CupertinoActivityIndicator(),
                            );
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const ListTile(
                              title: Text("User not found"),
                            );
                          }

                          final userDoc = userSnapshot.data!;
                          final appUser = AppUser.fromFirestore(userDoc);

                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/chat',
                                arguments: {
                                  'chatId': chat.id,
                                  'friendId': friendId,
                                  'currentUserId': currentUserId,
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 7,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CupertinoColors.systemGrey4
                                          .withOpacity(0.13),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 30,
                                    backgroundImage:
                                        (appUser.profileImageUrl.isNotEmpty
                                        ? NetworkImage(appUser.profileImageUrl)
                                        : AssetImage(
                                                appUser.gender == 'Male'
                                                    ? 'assets/images/man.png'
                                                    : 'assets/images/woman.png',
                                              )
                                              as ImageProvider),
                                  ),
                                  title: Text(
                                    appUser.name ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: const Text("Tap to chat"),
                                  trailing: const Icon(
                                    CupertinoIcons.chevron_forward,
                                    color: CupertinoColors.inactiveGray,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
