// screens/user_management/deleted_user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:farmers_admin/models/deleted_user_model.dart';
import 'package:farmers_admin/services/deleted_users_api_service.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

class DeletedUserDetailScreen extends StatefulWidget {
  final String userId;

  const DeletedUserDetailScreen({super.key, required this.userId});

  @override
  State<DeletedUserDetailScreen> createState() => _DeletedUserDetailScreenState();
}


class _DeletedUserDetailScreenState extends State<DeletedUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late DeletedUsersApiService _apiService;
  DeletedUserFullDetails? _details;
  bool _isLoading = false;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AdminServerAuthService>(context, listen: false);
      _apiService = DeletedUsersApiService(authService);
      _loadDetails();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final details = await _apiService.getFullDetails(widget.userId);
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user details: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    final user = _details!.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user.profileImage != null && user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child: user.profileImage == null || user.profileImage!.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: const Text('DELETED'),
                              backgroundColor: Colors.red[100],
                              labelStyle: TextStyle(color: Colors.red[800]),
                            ),
                            if (user.isAdmin)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Chip(
                                  label: Text('ADMIN'),
                                  backgroundColor: Colors.purple,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Contact Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Phone', '${user.phoneCountryCode ?? ''} ${user.phoneComplete ?? 'N/A'}'),
                  _buildInfoRow('Account Created', _formatDate(user.createdAt)),
                  _buildInfoRow('Deleted On', _formatDate(user.deletedAt)),
                  _buildInfoRow('User ID', user.uid),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Post Limits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Post Limits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow('Post Limit', '${user.userPostLimit}'),
                  _buildInfoRow('Used', '${user.userPostLimitUsed}'),
                  _buildInfoRow('Edit Limit', '${user.userUpdatePostLimit}'),
                  _buildInfoRow('Min Following Required', '${user.userFollowing}'),
                  _buildInfoRow('Post Limit Days', '${user.userTotalPostsTime}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    final posts = _details!.posts;
    if (posts.isEmpty) {
      return const Center(child: Text('No posts found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.images.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.images.length,
                      itemBuilder: (context, imgIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.images[imgIndex],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (post.description != null && post.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      post.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(post.status ?? 'unknown'),
                      backgroundColor: post.status == 'active'
                          ? Colors.green[100]
                          : Colors.grey[200],
                    ),
                    const Spacer(),
                    if (post.date != null)
                      Text(
                        post.date!,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActivityTab() {
    final follows = _details!.follows;
    final stats = _details!.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Likes & Views
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Engagement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Likes Given', '${stats.likesGiven}'),
                  _buildInfoRow('Likes Received', '${stats.likesReceived}'),
                  _buildInfoRow('Total Views', '${stats.viewsReceived}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Blocks
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blocks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Blocks Given', '${stats.blocksGiven}'),
                  _buildInfoRow('Blocks Received', '${stats.blocksReceived}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Following
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Following (${follows.following.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (follows.following.isEmpty)
                    const Text('Not following anyone')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: follows.following.map((f) {
                        return Chip(
                          avatar: const CircleAvatar(child: Icon(Icons.person, size: 16)),
                          label: Text(f.username),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Followers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Followers (${follows.followers.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (follows.followers.isEmpty)
                    const Text('No followers')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: follows.followers.map((f) {
                        return Chip(
                          avatar: const CircleAvatar(child: Icon(Icons.person, size: 16)),
                          label: Text(f.username),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationsTab() {
    final messages = _details!.messages;
    final feedback = _details!.feedback;
    final reports = _details!.reports;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Messages Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Messages Sent', '${messages.sent}'),
                  _buildInfoRow('Messages Received', '${messages.received}'),
                  const SizedBox(height: 8),
                  Text(
                    'Conversation Partners (${messages.conversationPartners.length})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (messages.conversationPartners.isEmpty)
                    const Text('No conversations')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: messages.conversationPartners.map((p) {
                        return Chip(
                          avatar: const CircleAvatar(child: Icon(Icons.person, size: 16)),
                          label: Text(p.username),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Feedback
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback (${feedback.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (feedback.isEmpty)
                    const Text('No feedback submitted')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: feedback.length,
                      itemBuilder: (context, index) {
                        final fb = feedback[index];
                        return ListTile(
                          title: Text(fb.type ?? 'General'),
                          subtitle: Text(fb.message ?? ''),
                          trailing: fb.rating != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    fb.rating!,
                                    (i) => const Icon(Icons.star, size: 16, color: Colors.amber),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports Filed (${reports.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  if (reports.isEmpty)
                    const Text('No reports filed')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return ListTile(
                          title: Text(report.postTitle ?? 'Post #${report.postId}'),
                          subtitle: Text(report.additionalDetails ?? ''),
                          trailing: report.reportDate != null
                              ? Text(report.reportDate!)
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionsTab() {
    final commissions = _details!.commissions;
    if (commissions.isEmpty) {
      return const Center(child: Text('No commission transfers'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final c = commissions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${c.commissionAmount} ${c.currency ?? ''}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c.name} - ${c.bank}'),
                if (c.postCode != null) Text('Post: ${c.postCode}'),
              ],
            ),
            trailing: Chip(
              label: Text(c.status ?? 'pending'),
              backgroundColor: c.status == 'completed'
                  ? Colors.green[100]
                  : c.status == 'rejected'
                      ? Colors.red[100]
                      : Colors.orange[100],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkingStatusTab() {
    final workingStatus = _details!.workingStatus;
    if (workingStatus.isEmpty) {
      return const Center(child: Text('No working status entries'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workingStatus.length,
      itemBuilder: (context, index) {
        final ws = workingStatus[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: const Text('App Message'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ws.messageAr != null && ws.messageAr!.isNotEmpty)
                  Text('AR: ${ws.messageAr}'),
                if (ws.messageEn != null && ws.messageEn!.isNotEmpty)
                  Text('EN: ${ws.messageEn}'),
                if (ws.createdAt != null)
                  Text('Created: ${ws.createdAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_details?.user.userName ?? 'User Details'),
        bottom: _isLoading
            ? null
            : TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.person), text: 'Account'),
                  Tab(icon: Icon(Icons.post_add), text: 'Posts'),
                  Tab(icon: Icon(Icons.trending_up), text: 'Activity'),
                  Tab(icon: Icon(Icons.message), text: 'Communications'),
                  Tab(icon: Icon(Icons.attach_money), text: 'Commissions'),
                  Tab(icon: Icon(Icons.work), text: 'Working Status'),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _details == null
                  ? const Center(child: Text('No data available'))
                  : Column(
                      children: [
                        // Stats Row
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatCard(
                                  'Posts',
                                  '${_details!.stats.postsCount}',
                                  Icons.post_add,
                                  Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  'Likes',
                                  '${_details!.stats.likesGiven}',
                                  Icons.favorite,
                                  Colors.red,
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  'Followers',
                                  '${_details!.stats.followersCount}',
                                  Icons.people,
                                  Colors.green,
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  'Messages',
                                  '${_details!.stats.messagesSent}',
                                  Icons.message,
                                  Colors.purple,
                                ),
                                const SizedBox(width: 8),
                                _buildStatCard(
                                  'Commissions',
                                  '${_details!.stats.commissionsCount}',
                                  Icons.attach_money,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildUserProfile(),
                              _buildPostsTab(),
                              _buildActivityTab(),
                              _buildCommunicationsTab(),
                              _buildCommissionsTab(),
                              _buildWorkingStatusTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
