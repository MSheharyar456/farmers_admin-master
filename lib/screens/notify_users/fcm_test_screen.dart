import 'package:dio/dio.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/services/fcm_service.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FCMTestScreen extends StatefulWidget {
  const FCMTestScreen({super.key});

  @override
  State<FCMTestScreen> createState() => _FCMTestScreenState();
}

class _FCMTestScreenState extends State<FCMTestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _userNameController = TextEditingController();
  final _userEmailController = TextEditingController();
  final _manualTokenController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingUsers = true;

  // List of test users loaded from VPS backend
  List<Map<String, dynamic>> _testUsers = [];
  String? _selectedUserId;
  String? _selectedUserFCMToken;

  @override
  void initState() {
    super.initState();
    _loadTestUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userNameController.dispose();
    _userEmailController.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadTestUsers() async {
    try {
      final authService = Provider.of<AdminServerAuthService>(context, listen: false);
      final token = authService.authToken;

      if (token == null || token.isEmpty) {
        debugPrint('Error: No auth token available for test users');
        setState(() => _isLoadingUsers = false);
        return;
      }

      final dio = Dio(BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final response = await dio.get(
        '/admin/test-users',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'X-Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> usersData = response.data['users'] ?? [];
        final List<Map<String, dynamic>> usersList = [];

        for (final u in usersData) {
          usersList.add({
            'id': u['id']?.toString() ?? '',
            'username': u['username']?.toString() ?? 'Unknown User',
            'email': u['email']?.toString() ?? '',
            'fcmToken': u['fcmToken']?.toString() ?? '',
          });
        }

        setState(() {
          _testUsers = usersList;
          _isLoadingUsers = false;
        });
      } else {
        setState(() => _isLoadingUsers = false);
      }
    } catch (e) {
      debugPrint('Error loading test users: $e');
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _sendTestNotification() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    final tokenToUse = _manualTokenController.text.trim().isNotEmpty
        ? _manualTokenController.text.trim()
        : _selectedUserFCMToken;

    if (tokenToUse == null || tokenToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user with an FCM token or enter a manual token.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();
      final userId = _selectedUserId ?? 'manual_testing';

      debugPrint('=== SENDING DIRECT FCM PUSH FOR TESTING ===');
      debugPrint('Target Token: $tokenToUse');
      debugPrint('Title: $title');
      debugPrint('Message: $message');
      debugPrint('============================================');

      final authService = Provider.of<AdminServerAuthService>(context, listen: false);

      // Invoke FCM sending via the backend proxy
      final fcmResult = await FCMService.sendPushNotification(
        fcmToken: tokenToUse,
        title: title,
        message: message,
        userId: userId,
        adminToken: authService.authToken ?? '',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (fcmResult.success) {
        _showResultDialog(
          title: 'Direct FCM Push Sent!',
          message: fcmResult.message,
          isSuccess: true,
          details: fcmResult.responseData?.toString(),
        );
      } else {
        _showResultDialog(
          title: 'Direct FCM Push Failed',
          message: fcmResult.message,
          isSuccess: false,
          details: fcmResult.errorDetails,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;

      _showResultDialog(
        title: 'Error Triggering Push',
        message: e.toString(),
        isSuccess: false,
      );
    }
  }

  void _showResultDialog({
    required String title,
    required String message,
    required bool isSuccess,
    String? details,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              if (details != null && details.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Response/Error Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    details,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
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
          style: const TextStyle(fontSize: 12, color: Colors.black),
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: !_isLoading && !readOnly,
          decoration: InputDecoration(
            hintText: hintText,
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
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FCM Notification Testing',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dashboard / Notify Users List / Test FCM',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey,
                                fontSize: 10,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.normal,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Main Form Content Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form (75%)
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                label: 'Notification Title*',
                                controller: _titleController,
                                hintText: 'Enter test title...',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
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
                                hintText: 'Enter test message...',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter notification message';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // User Selector Dropdown
                              const Text(
                                'Select Test User*',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _isLoadingUsers
                                  ? Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                                        ),
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: _selectedUserId,
                                      onChanged: _isLoading
                                          ? null
                                          : (String? newValue) {
                                              if (newValue != null) {
                                                final u = _testUsers.firstWhere((x) => x['id'] == newValue);
                                                setState(() {
                                                  _selectedUserId = newValue;
                                                  _selectedUserFCMToken = u['fcmToken'];
                                                  _userNameController.text = u['username'];
                                                  _userEmailController.text = u['email'];
                                                });
                                              }
                                            },
                                      items: _testUsers.map<DropdownMenuItem<String>>((user) {
                                        return DropdownMenuItem<String>(
                                          value: user['id'],
                                          child: Text(
                                            '${user['username']} (${user['email']})',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.grey[50],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(5),
                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                      ),
                                      hint: const Text('Select a test user...', style: TextStyle(fontSize: 12)),
                                    ),
                              const SizedBox(height: 20),

                              // Read-only info fields
                              Row(
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
                              const SizedBox(height: 20),

                              // Manual token input / override
                              _buildTextField(
                                label: 'Manual FCM Token Override (Optional)',
                                controller: _manualTokenController,
                                hintText: 'Paste direct FCM token here to bypass selected user token...',
                              ),
                              const SizedBox(height: 32),

                              // Send button
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: OutlinedButton(
                                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.grey[400]!),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                        ),
                                        child: const Text(
                                          'BACK',
                                          style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _sendTestNotification,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange.shade700,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                height: 15,
                                                width: 15,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text(
                                                'SEND TEST FCM PUSH',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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

                    // Info Card (25%)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.bug_report, color: Colors.orange.shade700, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'FCM Test Mode',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'How to Test:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. Register a user in the companion FCM Test App.\n'
                              '2. Select them in the dropdown.\n'
                              '3. Write a title and message.\n'
                              '4. Click "Send Test FCM Push" to trigger a direct delivery check.',
                              style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.5),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Direct Connection Check',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'This bypasses general queueing and contacts Google servers directly. You will see precise API responses.',
                                    style: TextStyle(fontSize: 10, color: Colors.black87, height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
    );
  }
}
