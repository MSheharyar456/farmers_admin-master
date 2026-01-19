import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/user_notification_model.dart';
import 'package:farmers_admin/services/fcm_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class EditNotifyUserScreen extends StatefulWidget {
  final UserNotification? notification;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userFCMToken;

  const EditNotifyUserScreen({
    super.key,
    this.notification,
    this.userId,
    this.userName,
    this.userEmail,
    this.userFCMToken,
  });

  bool get isAddMode => notification == null;

  @override
  State<EditNotifyUserScreen> createState() => _EditNotifyUserScreenState();
}

class _EditNotifyUserScreenState extends State<EditNotifyUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _messageController;
  late TextEditingController _userNameController;
  late TextEditingController _userEmailController;
  bool _isLoading = false;
  bool _isLoadingUsers = true;

  // User dropdown data
  Map<String, String> _users = {}; // userId -> userName
  Map<String, bool> _userFCMTokenStatus = {}; // userId -> hasFCMToken
  final Map<String, String> _allUserTokens = {}; // userId -> fcmToken
  String? _selectedUserId;
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

    // Initialize controllers based on mode
    if (widget.isAddMode) {
      _titleController = TextEditingController();
      _messageController = TextEditingController();
      _userNameController = TextEditingController(text: widget.userName ?? '');
      _userEmailController = TextEditingController(
        text: widget.userEmail ?? '',
      );
    } else {
      _titleController = TextEditingController(
        text: widget.notification!.notificationTitle,
      );
      _messageController = TextEditingController(
        text: widget.notification!.notificationMessage,
      );
      _userNameController = TextEditingController();
      _userEmailController = TextEditingController();
    }

    _loadUsers();
  }

  @override
  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
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
        final Map<String, String> usersMap = {};
        final Map<String, bool> fcmTokenStatusMap = {};

        usersData.forEach((userId, userData) {
          if (userData is Map) {
            final userName = userData['userName']?.toString() ?? 'Unknown User';
            final fcmToken = userData['userFCMToken']?.toString();
            final hasToken =
                fcmToken != null &&
                fcmToken.isNotEmpty &&
                FCMService.isValidFCMToken(fcmToken);

            // FIXED: Use userId directly (it's already the uid from Firebase)
            final userIdString = userId.toString();
            debugPrint('=== LOADING USER ===');
            debugPrint('Raw userId from Firebase: $userId');
            debugPrint('Converted userId string: $userIdString');
            debugPrint('userId runtimeType: ${userId.runtimeType}');
            usersMap[userIdString] = userName;
            fcmTokenStatusMap[userIdString] = hasToken;

            if (hasToken) {
              _allUserTokens[userIdString] = fcmToken;
            }

            debugPrint(
              'User loaded: $userName (User ID: $userIdString) - FCM Token: ${hasToken ? "Available" : "Missing/Invalid"}',
            );
          }
        });

        // Add "All Users" option if there are users
        if (usersMap.isNotEmpty) {
          usersMap['all_users'] = 'All Users (${usersMap.length})';
          fcmTokenStatusMap['all_users'] = _allUserTokens.isNotEmpty;
        }

        // Set the selected user ID based on mode
        String? selectedId;
        if (widget.isAddMode) {
          // In add mode, use the passed userId if provided
          if (widget.userId != null && widget.userId!.isNotEmpty) {
            selectedId = widget.userId;
            debugPrint('=== ADD MODE INIT ===');
            debugPrint('widget.userId: ${widget.userId}');
            debugPrint('selectedId set to: $selectedId');
            // If FCM token was passed, set it directly
            if (widget.userFCMToken != null &&
                FCMService.isValidFCMToken(widget.userFCMToken!)) {
              _allUserTokens[widget.userId!] = widget.userFCMToken!;
            }
          }
        } else {
          // In edit mode, use the notification's userId
          final notificationUserId = widget.notification!.userId;
          debugPrint('=== EDIT MODE INIT ===');
          debugPrint('notification userId: $notificationUserId');
          debugPrint('usersMap keys: ${usersMap.keys.toList()}');
          selectedId = usersMap.containsKey(notificationUserId)
              ? notificationUserId
              : null;
          debugPrint('selectedId set to: $selectedId');
        }

        // Update user name and email in edit mode if not already set
        if (!widget.isAddMode && selectedId != null) {
          if (_userNameController.text.isEmpty &&
              usersMap.containsKey(selectedId)) {
            _userNameController.text = usersMap[selectedId] ?? '';
          }
        }

        setState(() {
          _users = usersMap;
          _userFCMTokenStatus = fcmTokenStatusMap;
          _selectedUserId = selectedId;
          _isLoadingUsers = false;
        });

        if (selectedId != null) {
          if (widget.isAddMode &&
              widget.userFCMToken != null &&
              FCMService.isValidFCMToken(widget.userFCMToken!)) {
            // Use the passed FCM token directly
            setState(() {
              _selectedUserFCMToken = widget.userFCMToken;
              _hasFCMToken = true;
            });
          } else {
            _fetchUserFCMToken(selectedId);
          }
        }
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
          debugPrint('FCM Token found for user $userId');
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

  Future<void> _updateNotification() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // Set loading state immediately after validation to prevent concurrent executions
    setState(() => _isLoading = true);

    try {
      final isAddMode = widget.isAddMode;
      debugPrint('========================================');
      debugPrint(
        isAddMode
            ? 'Starting notification creation process'
            : 'Starting notification update process',
      );
      if (!isAddMode) {
        debugPrint('Notification ID: ${widget.notification!.notificationId}');
      }
      debugPrint('User ID: $_selectedUserId');
      debugPrint('User ID Type: ${_selectedUserId.runtimeType}');
      debugPrint('User ID Length: ${_selectedUserId?.length ?? 0}');
      debugPrint('Selected User Name: ${_userNameController.text}');
      debugPrint('Users Map Keys: ${_users.keys.toList()}');
      debugPrint('Title: ${_titleController.text.trim()}');
      debugPrint('Message: ${_messageController.text.trim()}');
      debugPrint('========================================');

      // DON'T fetch FCM token again - we already have it from dropdown selection!
      // Token is fetched automatically when user selects from dropdown

      FCMNotificationResult? fcmResult;
      bool notificationSent = false;

      // Send FCM push notification
      if (_selectedUserId == 'all_users') {
        // Send to ALL users
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
      } else if ((_hasFCMToken && _selectedUserFCMToken != null) ||
          _manualFCMToken != null) {
        final tokenToUse = _manualFCMToken ?? _selectedUserFCMToken!;
        debugPrint(
          'Sending FCM push notification using ${_manualFCMToken != null ? 'manual' : 'stored'} token...',
        );

        fcmResult = await FCMService.sendPushNotification(
          fcmToken: tokenToUse,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          userId: _selectedUserId!,
        );

        notificationSent = fcmResult.success;
        debugPrint('FCM Notification Result: ${fcmResult.message}');
      } else {
        debugPrint(
          'WARNING: Cannot send FCM push notification - FCM token not available for selected user',
        );
        debugPrint(
          'Notification will be ${isAddMode ? "saved" : "updated"} in database only',
        );
      }

      // Save notification in database
      final dbRef = FirebaseDatabase.instance.ref().child('userNotifications');
      String notificationId;

      if (isAddMode) {
        // Create new notification
        final newNotificationRef = dbRef.push();
        notificationId = newNotificationRef.key ?? '';

        debugPrint('BEFORE SAVE - _selectedUserId: $_selectedUserId');
        debugPrint(
          'BEFORE SAVE - _selectedUserId is null: ${_selectedUserId == null}',
        );
        debugPrint(
          'BEFORE SAVE - _selectedUserId isEmpty: ${_selectedUserId?.isEmpty ?? 'N/A'}',
        );
        final newData = {
          'notificationId': notificationId,
          'notificationTitle': _titleController.text.trim(),
          'notificationMessage': _messageController.text.trim(),
          'userId': _selectedUserId!,
          'notificationDate': DateTime.now().millisecondsSinceEpoch,
          // 'fcmSent': notificationSent,
          // 'fcmSentAt': notificationSent ? DateTime.now().millisecondsSinceEpoch : null,
          // 'fcmResult': fcmResult?.message,
          // // CRITICAL: Prevent duplicate notifications in mobile app
          'skipLocalNotification': notificationSent,
        };

        await newNotificationRef
            .set(newData)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception(
                  'Connection timeout. Please check your internet connection.',
                );
              },
            );

        debugPrint('Notification created in database with ID: $notificationId');
        debugPrint('SAVED DATA - userId field: ${newData['userId']}');
      } else {
        // Update existing notification
        notificationId = widget.notification!.notificationId;
        final notificationRef = dbRef.child(notificationId);

        debugPrint('BEFORE UPDATE - _selectedUserId: $_selectedUserId');
        debugPrint(
          'BEFORE UPDATE - _selectedUserId is null: ${_selectedUserId == null}',
        );
        final updatedData = {
          'notificationTitle': _titleController.text.trim(),
          'notificationMessage': _messageController.text.trim(),
          'userId': _selectedUserId!,
          'notificationDate': DateTime.now().millisecondsSinceEpoch,
          'notificationId': notificationId,
          // 'fcmSent': notificationSent,
          // 'fcmSentAt': notificationSent ? DateTime.now().millisecondsSinceEpoch : null,
          // 'fcmResult': fcmResult?.message,
          // // CRITICAL: Prevent duplicate notifications in mobile app
          // 'skipLocalNotification': notificationSent,
        };

        await notificationRef
            .update(updatedData)
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception(
                  'Connection timeout. Please check your internet connection.',
                );
              },
            );

        debugPrint('Notification updated in database with ID: $notificationId');
        debugPrint('SAVED DATA - userId field: ${updatedData['userId']}');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Only navigate back if notification was successfully pushed
      if (notificationSent) {
        // Success: show success snackbar, then navigate back (snackbar will auto-close)
        final successMessage = isAddMode
            ? 'Notification created and pushed successfully to user device!'
            : 'Notification updated and pushed successfully to user device!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        debugPrint(
          'SUCCESS: Notification ${isAddMode ? "created" : "sent"} successfully via FCM and ${isAddMode ? "saved" : "updated"} in database',
        );
        // Wait for snackbar to show, then navigate back (snackbar will close automatically)
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // Failure: show error snackbar, stay on screen
        String errorMessage;
        if (_hasFCMToken || _manualFCMToken != null) {
          errorMessage = isAddMode
              ? 'Notification created, but push notification failed.\nReason: ${fcmResult?.message ?? "Unknown error"}'
              : 'Notification updated, but push notification failed.\nReason: ${fcmResult?.message ?? "Unknown error"}';
          debugPrint(
            'WARNING: Notification ${isAddMode ? "created" : "updated"} but FCM push failed',
          );
        } else {
          errorMessage = isAddMode
              ? 'Notification created in database.\nNote: User FCM token not available, push notification not sent.'
              : 'Notification updated in database.\nNote: User FCM token not available, push notification not sent.';
          debugPrint(
            'INFO: Notification ${isAddMode ? "created" : "updated"} but no FCM token available',
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _updateNotification,
            ),
          ),
        );
        // NO navigation here - user stays on screen to retry
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      final isAddMode = widget.isAddMode;
      String errorMessage = isAddMode
          ? "Failed to create notification. "
          : "Failed to update notification. ";
      if (e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage += "Please check your internet connection and try again.";
      } else if (e.toString().contains('permission')) {
        errorMessage += isAddMode
            ? "You don't have permission to create this notification."
            : "You don't have permission to update this notification.";
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
            onPressed: _updateNotification,
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
    bool readOnly = false,
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
          style: const TextStyle(fontSize: 12, color: Colors.black),
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: !_isLoading && !readOnly,
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
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
                                        widget.isAddMode
                                            ? 'Add Notification'
                                            : 'Edit Notification',
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
                                    widget.isAddMode
                                        ? 'Dashboard / Users List / Add Notification'
                                        : 'Dashboard / Notify Users List / Edit Notification',
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
                              // Left Side - Form (75%)
                              Expanded(
                                flex: 3,
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
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please enter notification message';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                        _buildUserInfoFields(),
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
                                                      : _updateNotification,
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
                                                      : Text(
                                                          widget.isAddMode
                                                              ? 'ADD NOTIFICATION'
                                                              : 'SAVE CHANGES',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
                              // Right Side - Info Card (25%)
                              Builder(
                                builder: (context) {
                                  final hasToken =
                                      _hasFCMToken &&
                                      _selectedUserFCMToken != null;
                                  final isAllUsers =
                                      _selectedUserId == 'all_users';

                                  return Expanded(
                                    flex: 1,
                                    child: Container(
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

                                          // User ID
                                          if (_selectedUserId != null) ...[
                                            _buildInfoRow(
                                              icon: Icons.person,
                                              label: 'User ID',
                                              value: _selectedUserId!,
                                            ),
                                            const SizedBox(height: 16),
                                          ],

                                          // Notification ID (only in edit mode)
                                          if (!widget.isAddMode) ...[
                                            _buildInfoRow(
                                              icon: Icons.tag,
                                              label: 'Notification ID',
                                              value: widget
                                                  .notification!
                                                  .notificationId,
                                            ),
                                            const SizedBox(height: 20),
                                          ],

                                          // FCM Token Status Box
                                          if (_selectedUserId != null)
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
                                        ],
                                      ),
                                    ),
                                  );
                                },
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

  Widget _buildUserInfoFields() {
    // Update controllers when selected user changes
    if (_selectedUserId != null && _selectedUserId != 'all_users') {
      final userName = _users[_selectedUserId];
      if (userName != null && _userNameController.text != userName) {
        _userNameController.text = userName;
      }
    } else if (_selectedUserId == 'all_users') {
      if (_userNameController.text != 'All Users') {
        _userNameController.text = 'All Users (${_users.length - 1})';
      }
    }

    // Ensure controllers have values or placeholders
    if (_userNameController.text.isEmpty) {
      _userNameController.text = widget.userName ?? 'N/A';
    }
    if (_userEmailController.text.isEmpty) {
      _userEmailController.text = widget.userEmail ?? 'N/A';
    }

    // Build list of dropdown items with proper labels
    List<DropdownMenuItem<String>> userDropdownItems = [];

    // Add "All Users" option
    if (_users.containsKey('all_users')) {
      userDropdownItems.add(
        DropdownMenuItem(
          value: 'all_users',
          child: const Text(
            'All Users (Broadcast)',
            style: TextStyle(fontSize: 12),
          ),
        ),
      );
    }

    // Add individual users (skip 'all_users' key)
    _users.forEach((userId, userName) {
      if (userId != 'all_users') {
        userDropdownItems.add(
          DropdownMenuItem(
            value: userId,
            child: Text(userName, style: const TextStyle(fontSize: 12)),
          ),
        );
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // // User Selector Dropdown
        // Column(
        //   crossAxisAlignment: CrossAxisAlignment.start,
        //   children: [
        //     const Text(
        //       'Select User*',
        //       style: TextStyle(
        //         fontSize: 12,
        //         fontWeight: FontWeight.w500,
        //         color: Colors.black,
        //       ),
        //     ),
        //     const SizedBox(height: 8),
        //     _isLoadingUsers
        //         ? Container(
        //             height: 38,
        //             decoration: BoxDecoration(
        //               color: Colors.grey[100],
        //               border: Border.all(color: Colors.grey[300]!),
        //               borderRadius: BorderRadius.circular(5),
        //             ),
        //             child: const Center(
        //               child: SizedBox(
        //                 height: 20,
        //                 width: 20,
        //                 child: CircularProgressIndicator(strokeWidth: 2),
        //               ),
        //             ),
        //           )
        //         : SizedBox(
        //             height: 38,
        //             child: DropdownButtonFormField<String>(
        //               value: _selectedUserId,
        //               onChanged: _isLoading
        //                   ? null
        //                   : (String? newValue) {
        //                       if (newValue != null && newValue != _selectedUserId) {
        //                         debugPrint('=== USER SELECTION CHANGED ===');
        //                         debugPrint('Previous _selectedUserId: $_selectedUserId');
        //                         debugPrint('New value selected: $newValue');
        //                         debugPrint('New value type: ${newValue.runtimeType}');
        //                         debugPrint('New value length: ${newValue.length}');
        //                         setState(() {
        //                           _selectedUserId = newValue;
        //                           _manualTokenController.clear();
        //                         });
        //                         // Fetch FCM token for selected user
        //                         if (newValue != 'all_users') {
        //                           _fetchUserFCMToken(newValue);
        //                         } else {
        //                           // For all users, show count
        //                           setState(() {
        //                             _selectedUserFCMToken = '${_allUserTokens.length} devices ready';
        //                             _hasFCMToken = _allUserTokens.isNotEmpty;
        //                           });
        //                         }
        //                       }
        //                     },
        //               items: userDropdownItems,
        //               decoration: InputDecoration(
        //                 filled: true,
        //                 fillColor: Colors.grey[50],
        //                 border: OutlineInputBorder(
        //                   borderRadius: BorderRadius.circular(5),
        //                   borderSide: BorderSide(color: Colors.grey[300]!),
        //                 ),
        //                 enabledBorder: OutlineInputBorder(
        //                   borderRadius: BorderRadius.circular(5),
        //                   borderSide: BorderSide(color: Colors.grey[300]!),
        //                 ),
        //                 focusedBorder: const OutlineInputBorder(
        //                   borderSide: BorderSide(color: Colors.green, width: 2),
        //                 ),
        //                 contentPadding: const EdgeInsets.symmetric(
        //                   horizontal: 12,
        //                   vertical: 0,
        //                 ),
        //               ),
        //               validator: (value) {
        //                 if (value == null || value.isEmpty) {
        //                   return 'Please select a user';
        //                 }
        //                 return null;
        //               },
        //               hint: const Text('Select a user...'),
        //             ),
        //           ),
        //   ],
        // ),
        // const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'User Name',
                controller: _userNameController,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTextField(
                label: 'User Email',
                controller: _userEmailController,
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFCMTokenStatus() {
    if (_selectedUserId == null) return const SizedBox.shrink();

    final hasToken = _hasFCMToken && _selectedUserFCMToken != null;
    final isAllUsers = _selectedUserId == 'all_users';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasToken ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: hasToken ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasToken ? Icons.check_circle_outline : Icons.error_outline,
                color: hasToken
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasToken
                          ? (isAllUsers
                                ? 'Ready to Broadcast'
                                : 'FCM Token Available')
                          : 'FCM Token Not Available',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: hasToken
                            ? Colors.green.shade900
                            : Colors.orange.shade900,
                      ),
                    ),
                    if (hasToken) ...[
                      const SizedBox(height: 6),
                      Text(
                        isAllUsers ? 'Recipients:' : 'Token:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SelectableText(
                        _selectedUserFCMToken!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          fontFamily: 'RobotoMono',
                          fontWeight: isAllUsers
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'A push notification will not be sent to this user unless a manual token is provided.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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
