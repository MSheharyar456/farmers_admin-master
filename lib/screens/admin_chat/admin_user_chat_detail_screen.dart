import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/chat_model.dart';
import 'package:farmers_admin/services/admin_chat_service.dart';

class AdminUserChatDetailScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String contactId;
  final String contactName;
  final String? contactProfileImage;
  final String? contactProfileColor;

  const AdminUserChatDetailScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.contactId,
    required this.contactName,
    this.contactProfileImage,
    this.contactProfileColor,
  });

  @override
  State<AdminUserChatDetailScreen> createState() =>
      _AdminUserChatDetailScreenState();
}

class _AdminUserChatDetailScreenState extends State<AdminUserChatDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: ChatDetailContent(
        targetUserId: widget.targetUserId,
        targetUserName: widget.targetUserName,
        contactId: widget.contactId,
        contactName: widget.contactName,
        contactProfileImage: widget.contactProfileImage,
        contactProfileColor: widget.contactProfileColor,
      ),
    );
  }
}

class ChatDetailContent extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String contactId;
  final String contactName;
  final String? contactProfileImage;
  final String? contactProfileColor;

  const ChatDetailContent({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.contactId,
    required this.contactName,
    this.contactProfileImage,
    this.contactProfileColor,
  });

  @override
  State<ChatDetailContent> createState() => _ChatDetailContentState();
}

class _ChatDetailContentState extends State<ChatDetailContent> {
  late final AdminChatService _chatService;
  List<AdminChatMessage> _messages = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatService = context.read<AdminChatService>();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final messages = await _chatService.getMessages(
        widget.targetUserId,
        widget.contactId,
      );
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.green;
    try {
      final h = hex.replaceAll('#', '').trim();
      if (h.length == 6) {
        return Color(int.parse('FF$h', radix: 16));
      } else if (h.length == 8) {
        return Color(int.parse(h, radix: 16));
      }
    } catch (_) {}
    return Colors.green;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) {
      return 'Today';
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 40,
                vertical: isMobile ? 12 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isMobile),
                  const SizedBox(height: 20),
                  // Chat Conversation Box inside a Premium Container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                // Conversation target info header (inside the container)
                                _buildConversationInfoBar(),
                                // Info Warning Banner
                                _buildWarningBanner(),
                                // Messages List View
                                Expanded(
                                  child: Container(
                                    color: const Color(0xFFF8FAFC),
                                    child: _buildMessagesList(),
                                  ),
                                ),
                              ],
                            ),
                            if (_isLoading)
                              const Positioned.fill(
                                child: LoadingOverlay(
                                  text: 'Loading...',
                                  showBackdrop: true,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                "Conversation: ${widget.targetUserName} & ${widget.contactName}",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 48.0),
          child: Text(
            "Dashboard / Chat Monitoring / Chats / Details",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey,
              fontSize: 10,
              letterSpacing: 0.5,
              fontWeight: FontWeight.normal,
              fontFamily: 'Roboto',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversationInfoBar() {
    final parsedContactColor = _parseHexColor(widget.contactProfileColor);
    final hasValidImg =
        widget.contactProfileImage != null &&
        widget.contactProfileImage!.isNotEmpty &&
        widget.contactProfileImage != 'default_pfp.jpg' &&
        !widget.contactProfileImage!.endsWith('default_pfp.jpg');

    String normalizedUrl = widget.contactProfileImage ?? '';
    if (hasValidImg && !widget.contactProfileImage!.startsWith('http')) {
      final base = apiBaseUrl.endsWith('/')
          ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
          : apiBaseUrl;
      normalizedUrl = widget.contactProfileImage!.startsWith('/')
          ? '$base${widget.contactProfileImage}'
          : '$base/${widget.contactProfileImage}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: parsedContactColor,
            child: hasValidImg
                ? ClipOval(
                    child: Image.network(
                      normalizedUrl,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        _getInitials(widget.contactName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : Text(
                    _getInitials(widget.contactName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Monitoring conversation history",
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20, color: Colors.green),
            tooltip: 'Refresh messages',
            onPressed: _loadMessages,
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.amber.shade100, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Read-only monitoring mode. End-to-end encrypted messages decrypted locally using derived user conversation keys.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading && _messages.isEmpty) {
      return const SizedBox();
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          "No messages in this chat",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final msg = _messages[index];
          final previousMsg = index > 0 ? _messages[index - 1] : null;
          final showDate =
              index == 0 ||
              (previousMsg != null &&
                  !_isSameDay(previousMsg.createdAt, msg.createdAt));
          final isTargetUser = msg.senderId == widget.targetUserId;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDate) _buildDateSeparator(msg.createdAt),
              _buildMessageBubble(msg, isTargetUser),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _formatDateSeparator(date),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(AdminChatMessage msg, bool isTargetUser) {
    final senderName = isTargetUser
        ? widget.targetUserName
        : widget.contactName;
    final alignRight = isTargetUser;
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: alignRight
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              senderName,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: alignRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth < 600 ? screenWidth * 0.75 : 500,
                  ),
                  decoration: BoxDecoration(
                    color: alignRight ? const Color(0xFFE8F5E9) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: alignRight
                          ? const Radius.circular(12)
                          : Radius.zero,
                      bottomRight: alignRight
                          ? Radius.zero
                          : const Radius.circular(12),
                    ),
                    border: Border.all(
                      color: alignRight
                          ? const Color(0xFFC8E6C9)
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.message,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('h:mm a').format(msg.createdAt),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (alignRight) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 11,
                              color: msg.isRead ? Colors.blue : Colors.grey,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
