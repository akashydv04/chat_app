import 'package:chat_app/model/user_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat List")),
      body: currentUserId == null
          ? const Center(child: Text("Not logged in"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .where('participants', arrayContains: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No chats found"));
                }

                final chatDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatDocs.length,
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
                      return const SizedBox.shrink(); // skip if invalid
                    }

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(friendId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const ListTile(title: Text("Loading..."));
                        }

                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          return const ListTile(title: Text("User not found"));
                        }

                        final userDoc = userSnapshot.data!;
                        final appUser = AppUser.fromFirestore(userDoc);

                        return ListTile(
                          title: Text(appUser.name ?? 'Unknown'),
                          subtitle: const Text("Tap to chat"),
                          leading: CircleAvatar(
                            radius: 28,
                            backgroundImage: appUser.profileImageUrl.isNotEmpty
                                ? NetworkImage(appUser.profileImageUrl)
                                : AssetImage(
                                        appUser.gender == 'Male'
                                            ? 'assets/images/man.png'
                                            : 'assets/images/woman.png',
                                      )
                                      as ImageProvider,
                          ),
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
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
