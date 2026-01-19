import 'package:farmers_admin/constants/app_colors.dart';
import 'package:farmers_admin/models/chat_model.dart';
import 'package:farmers_admin/screens/admin_chat/admin_chat_detail_screen.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminChatListScreen extends StatefulWidget {
  const AdminChatListScreen({super.key});

  @override
  State<AdminChatListScreen> createState() => _AdminChatListScreenState();
}

class _AdminChatListScreenState extends State<AdminChatListScreen> {
  final DatabaseReference _chatsRef = FirebaseDatabase.instance.ref().child(
    'admin_chats',
  );

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>()!;

    return ResponsiveScaffold(
      title: "Admin Chat",
      content: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Messages",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _chatsRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('No chats available'));
                  }

                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );
                  final List<ChatUser> chatUsers = [];

                  data.forEach((key, value) {
                    final chatData = Map<String, dynamic>.from(value as Map);
                    int unreadCount = 0;

                    if (chatData.containsKey('messages')) {
                      final messages = Map<String, dynamic>.from(
                        chatData['messages'] as Map,
                      );
                      messages.forEach((msgId, msgValue) {
                        final msg = Map<String, dynamic>.from(msgValue as Map);
                        if (msg['seen'] == false &&
                            msg['senderId'] != 'admin') {
                          unreadCount++;
                        }
                      });
                    }

                    if (chatData.containsKey('meta')) {
                      final meta = Map<String, dynamic>.from(
                        chatData['meta'] as Map,
                      );
                      chatUsers.add(
                        ChatUser.fromMap(meta, unreadCount: unreadCount),
                      );
                    }
                  });

                  // Sort by last time
                  chatUsers.sort((a, b) => b.lastTime.compareTo(a.lastTime));

                  return ListView.builder(
                    itemCount: chatUsers.length,
                    itemBuilder: (context, index) {
                      final user = chatUsers[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: appColors.brandColor,
                            child: Text(
                              user.userName.isNotEmpty
                                  ? user.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            user.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            user.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatTimestamp(user.lastTime),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              if (user.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${user.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminChatDetailScreen(
                                  userId: user.userId,
                                  userName: user.userName,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return DateFormat('hh:mm a').format(date);
    } else {
      return DateFormat('MMM d, hh:mm a').format(date);
    }
  }
}
