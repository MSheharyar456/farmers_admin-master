import 'package:farmers_admin/constants/app_colors.dart';
import 'package:farmers_admin/models/chat_model.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminChatDetailScreen> createState() => _AdminChatDetailScreenState();
}

class _AdminChatDetailScreenState extends State<AdminChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  late DatabaseReference _messagesRef;
  late DatabaseReference _metaRef;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messagesRef = FirebaseDatabase.instance.ref().child(
      'admin_chats/${widget.userId}/messages',
    );
    _metaRef = FirebaseDatabase.instance.ref().child(
      'admin_chats/${widget.userId}/meta',
    );
    _markMessagesAsSeen();
  }

  void _markMessagesAsSeen() {
    _messagesRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          final msg = Map<String, dynamic>.from(value as Map);
          if (msg['seen'] == false && msg['senderId'] != 'admin') {
            _messagesRef.child(key).update({'seen': true});
          }
        });
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newMessageRef = _messagesRef.push();
    final messageId = newMessageRef.key;

    final message = ChatMessage(
      id: messageId!,
      senderId: 'admin', // Or actual admin ID if available
      senderName: 'Admin',
      text: text,
      timestamp: timestamp,
      seen: false,
    );

    newMessageRef.set(message.toMap());

    // Update meta
    _metaRef.update({
      'lastMessage': text,
      'lastTime': timestamp,
      'userId': widget.userId,
      'userName': widget.userName,
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appColors.brandColor,
        title: Text(widget.userName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DatabaseEvent>(
              stream: _messagesRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No messages yet'));
                }

                final data = Map<String, dynamic>.from(
                  snapshot.data!.snapshot.value as Map,
                );
                final List<ChatMessage> messages = [];

                data.forEach((key, value) {
                  final messageData = Map<String, dynamic>.from(value as Map);
                  messages.add(ChatMessage.fromMap(messageData));
                });

                // Sort by timestamp descending for reverse list view
                messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == 'admin';

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isMe ? appColors.brandColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _formatTimestamp(message.timestamp),
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: appColors.brandColor),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('hh:mm a').format(date);
  }
}
