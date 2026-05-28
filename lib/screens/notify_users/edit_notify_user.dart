import 'package:dio/dio.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/models/user_notification_model.dart';
import 'package:farmers_admin/services/admin_notification_service.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  String? _selectedUserId;

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
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final authService = Provider.of<AdminServerAuthService>(context, listen: false);
      final token = authService.authToken;
      
      if (token == null || token.isEmpty) {
        debugPrint('Error: No auth token available');
        setState(() => _isLoadingUsers = false);
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.get(
        '/admin/users',
        queryParameters: {'limit': 500},
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'X-Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> usersData = response.data['users'] ?? [];
        final Map<String, String> usersMap = {};

        for (final userData in usersData) {
          final userId = userData['id']?.toString() ?? '';
          final userName = userData['username']?.toString() ?? 'Unknown User';

          if (userId.isNotEmpty) {
            debugPrint('=== LOADING USER FROM SERVER ===');
            debugPrint('User ID: $userId');
            debugPrint('User Name: $userName');
            usersMap[userId] = userName;
          }
        }

        // Add "All Users" option if there are users
        if (usersMap.isNotEmpty) {
          usersMap['all_users'] = 'All Users (${usersMap.length})';
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
          _selectedUserId = selectedId;
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

  Future<void> _updateNotification() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) return;

    // Fix: Check if form key is valid before accessing currentState
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserId == null || _selectedUserId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user'),
          backgroundColor: Colors.orange,
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
      debugPrint('User ID: $_selectedUserId');
      debugPrint('Selected User Name: ${_userNameController.text}');
      debugPrint('Title: ${_titleController.text.trim()}');
      debugPrint('Message: ${_messageController.text.trim()}');
      debugPrint('========================================');

      // Get auth token from the provider
      final authService = Provider.of<AdminServerAuthService>(context, listen: false);
      final authToken = authService.authToken;
      
      if (authToken == null || authToken.isEmpty) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error: Please login again'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Send notification via server API (Socket.IO + MySQL)
      final result = await AdminNotificationService.sendNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        userId: _selectedUserId == 'all_users' ? null : _selectedUserId,
        authToken: authToken,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Success
        final successMessage = isAddMode
            ? 'Notification sent successfully via Socket.IO!'
            : 'Notification updated successfully!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        debugPrint('SUCCESS: Notification sent via server API');
        
        // Wait for snackbar to show, then navigate back
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        // Server returned error
        final errorMsg = result['message'] ?? 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification: $errorMsg'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _updateNotification,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      String errorMessage = "Failed to send notification. ";
      if (e.toString().contains('timeout') ||
          e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage += "Please check your internet connection.";
      } else if (e.toString().contains('permission')) {
        errorMessage += "You don't have permission to send notifications.";
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
                                          // Header with Socket.IO Status
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.online_prediction,
                                                  color: Colors.blue.shade700,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'Socket.IO Ready',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blue.shade900,
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

                                          // Socket.IO Status Box
                                          if (_selectedUserId != null)
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.blue.shade200,
                                                ),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.notifications_active,
                                                        color: Colors.blue.shade700,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          isAllUsers
                                                              ? 'Broadcast Mode'
                                                              : 'Real-time Delivery',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.blue.shade900,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    isAllUsers
                                                        ? 'Notification will be sent to all connected users via Socket.IO broadcast.'
                                                        : 'Notification will be delivered instantly via Socket.IO when user is online.',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.blue.shade800,
                                                      height: 1.3,
                                                    ),
                                                  ),
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
}
