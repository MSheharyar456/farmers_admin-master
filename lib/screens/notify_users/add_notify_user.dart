import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/services/fcm_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddNotifyUserScreen extends StatefulWidget {
  const AddNotifyUserScreen({super.key});

  @override
  State<AddNotifyUserScreen> createState() => _AddNotifyUserScreenState();
}

class _AddNotifyUserScreenState extends State<AddNotifyUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;
  bool _isLoadingUsers = true;

  // User list data
  List<Map<String, dynamic>> _userList = []; // List of users with userId, userName, userEmail, hasFCMToken
  final Map<String, String> _allUserTokens = {}; // userId -> fcmToken
  String _selectedUserId = 'all_users'; // Default to all users
  String? _selectedUserFCMToken;
  bool _hasFCMToken = false;

  // Manual token entry when user has no FCM token
  final TextEditingController _manualTokenController = TextEditingController();
  String? get _manualFCMToken => _manualTokenController.text.trim().isEmpty
      ? null
      : _manualTokenController.text.trim();

  @override
  void initState() {
    super.initState();
    // Set default to all users
    _selectedUserId = 'all_users';
    _loadUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('usersAuthData')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final usersData = Map<dynamic, dynamic>.from(snapshot.value as Map);
        final List<Map<String, dynamic>> userList = [];
        _allUserTokens.clear();

        usersData.forEach((userId, userData) {
          if (userData is Map) {
            final userName = userData['userName']?.toString() ?? 'Unknown User';
            final userEmail = userData['userMail']?.toString() ?? 'No email';
            final fcmToken = userData['userFCMToken']?.toString();
            final hasToken =
                fcmToken != null &&
                fcmToken.isNotEmpty &&
                FCMService.isValidFCMToken(fcmToken);

            userList.add({
              'userId': userId.toString(),
              'userName': userName,
              'userEmail': userEmail,
              'hasFCMToken': hasToken,
            });

            if (hasToken) {
              _allUserTokens[userId.toString()] = fcmToken;
            }

            debugPrint(
              'User loaded: $userName (ID: $userId) - FCM Token: ${hasToken ? "Available" : "Missing/Invalid"}',
            );
          }
        });

        // Set FCM token status for all users
        if (_allUserTokens.isNotEmpty) {
          _hasFCMToken = true;
          _selectedUserFCMToken = '${_allUserTokens.length} devices ready';
        }

        setState(() {
          _userList = userList;
          _isLoadingUsers = false;
        });
      } else {
        setState(() {
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _fetchUserFCMToken(String userId) async {
    try {
      debugPrint('Fetching FCM token for user: $userId');
      final snapshot = await FirebaseDatabase.instance
          .ref('usersAuthData/$userId/userFCMToken')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final fcmToken = snapshot.value.toString();
        if (FCMService.isValidFCMToken(fcmToken)) {
          setState(() {
            _selectedUserFCMToken = fcmToken;
            _hasFCMToken = true;
          });
          debugPrint(
            'FCM Token found for user $userId: ${fcmToken.length > 50 ? "${fcmToken.substring(0, 50)}..." : fcmToken}',
          );
        } else {
          setState(() {
            _selectedUserFCMToken = null;
            _hasFCMToken = false;
          });
          debugPrint('Invalid FCM Token format for user $userId');
        }
      } else {
        setState(() {
          _selectedUserFCMToken = null;
          _hasFCMToken = false;
        });
        debugPrint('No FCM Token found for user $userId');
      }
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
      setState(() {
        _selectedUserFCMToken = null;
        _hasFCMToken = false;
      });
    }
  }

  Future<void> _saveNotification() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    // Default to all users if not set
    if (_selectedUserId.isEmpty) {
      _selectedUserId = 'all_users';
    }

    // Set loading state immediately after validation to prevent concurrent executions
    setState(() => _isLoading = true);

    try {
      debugPrint('========================================');
      debugPrint('Starting notification save process');
      debugPrint('User ID: $_selectedUserId');
      debugPrint('Title: ${_titleController.text.trim()}');
      debugPrint('Message: ${_messageController.text.trim()}');
      debugPrint('========================================');

      // FCM token already loaded for all users
      // No need to fetch individual token since we're sending to all users

      FCMNotificationResult? fcmResult;
      bool notificationSent = false;

      // Send FCM push notification to ALL users
      debugPrint('Sending FCM push notification to ALL users...');
      int successCount = 0;
      int failureCount = 0;

      final tokens = _allUserTokens.values.toList();
      if (tokens.isEmpty) {
        debugPrint('WARNING: No valid FCM tokens found for any user');
      }

      for (final token in tokens) {
        final result = await FCMService.sendPushNotification(
          fcmToken: token,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          userId: 'all_users',
        );

        if (result.success) {
          successCount++;
        } else {
          failureCount++;
        }
      }

      notificationSent = successCount > 0;
      fcmResult = FCMNotificationResult(
        success: notificationSent,
        message: 'Sent to $successCount users. Failed: $failureCount',
        timestamp: DateTime.now(),
      );

      // Save notification to database
      final dbRef = FirebaseDatabase.instance.ref().child('userNotifications');
      final newNotificationRef = dbRef.push();

      final notificationId = newNotificationRef.key!;
      final notificationDate = DateTime.now().millisecondsSinceEpoch;

      await newNotificationRef
          .set({
        'notificationId': notificationId,
        'notificationTitle': _titleController.text.trim(),
        'notificationMessage': _messageController.text.trim(),
        'userId': _selectedUserId,
        'notificationDate': notificationDate,
        // 'fcmSent': notificationSent,
        // 'fcmSentAt': notificationSent
        //     ? DateTime.now().millisecondsSinceEpoch
        //     : null,
        // 'fcmResult': fcmResult?.message,
        // // CRITICAL: Add this flag to prevent duplicate notifications
        'skipLocalNotification': notificationSent, // Mobile app should check this!

          })
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Connection timeout. Please check your internet connection.',
          );
        },
      );

      debugPrint('Notification saved to database with ID: $notificationId');

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Only navigate back if notification was successfully pushed
      if (notificationSent) {
        // Success: show success snackbar, then navigate back (snackbar will auto-close)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Notification saved and pushed successfully to user device!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        debugPrint(
          'SUCCESS: Notification sent successfully via FCM and saved in database',
        );
        // Wait for snackbar to show, then navigate back (snackbar will close automatically)
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context, true);
        }

      } else {
        // Failure: show error snackbar, stay on screen
        String errorMessage;
        if (_hasFCMToken) {
          errorMessage =
              'Notification saved, but push notification failed.\nReason: ${fcmResult.message ?? "Unknown error"}';
          debugPrint('WARNING: Notification saved but FCM push failed');
        } else {
          errorMessage =
              'Notification saved in database.\nNote: User FCM token not available, push notification not sent.';
          debugPrint('INFO: Notification saved but no FCM token available');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveNotification,
            ),
          ),
        );
        // NO navigation here - user stays on screen to retry
      }
    } catch (e) {
      setState(() => _isLoading = false);

      if (!mounted) return;

      String errorMessage = "Failed to save notification. ";

      if (e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage += "Please check your internet connection and try again.";
      } else if (e.toString().contains('permission')) {
        errorMessage += "You don't have permission to add notifications.";
      } else {
        errorMessage += "Please try again later.";
      }

      debugPrint('ERROR: $errorMessage');
      debugPrint('Exception: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _saveNotification,
          ),
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          style: const TextStyle(fontSize: 12),
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserListView() {
    if (_isLoadingUsers) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Center(
          child: Text(
            'No users available',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider before user list
        const Divider(
          color: Colors.grey,
          height: 1,
        ),
        const SizedBox(height: 16),
        // Header
        Row(
          children: [
            Icon(
              Icons.people,
              color: Colors.green.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'All Users (${_userList.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // User List
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: _userList.length,
            itemBuilder: (context, index) {
              final user = _userList[index];
              final hasToken = user['hasFCMToken'] as bool;
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tick mark icon
                    Icon(
                      hasToken ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: hasToken ? Colors.green : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 10),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['userName'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user['userEmail'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SideMenu(),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppHeader(),
                    Container(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          // Header Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.arrow_back,
                                          color: Colors.black,
                                        ),
                                        onPressed: _isLoading
                                            ? null
                                            : () => Navigator.pop(context),
                                      ),
                                      Text(
                                        'Add Notification',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dashboard / Notify Users List / Add Notification',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                          fontWeight: FontWeight.normal,
                                          fontFamily: 'Roboto',
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Main Content Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Side - Form (65%)
                              Expanded(
                                flex: 65,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5),
                                    color: Colors.white,
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildTextField(
                                          label: 'Notification Title*',
                                          controller: _titleController,
                                          hintText:
                                              'Enter notification title...',
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please enter notification title';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        _buildTextField(
                                          label: 'Notification Message*',
                                          controller: _messageController,
                                          maxLines: 4,
                                          hintText:
                                              'Enter notification message...',
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please enter notification message';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 32),

                                        // Action Buttons
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SizedBox(
                                                height: 38,
                                                child: OutlinedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : () => Navigator.pop(
                                                          context,
                                                        ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 5,
                                                        ),
                                                    side: BorderSide(
                                                      color: Colors.grey[400]!,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'CANCEL',
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: SizedBox(
                                                height: 38,
                                                child: ElevatedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _saveNotification,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 5,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child: _isLoading
                                                      ? const SizedBox(
                                                          height: 15,
                                                          width: 15,
                                                          child:
                                                              CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                      : const Text(
                                                          'SAVE NOTIFICATION',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Right Side - Info Card (35%)
                              Expanded(
                                flex: 35,
                                child: Builder(
                                  builder: (context) {
                              final hasToken =
                                  _hasFCMToken &&
                                  _selectedUserFCMToken != null;
                              final isAllUsers =
                                  _selectedUserId == 'all_users';

                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header with FCM Status
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: hasToken
                                                      ? Colors.green.shade50
                                                      : Colors.orange.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  hasToken
                                                      ? Icons
                                                            .check_circle_outline
                                                      : Icons.error_outline,
                                                  color: hasToken
                                                      ? Colors.green.shade700
                                                      : Colors.orange.shade700,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  hasToken
                                                      ? (isAllUsers
                                                            ? 'Ready to Broadcast'
                                                            : 'FCM Token Available')
                                                      : 'No FCM Token',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: hasToken
                                                        ? Colors.green.shade900
                                                        : Colors
                                                              .orange
                                                              .shade900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 20),

                                          // Divider
                                          Divider(
                                            color: Colors.grey.shade200,
                                            height: 1,
                                          ),
                                          const SizedBox(height: 20),

                                          // User Info
                                          _buildInfoRow(
                                            icon: Icons.people,
                                            label: 'Recipients',
                                            value: 'All Users (${_userList.length})',
                                          ),



                                          const SizedBox(height: 20),

                                          // FCM Token Status Box
                                          Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: hasToken
                                                    ? Colors.green.shade50
                                                    : Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: hasToken
                                                      ? Colors.green.shade200
                                                      : Colors.orange.shade200,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        hasToken
                                                            ? Icons
                                                                  .notifications_active
                                                            : Icons
                                                                  .notifications_off,
                                                        color: hasToken
                                                            ? Colors
                                                                  .green
                                                                  .shade700
                                                            : Colors
                                                                  .orange
                                                                  .shade700,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          hasToken
                                                              ? 'Push Notification Ready'
                                                              : 'Push Notification Unavailable',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: hasToken
                                                                ? Colors
                                                                      .green
                                                                      .shade900
                                                                : Colors
                                                                      .orange
                                                                      .shade900,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (hasToken &&
                                                      _selectedUserFCMToken !=
                                                          null) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      isAllUsers
                                                          ? 'Recipients:'
                                                          : 'Token:',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    SelectableText(
                                                      _selectedUserFCMToken!,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black87,
                                                        fontFamily:
                                                            'RobotoMono',
                                                        fontWeight: isAllUsers
                                                            ? FontWeight.bold
                                                            : FontWeight.normal,
                                                      ),
                                                    ),
                                                  ] else if (!hasToken) ...[
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'User must login to the app to receive push notifications.',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .orange
                                                            .shade800,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          const SizedBox(height: 20),
                                          // User List
                                          //_buildUserListView(),
                                        ],
                                      ),
                                    );
                                  },
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
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: valueColor ?? Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFCMTokenStatus() {
    final hasToken = _hasFCMToken && _selectedUserFCMToken != null;

    final isAllUsers = _selectedUserId == 'all_users';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasToken ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasToken ? Colors.green.shade200 : Colors.orange.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Icon(
                hasToken ? Icons.check_circle : Icons.warning_amber_rounded,
                color: hasToken ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasToken
                      ? (isAllUsers
                            ? 'Ready to Broadcast'
                            : 'FCM Token Available')
                      : 'FCM Token Not Available',
                  style: TextStyle(
                    fontSize: 14,
                    color: hasToken
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          if (hasToken) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Instructions
            if (!isAllUsers)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Copy the FCM token below and use it in Firebase Console to send the notification',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // FCM Token Display
            Text(
              isAllUsers ? 'Recipients:' : 'FCM Token:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _selectedUserFCMToken!,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.grey.shade800,
                        fontWeight: isAllUsers
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (!isAllUsers) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy FCM Token',
                      onPressed: () async {
                        // Copy to clipboard
                        await Clipboard.setData(
                          ClipboardData(text: _selectedUserFCMToken!),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ FCM Token copied to clipboard!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },

                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green.shade50,
                        foregroundColor: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (!isAllUsers) ...[
              const SizedBox(height: 12),

              // Firebase Console Link
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.open_in_new,
                      color: Colors.purple.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Send via Firebase Console → Messaging → New Campaign → Test Message',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.purple.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'This user has not logged into the mobile app or has not granted notification permissions.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade900,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _manualTokenController,
            decoration: const InputDecoration(
              labelText: 'Manual FCM Token (optional)',
              hintText: 'Enter FCM token manually to override or if missing',
              border: OutlineInputBorder(),
              helperText:
                  'If provided, this token will be used instead of the stored one.',
              helperMaxLines: 2,
            ),
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            minLines: 1,
          ),
        ],
      ),
    );
  }
}

