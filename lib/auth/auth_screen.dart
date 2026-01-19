import 'package:farmers_admin/screens/activity/activity_login_screen.dart';
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
import 'package:farmers_admin/user_feedback/user_feedback_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bcrypt/bcrypt.dart';

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

  final dbRef = FirebaseDatabase.instance.ref();

  Future<void> _loadLastLoggedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEmail = prefs.getString('lastLoggedInEmail');
    if (lastEmail != null && lastEmail.isNotEmpty) {
      _emailController.text = lastEmail;
    }
  }

  @override
  void initState() {
    super.initState();

    // Load last logged-in email after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLastLoggedInEmail();
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // 🔥 Get saved route from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final savedIndex = prefs.getInt('activeMenuIndex') ?? 0;
        final userType = prefs.getString('userType');

        Widget destination;

        // Navigate to saved page based on index
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
          case 11:
            destination = const NotifyUsersScreen();
          case 12:
            destination = const AdminChatListScreen();
            break;
          default:
            destination = DashboardScreen(userType: userType);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => destination),
          );
        }
      });
    } else {
      _errorMessage = widget.errorMessage;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enteredEmail = _emailController.text.trim();
      final enteredPassword = _passwordController.text.trim();
      final enteredPasskey = _passkeyController.text.trim();
      final enteredOptionkey = _optionkeyController.text.trim();

      if (_isLogin) {
        // 🟢 LOGIN FLOW - TWO PHASE AUTHENTICATION

        // Phase 1: Check if user exists in adminUsers database
        final usersSnapshot = await dbRef.child("adminUsers").get();

        if (!usersSnapshot.exists) {
          throw FirebaseAuthException(
            code: 'no-users',
            message: 'No admin users found. Please contact administrator.',
          );
        }

        bool userFound = false;
        String? userType;
        String? userRole;
        String? foundUserKey;

        // Find user by email and validate keys
        for (var child in usersSnapshot.children) {
          final userData = child.value as Map?;
          if (userData == null) continue;

          if (userData['email'] == enteredEmail) {
            userFound = true;
            foundUserKey = child.key;

            // Read stored hashes (migration: support older plaintext fields if present)
            final storedpasskey = userData['passkey']?.toString() ?? "";
            final storedoptionkey = userData['optionkey']?.toString() ?? "";
            final storedPasskeyPlain = userData['passkey']?.toString();
            final storedOptionkeyPlain = userData['optionkey']?.toString();
            // Determine user type based on optionkey presence in input
            if (enteredOptionkey.isNotEmpty) {
              // User attempting admin login
              // If no optionkey hash present but plaintext exists (legacy), treat as unauthorized and require migration.
              if (storedoptionkey.isEmpty &&
                  (storedOptionkeyPlain == null ||
                      storedOptionkeyPlain.isEmpty)) {
                throw FirebaseAuthException(
                  code: 'unauthorized-key',
                  message: 'This account does not have admin privileges.',
                );
              }

              // Verify both passkey and optionkey using BCrypt (or fall back to plaintext equality for legacy data)
              final passkeyValid = storedpasskey.isNotEmpty
                  ? BCrypt.checkpw(enteredPasskey, storedpasskey)
                  : (storedPasskeyPlain != null &&
                        enteredPasskey == storedPasskeyPlain);

              final optionkeyValid = storedoptionkey.isNotEmpty
                  ? BCrypt.checkpw(enteredOptionkey, storedoptionkey)
                  : (storedOptionkeyPlain != null &&
                        enteredOptionkey == storedOptionkeyPlain);

              if (!passkeyValid || !optionkeyValid) {
                throw FirebaseAuthException(
                  code: 'invalid-admin-keys',
                  message: 'Invalid admin keys.',
                );
              }

              userType = "admin";
            } else {
              // User attempting sub-admin login - validate passkey only
              if (enteredPasskey.isEmpty) {
                throw FirebaseAuthException(
                  code: 'missing-passkey',
                  message: 'Please enter your passkey.',
                );
              }

              final passkeyValid = storedpasskey.isNotEmpty
                  ? BCrypt.checkpw(enteredPasskey, storedpasskey)
                  : (storedPasskeyPlain != null &&
                        enteredPasskey == storedPasskeyPlain);

              if (!passkeyValid) {
                throw FirebaseAuthException(
                  code: 'invalid-passkey',
                  message: 'Invalid passkey. Please try again.',
                );
              }

              userType = "sub-admin";
              // Capture the role for sub-admins
              userRole = userData['role']?.toString() ?? 'full';
            }

            break;
          }
        }

        if (!userFound) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No account found with this email.',
          );
        }

        // Save userType and userRole in SharedPreferences before Firebase auth
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userType', userType ?? "sub-admin");
        // Store role for sub-admins (super admins don't need role check)
        if (userRole != null) {
          await prefs.setString('userRole', userRole);
        } else {
          await prefs.remove('userRole'); // Clear role for super admins
        }

        // Phase 2: Authenticate with Firebase Authentication
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );

        // 🔥 ADD THIS: Reset menu to Dashboard on fresh login
        await SharedPreferences.getInstance();
        await prefs.setInt('activeMenuIndex', 0); // Reset to Dashboard
        await prefs.setBool('isFreshLogin', true); // Mark as fresh login

        // Success - Navigate to Dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DashboardScreen(userType: userType ?? "sub-admin"),
            ),
          );
        }
      } else {
        // 🟩 SIGN UP FLOW - Creates Sub-Admin

        final enteredUsername = _usernameController.text.trim();

        // Prevent signup with optionkey (optional validation)
        if (enteredOptionkey.isNotEmpty) {
          throw FirebaseAuthException(
            code: 'invalid-signup',
            message: 'Sub-admin accounts cannot have optionkey.',
          );
        }

        // Create user in Firebase Authentication first
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: enteredEmail,
              password: enteredPassword,
            );

        // Store user data in adminUsers database
        // DO NOT store plaintext password. Hash the passkey before storing.
        final passkey = enteredPasskey.isNotEmpty
            ? BCrypt.hashpw(enteredPasskey, BCrypt.gensalt())
            : "";
        await dbRef.child("adminUsers").child(userCredential.user!.uid).set({
          "username": enteredUsername,
          "email": enteredEmail,
          // intentionally not storing the Firebase auth password
          "passkey": passkey,
          // Sub-admin has no optionkey; keep optionkey empty
          "optionkey": "",
          "createdAt": DateTime.now().toIso8601String(),
        });

        // Sign out after signup
        await FirebaseAuth.instance.signOut();

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
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _errorMessage = 'No account found for this email.';
            break;
          case 'wrong-password':
            _errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            _errorMessage = 'Please enter a valid email address.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'This email is already registered.';
            break;
          case 'missing-admin-keys':
          case 'invalid-admin-keys':
          case 'unauthorized-key':
          case 'missing-passkey':
          case 'invalid-passkey':
          case 'invalid-signup':
          case 'no-users':
            _errorMessage = e.message;
            break;
          default:
            _errorMessage = 'Authentication failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    // Pre-fill with current email if available
    if (_emailController.text.isNotEmpty) {
      emailController.text = _emailController.text;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Forgot Password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your email address to verify your account and receive a password reset link.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF0FC570),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  floatingLabelStyle: const TextStyle(color: Color(0xFF0FC570)),
                ),
                keyboardType: TextInputType.emailAddress,
                cursorColor: const Color(0xFF0FC570),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email address'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: email,
                );

                // Hide loading indicator
                if (mounted) Navigator.pop(context);

                // Close dialog
                if (mounted) Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Password reset link sent to $email'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                // Hide loading indicator
                if (mounted) Navigator.pop(context);

                String errorMessage = 'Failed to send reset email';
                if (e.code == 'user-not-found') {
                  errorMessage = 'No user found with this email.';
                } else if (e.code == 'invalid-email') {
                  errorMessage = 'Invalid email address.';
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                // Hide loading indicator
                if (mounted) Navigator.pop(context);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An error occurred'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0FC570),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Send Reset Link',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
                              Align(
                                alignment: Alignment.topLeft,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  // onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: Colors.green,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passkeyController.dispose();
    _optionkeyController.dispose();
    super.dispose();
  }
}
