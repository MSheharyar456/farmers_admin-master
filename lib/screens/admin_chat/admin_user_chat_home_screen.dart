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
import 'package:farmers_admin/screens/admin_chat/admin_user_chat_detail_screen.dart';

class AdminUserChatHomeScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const AdminUserChatHomeScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<AdminUserChatHomeScreen> createState() =>
      _AdminUserChatHomeScreenState();
}

class _AdminUserChatHomeScreenState extends State<AdminUserChatHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: ChatHomeContent(
        targetUserId: widget.targetUserId,
        targetUserName: widget.targetUserName,
      ),
    );
  }
}

class ChatHomeContent extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;

  const ChatHomeContent({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  @override
  State<ChatHomeContent> createState() => _ChatHomeContentState();
}

class _ChatHomeContentState extends State<ChatHomeContent> {
  late final AdminChatService _chatService;
  List<AdminChatUser> _contacts = [];
  List<AdminChatUser> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chatService = context.read<AdminChatService>();
    _loadChats();
  }

  Future<void> _loadChats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final chats = await _chatService.getUserChats(widget.targetUserId);
      if (mounted) {
        setState(() {
          _contacts = chats;
          _applySearch();
          _isLoading = false;
        });
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

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredContacts = _contacts;
    } else {
      _filteredContacts = _contacts
          .where(
            (c) =>
                c.username.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            child: RefreshIndicator(
              color: Colors.green,
              onRefresh: _loadChats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                      // Modern Container layout wrapping search and contacts list
                      Container(
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
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSearchBar(),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "CONVERSATIONS",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildBody(isMobile),
                                  ],
                                ),
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
                    ],
                  ),
                ),
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
                "Chats of ${widget.targetUserName}",
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
            "Dashboard / Chat Monitoring / Chats",
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

  Widget _buildSearchBar() {
    return SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 12),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applySearch();
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF1F5F9),
          hintText: 'Search chats...',
          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, size: 14, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 14, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _applySearch();
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.green, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (_isLoading && _filteredContacts.isEmpty) {
      return const SizedBox(height: 200);
    }

    if (_filteredContacts.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isEmpty
                    ? "No conversations found"
                    : "No matches found",
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _ChatContactTile(
          contact: contact,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminUserChatDetailScreen(
                  targetUserId: widget.targetUserId,
                  targetUserName: widget.targetUserName,
                  contactId: contact.id,
                  contactName: contact.username,
                  contactProfileImage: contact.profileImage,
                  contactProfileColor: contact.profileColor,
                ),
              ),
            ).then((_) => _loadChats());
          },
        );
      },
    );
  }
}

class _ChatContactTile extends StatelessWidget {
  final AdminChatUser contact;
  final VoidCallback onTap;

  const _ChatContactTile({required this.contact, required this.onTap});

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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final localDt = dt.toLocal();
    if (localDt.year == now.year &&
        localDt.month == now.month &&
        localDt.day == now.day) {
      return DateFormat('h:mm a').format(localDt);
    }
    return DateFormat('MMM d, h:mm a').format(localDt);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseHexColor(contact.profileColor);
    final hasValidImg =
        contact.profileImage.isNotEmpty &&
        contact.profileImage != 'default_pfp.jpg' &&
        !contact.profileImage.endsWith('default_pfp.jpg');

    String normalizedUrl = contact.profileImage;
    if (hasValidImg && !contact.profileImage.startsWith('http')) {
      final base = apiBaseUrl.endsWith('/')
          ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
          : apiBaseUrl;
      normalizedUrl = contact.profileImage.startsWith('/')
          ? '$base${contact.profileImage}'
          : '$base/${contact.profileImage}';
    }

    final isUnread = contact.unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isUnread
            ? Colors.green.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: bgColor,
                      child: hasValidImg
                          ? ClipOval(
                              child: Image.network(
                                normalizedUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Text(
                                  _getInitials(contact.username),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              _getInitials(contact.username),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                    if (contact.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.username,
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 13,
                          color: isUnread ? Colors.black : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (contact.lastMessage != null) ...[
                            Icon(
                              Icons.done_all,
                              size: 13,
                              color: isUnread
                                  ? Colors.green.shade400
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              contact.lastMessage ?? 'No messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isUnread
                                    ? Colors.black87
                                    : Colors.grey[600],
                                fontWeight: isUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDateTime(contact.lastMessageAt),
                      style: TextStyle(
                        color: isUnread ? Colors.green : Colors.grey[500],
                        fontSize: 10,
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${contact.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
