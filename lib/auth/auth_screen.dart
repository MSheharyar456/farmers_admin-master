import 'dart:async';

import 'package:dio/dio.dart';
import 'package:farmers_admin/config/api_config.dart';
import 'package:farmers_admin/screens/app_setting/app_setting_screen.dart';
import 'package:farmers_admin/screens/admin_chat/admin_chat_list_screen.dart';
import 'package:farmers_admin/screens/ads_image.dart';
import 'package:farmers_admin/screens/dashboard/dashboard.dart';
import 'package:farmers_admin/screens/farming_tip/farmingTip.dart';
import 'package:farmers_admin/screens/notify_users/notify_users_screen.dart';
import 'package:farmers_admin/screens/post_management/post_management_screen.dart';
import 'package:farmers_admin/screens/sold_posts/sold_posts_screen.dart';
import 'package:farmers_admin/screens/user_management/user_screen.dart';
import 'package:farmers_admin/screens/working_status/working_status_screen.dart';
import 'package:farmers_admin/screens/commission/commission_screen.dart';
import 'package:farmers_admin/screens/post_report/post_report_screen.dart';
import 'package:farmers_admin/screens/crash_reports/crash_reports_screen.dart';
import 'package:farmers_admin/screens/user_management/deleted_users_screen.dart';
import 'package:farmers_admin/user_feedback/user_feedback_screen.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/models/admin_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  final String? errorMessage;

  const AuthScreen({super.key, this.errorMessage});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}



class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _optionkeyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasskeyVisible = false;
  bool _isOptionkeyVisible = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  StreamSubscription<AdminUser?>? _authSubscription;

  Future<void> _loadLastLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('lastLoggedInEmail');
    if (lastEmail != null && lastEmail.isNotEmpty) {
      _emailController.text = lastEmail;
    }
  }

  void _navigateToDestination(Widget destination) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastLoggedInEmail();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AdminServerAuthService>(context, listen: false);
      _authSubscription = authService.authStateChanges.listen((AdminUser? user) async {
        if (user == null || !mounted) return;
        final prefs = await SharedPreferences.getInstance();
        final savedIndex = prefs.getInt('activeMenuIndex') ?? 0;
        final userType = user.userType;

        Widget destination;
        switch (savedIndex) {
          case 0:
            destination = DashboardScreen(userType: userType);
            break;
          case 1:
            destination = const PostManagementScreen();
            break;
          case 2:
            destination = const UserScreen();
            break;
          case 3:
            destination = const UserFeedbackScreen();
            break;
          case 4:
            destination = const FarmingTipManagementScreen();
            break;
          case 5:
            destination = const AdsImageScreen();
            break;
          case 6:
            destination = const WorkingStatusManagementScreen();
            break;
          case 7:
            destination = AppSettingScreen();
            break;
          case 8:
            destination = const CommissionScreen();
            break;
          case 9:
            destination = const PostReportScreen();
            break;
          case 10:
            destination = const SoldPostsScreen();
            break;
          case 11:
            destination = const NotifyUsersScreen();
            break;
          case 12:
            destination = const AdminChatListScreen();
            break;
          case 15:
            destination = const DeletedUsersScreen();
            break;
          case 16:
            destination = const CrashReportsScreen();
            break;
          default:
            destination = DashboardScreen(userType: userType);
        }
        if (mounted) _navigateToDestination(destination);
      });
    });

    _errorMessage = widget.errorMessage;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = Provider.of<AdminServerAuthService>(context, listen: false);
    final enteredEmail = _emailController.text.trim();
    final enteredPassword = _passwordController.text.trim();
    final enteredPasskey = _passkeyController.text.trim();
    final enteredOptionkey = _optionkeyController.text.trim();

    print('DEBUG: AuthScreen._submit() called. _isLogin: $_isLogin');
    print('DEBUG: Email: $enteredEmail');

    try {
      if (_isLogin) {
        print('DEBUG: Calling authService.login()');
        final user = await authService.login(
          email: enteredEmail,
          password: enteredPassword,
          passkey: enteredPasskey,
          optionkey: enteredOptionkey.isEmpty ? null : enteredOptionkey,
        );
        print('DEBUG: authService.login() returned successfully for user: ${user.email}');

        print('DEBUG: Getting SharedPreferences instance...');
        final prefs = await SharedPreferences.getInstance();
        print('DEBUG: SharedPreferences instance obtained.');
        
        print('DEBUG: Saving user info to SharedPreferences...');
        await prefs.setString('user_id', user.id);
        await prefs.setString('user_email', user.email);
        await prefs.setString('user_name', user.username ?? '');
        await prefs.setString('userType', user.userType);
        await prefs.setString('userRole', user.role);
        await prefs.setInt('activeMenuIndex', 0);
        await prefs.setBool('isFreshLogin', true);
        print('DEBUG: User info saved to SharedPreferences.');

        if (mounted) {
          print('DEBUG: Navigating to DashboardScreen...');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardScreen(userType: user.userType),
            ),
          );
        } else {
          print('DEBUG: AuthScreen no longer mounted, skipping navigation.');
        }
      } else {
        final enteredUsername = _usernameController.text.trim();
        if (enteredOptionkey.isNotEmpty) {
          setState(() {
            _errorMessage = 'Sub-admin accounts cannot have optionkey.';
          });
          if (mounted) setState(() => _isLoading = false);
          return;
        }

        await authService.signUp(
          email: enteredEmail,
          password: enteredPassword,
          username: enteredUsername,
          passkey: enteredPasskey,
        );

        if (mounted) {
          setState(() {
            _isLogin = true;
            _usernameController.clear();
            _emailController.clear();
            _passwordController.clear();
            _passkeyController.clear();
            _optionkeyController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sub-Admin account created successfully! Please log in.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on AdminAuthException catch (e) {
      print('DEBUG: AdminAuthException: ${e.message}');
      // Show user-friendly error message (truncate if too long)
      final msg = e.message;
      setState(() => _errorMessage = msg.length > 150 ? '${msg.substring(0, 150)}...' : msg);
    } on DioException catch (e) {
      print('DEBUG: DioException: ${e.type} - ${e.message}');
      // Handle network/connection errors with user-friendly messages
      String userMessage;
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        userMessage = 'Connection timed out. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        userMessage = 'Network error. Please check your internet connection.';
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          userMessage = 'Invalid credentials. Please check your email, password, and passkey.';
        } else if (statusCode == 404) {
          userMessage = 'Server not found. Please try again later.';
        } else if (statusCode != null && statusCode >= 500) {
          userMessage = 'Server error. Please try again later.';
        } else {
          userMessage = 'Something went wrong. Please try again.';
        }
      } else {
        userMessage = 'Network error. Please check your connection and try again.';
      }
      setState(() => _errorMessage = userMessage);
    } catch (e, stack) {
      print('DEBUG: General error during login SUBMIT: $e');
      print('DEBUG: Stack trace: $stack');
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    final passkeyController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Reset Password',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter email';
                      if (!value.contains('@')) return 'Please enter valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passkeyController,
                    decoration: const InputDecoration(
                      labelText: 'Current Passkey',
                      hintText: 'Enter your current passkey',
                      prefixIcon: Icon(Icons.vpn_key, color: Colors.green),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter passkey';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password (min 6 chars)',
                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                      suffixIcon: IconButton(
                        icon: Icon(showNewPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => showNewPassword = !showNewPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: !showNewPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter new password';
                      if (value.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: 'Re-enter new password',
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
                      suffixIcon: IconButton(
                        icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: !showConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please confirm password';
                      if (value != newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setState(() => isLoading = true);

                try {
                  final dio = Dio(BaseOptions(
                    baseUrl: apiBaseUrl,
                    connectTimeout: const Duration(seconds: 30),
                    receiveTimeout: const Duration(seconds: 30),
                  ));

                  final res = await dio.post('/admin/auth/reset-password', data: {
                    'email': emailController.text.trim(),
                    'passkey': passkeyController.text.trim(),
                    'newPassword': newPasswordController.text.trim(),
                  });

                  if (res.data != null && res.data['success'] == true) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res.data['message'] ?? 'Password reset successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    throw Exception(res.data?['message'] ?? 'Reset failed');
                  }
                } on DioException catch (e) {
                  String userMessage;
                  if (e.type == DioExceptionType.connectionTimeout ||
                      e.type == DioExceptionType.sendTimeout ||
                      e.type == DioExceptionType.receiveTimeout) {
                    userMessage = 'Connection timed out. Please check your internet connection.';
                  } else if (e.type == DioExceptionType.connectionError) {
                    userMessage = 'Network error. Please check your internet connection.';
                  } else if (e.type == DioExceptionType.badResponse) {
                    final statusCode = e.response?.statusCode;
                    final serverMsg = e.response?.data?['message'];
                    if (serverMsg != null && serverMsg.toString().isNotEmpty) {
                      userMessage = serverMsg.toString().length > 100 
                          ? '${serverMsg.toString().substring(0, 100)}...' 
                          : serverMsg.toString();
                    } else if (statusCode == 401) {
                      userMessage = 'Invalid credentials. Please check your information.';
                    } else if (statusCode == 404) {
                      userMessage = 'Server not found. Please try again later.';
                    } else if (statusCode != null && statusCode >= 500) {
                      userMessage = 'Server error. Please try again later.';
                    } else {
                      userMessage = 'Reset failed. Please try again.';
                    }
                  } else {
                    userMessage = 'Network error. Please check your connection.';
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(userMessage), backgroundColor: Colors.red),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Something went wrong. Please try again.'), 
                        backgroundColor: Colors.red
                      ),
                    );
                  }
                } finally {
                  if (context.mounted) {
                    setState(() => isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FC570),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotEmailDialog() {
    final usernameController = TextEditingController();
    final passkeyController = TextEditingController();
    final optionkeyController = TextEditingController();
    final newEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool isVerified = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              isVerified ? 'Enter New Email' : 'Forgot Email',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMsg!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!isVerified) ...[
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter your username',
                        prefixIcon: Icon(Icons.person, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter username';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passkeyController,
                      decoration: const InputDecoration(
                        labelText: 'Passkey',
                        hintText: 'Enter your passkey',
                        prefixIcon: Icon(Icons.vpn_key, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter passkey';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: optionkeyController,
                      decoration: const InputDecoration(
                        labelText: 'Optionkey',
                        hintText: 'Enter your optionkey',
                        prefixIcon: Icon(Icons.settings_remote, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter optionkey';
                        return null;
                      },
                    ),
                  ] else ...[
                    const Text(
                      'Identity verified! Enter your new email address.',
                      style: TextStyle(fontSize: 14, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newEmailController,
                      decoration: const InputDecoration(
                        labelText: 'New Email',
                        hintText: 'Enter new email address',
                        prefixIcon: Icon(Icons.email, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter new email';
                        if (!value.contains('@')) return 'Please enter valid email';
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Cancel', style: TextStyle(fontSize: 16, color: Colors.black54)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;

                setState(() {
                  isLoading = true;
                  errorMsg = null;
                });

                try {
                  final dio = Dio(BaseOptions(
                    baseUrl: apiBaseUrl,
                    connectTimeout: const Duration(seconds: 30),
                    receiveTimeout: const Duration(seconds: 30),
                  ));

                  if (!isVerified) {
                    // Step 1: Verify identity first by calling a verify endpoint
                    final verifyRes = await dio.post('/admin/auth/verify-identity', data: {
                      'username': usernameController.text.trim(),
                      'passkey': passkeyController.text.trim(),
                      'optionkey': optionkeyController.text.trim(),
                    });

                    if (verifyRes.data != null && verifyRes.data['success'] == true) {
                      setState(() {
                        isVerified = true;
                        isLoading = false;
                      });
                    } else {
                      throw Exception(verifyRes.data?['message'] ?? 'Verification failed');
                    }
                  } else {
                    // Step 2: Update email
                    final res = await dio.post('/admin/auth/verify-and-update-email', data: {
                      'username': usernameController.text.trim(),
                      'passkey': passkeyController.text.trim(),
                      'optionkey': optionkeyController.text.trim(),
                      'newEmail': newEmailController.text.trim(),
                    });

                    if (res.data != null && res.data['success'] == true) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.data['message'] ?? 'Email updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      throw Exception(res.data?['message'] ?? 'Update failed');
                    }
                  }
                } on DioException catch (e) {
                  String userMessage;
                  if (e.type == DioExceptionType.connectionTimeout ||
                      e.type == DioExceptionType.sendTimeout ||
                      e.type == DioExceptionType.receiveTimeout) {
                    userMessage = 'Connection timed out. Please check your internet connection.';
                  } else if (e.type == DioExceptionType.connectionError) {
                    userMessage = 'Network error. Please check your internet connection.';
                  } else if (e.type == DioExceptionType.badResponse) {
                    final statusCode = e.response?.statusCode;
                    final serverMsg = e.response?.data?['message'];
                    if (serverMsg != null && serverMsg.toString().isNotEmpty) {
                      userMessage = serverMsg.toString().length > 100 
                          ? '${serverMsg.toString().substring(0, 100)}...' 
                          : serverMsg.toString();
                    } else if (statusCode == 401) {
                      userMessage = 'Invalid credentials. Please check your information.';
                    } else if (statusCode == 404) {
                      userMessage = 'Server not found. Please try again later.';
                    } else if (statusCode != null && statusCode >= 500) {
                      userMessage = 'Server error. Please try again later.';
                    } else {
                      userMessage = 'Request failed. Please try again.';
                    }
                  } else {
                    userMessage = 'Network error. Please check your connection.';
                  }
                  setState(() {
                    errorMsg = userMessage;
                    isLoading = false;
                  });
                } catch (e) {
                  setState(() {
                    errorMsg = 'Something went wrong. Please try again.';
                    isLoading = false;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FC570),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isVerified ? 'Update Email' : 'Verify', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _isLogin;

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 800;
          return Row(
            children: [
              // LEFT SIDE FORM
              Expanded(
                flex: 2,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SvgPicture.asset(
                              'images/splash_green.svg',
                              height: 100,
                            ),
                            const SizedBox(height: 0),

                            Text(
                              isLogin
                                  ? "Login to Account"
                                  : "Create Sub-Admin Account",
                              style: const TextStyle(
                                color: Color(0xFF202224),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),

                            Text(
                              isLogin
                                  ? "Please enter your credentials to continue"
                                  : "Fill in your details to create sub-admin account",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFADB5BD),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (_errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // USERNAME (Only for Sign Up)
                            if (!isLogin) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Username*',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _usernameController,
                                    cursorColor: Colors.black,
                                    decoration: InputDecoration(
                                      hintText: 'Enter username',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFADB5BD),
                                        fontSize: 14,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a username.';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],

                            // EMAIL
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email*',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _emailController,
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                    hintText: 'example@site.com',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFADB5BD),
                                      fontSize: 14,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.green,
                                        width: 1,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || !value.contains('@')) {
                                      return 'Please enter a valid email address.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // PASSWORD
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Password*',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _passwordController,
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                    hintText: '✱✱✱✱✱✱',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFADB5BD),
                                      fontSize: 12,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.green,
                                        width: 1,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 20),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        style: ButtonStyle(
                                          overlayColor: WidgetStateProperty.all(
                                            Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'Password must be at least 6 characters long.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // PASSKEY
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isLogin ? 'Passkey' : 'Passkey*',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _passkeyController,
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                    hintText: '✱✱✱✱✱✱✱',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFADB5BD),
                                      fontSize: 12,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: Colors.green,
                                        width: 1,
                                      ),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.vpn_key,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 20),
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          _isPasskeyVisible
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.grey,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasskeyVisible =
                                                !_isPasskeyVisible;
                                          });
                                        },
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        style: ButtonStyle(
                                          overlayColor: WidgetStateProperty.all(
                                            Colors.transparent,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  obscureText: !_isPasskeyVisible,
                                  validator: (value) {
                                    if (!isLogin &&
                                        (value == null || value.isEmpty)) {
                                      return 'Passkey is required.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // OPTIONKEY (Only shown in Login)
                            if (isLogin)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Optionkey',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  TextFormField(
                                    controller: _optionkeyController,
                                    cursorColor: Colors.black,
                                    decoration: InputDecoration(
                                      hintText: '✱✱✱✱✱✱✱',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFFADB5BD),
                                        fontSize: 12,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                            horizontal: 14,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(
                                          color: Colors.green,
                                          width: 1,
                                        ),
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.key,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                      suffixIcon: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 20,
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            _isOptionkeyVisible
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.grey,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isOptionkeyVisible =
                                                  !_isOptionkeyVisible;
                                            });
                                          },
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          hoverColor: Colors.transparent,
                                          style: ButtonStyle(
                                            overlayColor:
                                                WidgetStateProperty.all(
                                                  Colors.transparent,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    obscureText: !_isOptionkeyVisible,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 0),

                            if (isLogin)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: Colors.green,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      overlayColor: Colors.transparent,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.green,
                                        decorationThickness: 2,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _showForgotEmailDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      foregroundColor: Colors.green,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      overlayColor: Colors.transparent,
                                    ),
                                    child: const Text(
                                      'Forgot Email?',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.green,
                                        decorationThickness: 2,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 10),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0FC570),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBackgroundColor: const Color(
                                        0xFF0FC570,
                                      ),
                                      disabledForegroundColor: Colors.white,
                                    ).copyWith(
                                      overlayColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ), // 🔹 removes hover/splash/focus effect
                                      shadowColor: WidgetStateProperty.all(
                                        Colors.transparent,
                                      ), // (optional) removes elevation shadow on hover
                                    ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _isLoading
                                      ? const SizedBox(
                                          key: ValueKey('loader'),
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          key: const ValueKey('text'),
                                          isLogin ? 'Login' : 'Sign Up',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            // TOGGLE BETWEEN LOGIN & SIGNUP
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLogin
                                      ? "Don't have an account? "
                                      : "Already have an account? ",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _errorMessage = null;
                                    });
                                  },
                                  hoverColor:
                                      Colors.transparent, // 🔹 No hover color
                                  splashColor:
                                      Colors.transparent, // 🔹 No splash effect
                                  highlightColor: Colors
                                      .transparent, // 🔹 No highlight on click
                                  child: Text(
                                    isLogin ? "Sign Up" : "Login",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
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
                ),
              ),

              // RIGHT SIDE IMAGE
              if (isWideScreen)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: const Color(0xFFF7F9FB),
                    child: Image.asset(
                      'images/loginBanner.png',
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passkeyController.dispose();
    _optionkeyController.dispose();
    super.dispose();
  }
}
