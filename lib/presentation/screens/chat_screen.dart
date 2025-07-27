import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
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
            showCupertinoDialog(
              context: context,
              builder: (_) => CupertinoAlertDialog(
                title: Text("Blocked"),
                content: Text("You are blocked by $friendName"),
                actions: [
                  CupertinoDialogAction(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      print("Error getting friend details: $e");
    }
  }

  Future<bool> isBlocked(String currentUserId, String receiverUserId) async {
    final receiverDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(receiverUserId)
        .get();

    final blockedUsers = List<String>.from(receiverDoc['blockedUsers'] ?? []);
    return blockedUsers.contains(currentUserId);
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(friendName),
        backgroundColor: CupertinoColors.systemGrey6,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: messageStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading messages"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CupertinoActivityIndicator());
                  }

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
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey4,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            msg['message'] ?? '',
                            style: TextStyle(
                              color: isMe
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: "Type a message",
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: CupertinoColors.activeBlue,
                      size: 28,
                    ),
                    onPressed: () {
                      if (isUserBlocked) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: Text("Blocked"),
                            content: Text("You are blocked by $friendName"),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text("OK"),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
