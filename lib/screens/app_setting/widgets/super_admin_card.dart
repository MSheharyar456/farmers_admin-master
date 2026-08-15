import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';

class SuperAdminCard extends StatefulWidget {
  final ValueChanged<bool>? onLoadingChanged;

  const SuperAdminCard({super.key, this.onLoadingChanged});

  @override
  State<SuperAdminCard> createState() => _SuperAdminCardState();
}

class _SuperAdminCardState extends State<SuperAdminCard> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _optionkeyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  bool _showPassword = false;
  bool _showPasskey = false;
  bool _showOptionkey = false;

  String? _uid;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _fetchAdminDataWithRetry();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAdminDataWithRetry() async {
    int attempts = 0;
    const maxAttempts = 20;

    _retryTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      attempts++;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userEmail = prefs.getString('user_email');
      final userName = prefs.getString('user_name');

      debugPrint(
        "SuperAdminCard: Attempt $attempts - user_id=$userId, email=$userEmail, name=$userName",
      );

      if (userId != null && userId.isNotEmpty) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _uid = userId;
            _emailController.text = userEmail ?? '';
            _usernameController.text = userName ?? '';
            _isLoading = false;
          });
        }
        widget.onLoadingChanged?.call(false);
        return;
      }

      if (attempts >= maxAttempts) {
        timer.cancel();
        if (mounted) {
          setState(() => _isLoading = false);
        }
        widget.onLoadingChanged?.call(false);
      }
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uid == null) return;

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AdminServerAuthService>(context, listen: false);
      final token = authService.authToken;

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final Map<String, dynamic> updates = {
        "username": _usernameController.text.trim(),
      };

      if (_passkeyController.text.isNotEmpty) {
        updates["passkey"] = _passkeyController.text.trim();
      }

      if (_optionkeyController.text.isNotEmpty) {
        updates["optionkey"] = _optionkeyController.text.trim();
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['X-Authorization'] = 'Bearer $token';
            return handler.next(options);
          },
        ),
      );

      final res = await dio.patch('/admin/me', data: updates);

      if (res.data == null || res.data['success'] != true) {
        final msg = res.data?['message'] as String? ?? 'Update failed';
        throw Exception(msg);
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _usernameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _passwordController.clear();
        _passkeyController.clear();
        _optionkeyController.clear();
      }
    } on DioException catch (e) {
      final resp = e.response?.data;
      final msg = resp is Map ? resp['message'] as String? : null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg ?? e.message ?? 'Update failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Super Admin Profile",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  "Username",
                  _usernameController,
                  Icons.person,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "Gmail",
                  _emailController,
                  Icons.email,
                  enabled: false,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "New Passkey",
                  _passkeyController,
                  Icons.vpn_key,
                  isObscure: true,
                  isVisible: _showPasskey,
                  onToggleVisibility: () {
                    setState(() {
                      _showPasskey = !_showPasskey;
                    });
                  },
                  hint: "Leave empty to keep current",
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  "New Optionkey",
                  _optionkeyController,
                  Icons.settings_remote,
                  isObscure: true,
                  isVisible: _showOptionkey,
                  onToggleVisibility: () {
                    setState(() {
                      _showOptionkey = !_showOptionkey;
                    });
                  },
                  hint: "Leave empty to keep current",
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : const Text("Save Changes"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isObscure = false,
    bool enabled = true,
    String? hint,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: isObscure && !isVisible,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              size: 18,
              color: const Color.fromARGB(255, 235, 225, 225),
            ),
            suffixIcon: isObscure
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
          ),
          validator: (value) {
            if (label == 'Username' || label == 'Gmail') {
              if (value == null || value.isEmpty) {
                return 'This field is required';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}

