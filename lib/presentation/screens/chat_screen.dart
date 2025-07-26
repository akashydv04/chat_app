import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? chatId;
  String? friendId;
  String? currentUserId;
  String friendName = "Chat Room";
  final TextEditingController _messageController = TextEditingController();
  bool isUserBlocked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      chatId = arguments['chatId'] as String?;
      friendId = arguments['friendId'] as String?;
      currentUserId = arguments['currentUserId'] as String?;
      getFriendDetails();
    }
  }

  Future<void> getFriendDetails() async {
    try {
      var res = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .get();
      if (res.exists) {
        var data = res.data();
        if (data != null) {
          setState(() {
            friendName = data['name'] ?? "Chat Room";
          });

          isUserBlocked = await isBlocked(currentUserId!, friendId!);
          if (isUserBlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("You are blocked by $friendName")),
            );
          }
        }
      }
    } catch (e) {
      print("Error getting friend details: $e");
    }
  }

  Future<void> sendMessage(String message) async {
    if (chatId == null || message.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': currentUserId,
          'receiverId': friendId,
          'message': message.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });

    _messageController.clear();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> messageStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<bool> isBlocked(String currentUserId, String receiverUserId) async {
    final receiverDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUserId)
        .get();

    final blockedUsers = List<String>.from(receiverDoc['blockedUsers'] ?? []);
    return blockedUsers.contains(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(friendName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: messageStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text("Error loading messages"));
                if (!snapshot.hasData)
                  return Center(child: CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data();
                    final isMe = msg['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['message'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (isUserBlocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("You are blocked by $friendName"),
                        ),
                      );
                      return;
                    }
                    sendMessage(_messageController.text);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
        ],
      ),
    );
  }
}
