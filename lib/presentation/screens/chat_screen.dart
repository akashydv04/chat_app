import 'package:cached_network_image/cached_network_image.dart';
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
  String? _friendImageUrl;
  String? _myProfileImageUrl;
  String friendName = "Chat Room";
  final TextEditingController _messageController = TextEditingController();
  bool isUserBlocked = false;
  bool _sending = false;

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

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {}); // Triggers rebuild when text changes
    });
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
            _friendImageUrl = data['profileImageUrl'] ?? "";
          });

          getOwnDetails();
          isUserBlocked = await isBlocked(currentUserId!, friendId!);
          if (isUserBlocked && mounted) {
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

  Future<void> getOwnDetails() async {
    try {
      var res = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();
      if (res.exists) {
        var data = res.data();
        if (data != null) {
          setState(() {
            _myProfileImageUrl = data['profileImageUrl'] ?? "";
          });
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

    setState(() => _sending = true);
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
    setState(() => _sending = false);
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

  Widget buildBubble(Map<String, dynamic> msg, bool isMe) {
    Color bg = isMe ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5;
    Color fg = isMe ? CupertinoColors.white : CupertinoColors.black;
    BorderRadius radius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(8),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomRight: Radius.circular(22),
            bottomLeft: Radius.circular(8),
          );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4, right: 2),
            child: CircleAvatar(
              backgroundColor: CupertinoColors.systemGrey3,
              radius: 14,
              backgroundImage: _friendImageUrl != null
                  ? CachedNetworkImageProvider(_friendImageUrl!)
                  : null,
              child: _friendImageUrl == null
                  ? const Icon(
                      CupertinoIcons.person,
                      color: CupertinoColors.systemGrey,
                      size: 18,
                    )
                  : null,
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 2),
          constraints: BoxConstraints(
            minWidth: 48,
            maxWidth:
                MediaQueryData.fromView(
                  WidgetsBinding.instance.window,
                ).size.width *
                0.7,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: isMe
                    ? CupertinoColors.activeBlue.withOpacity(0.16)
                    : CupertinoColors.systemGrey2.withOpacity(0.18),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            msg['message'] ?? '',
            style: TextStyle(
              color: fg,
              fontSize: 17,
              height: 1.3,
              fontFamily: 'ChatApp', // Should match the family in pubspec.yaml
              fontWeight: FontWeight.normal, // Ensures the font is not bold
              decoration: TextDecoration.none,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 8, bottom: 4),
            child: CircleAvatar(
              backgroundColor: CupertinoColors.systemGrey3,
              radius: 14,
              backgroundImage: _myProfileImageUrl != null
                  ? CachedNetworkImageProvider(_myProfileImageUrl!)
                  : null,
              child: _myProfileImageUrl == null
                  ? const Icon(
                      CupertinoIcons.person,
                      color: CupertinoColors.systemGrey,
                      size: 18,
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  Widget buildInputBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 8, 7),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _messageController,
              placeholder: "Type a message",
              maxLines: 4,
              minLines: 1,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(22),
              ),
              style: const TextStyle(fontSize: 16),
              enabled: !isUserBlocked && !_sending,
              onSubmitted: (msg) {
                if (msg.trim().isNotEmpty && !isUserBlocked) {
                  sendMessage(msg);
                }
              },
            ),
          ),
          const SizedBox(width: 6),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            color: CupertinoColors.activeBlue,
            borderRadius: BorderRadius.circular(22),
            onPressed:
                (_messageController.text.trim().isEmpty ||
                    isUserBlocked ||
                    _sending)
                ? null
                : () => sendMessage(_messageController.text),
            child: _sending
                ? const CupertinoActivityIndicator(
                    color: CupertinoColors.white,
                    radius: 10,
                  )
                : const Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    color: CupertinoColors.white,
                    size: 31,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(friendName),
        backgroundColor: CupertinoColors.systemGrey6,
        border: null,
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

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        "No messages yet",
                        style: TextStyle(
                          color: CupertinoColors.inactiveGray,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 2,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index].data();
                      final isMe = msg['senderId'] == currentUserId;
                      return buildBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),
            if (isUserBlocked)
              Container(
                height: 52,
                color: CupertinoColors.systemGrey6,
                child: const Center(
                  child: Text(
                    "You are blocked by this user.",
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
            else
              AnimatedPadding(
                duration: const Duration(milliseconds: 130),
                padding: EdgeInsets.only(bottom: bottomInset),
                child: buildInputBar(),
              ),
          ],
        ),
      ),
    );
  }
}
