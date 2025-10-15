import 'package:farmers_admin/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthScreen extends StatefulWidget {
  final String? errorMessage;

  const AuthScreen({super.key, this.errorMessage});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasskeyVisible = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  final dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
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
      if (_isLogin) {
        // LOGIN
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final snapshot = await dbRef.child("adminUsers").child(userCredential.user!.uid).get();

        if (!snapshot.exists ||
            snapshot.child("passkey").value != _passkeyController.text.trim()) {
          await FirebaseAuth.instance.signOut();
          throw FirebaseAuthException(
            code: 'invalid-passkey',
            message: 'Invalid passkey. Please try again.',
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      } else {
        // SIGN UP
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await dbRef.child("adminUsers").child(userCredential.user!.uid).set({
          "email": _emailController.text.trim(),
          "passkey": _passkeyController.text.trim(),
          "createdAt": DateTime.now().toIso8601String(),
        });

// 🔒 Sign out immediately after signup
        await FirebaseAuth.instance.signOut();

// ✅ Redirect to login screen
        if (mounted) {
          setState(() {
            _isLogin = true; // Switch to login mode
            _emailController.clear();
            _passwordController.clear();
            _passkeyController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please log in.'),
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
          case 'invalid-passkey':
            _errorMessage = e.message;
            break;
          default:
            _errorMessage = 'Authentication failed. Please try again.';
        }
      });
    }

    if (mounted) setState(() => _isLoading = false);
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
                            SvgPicture.asset('images/splash_green.svg', height: 100),
                            const SizedBox(height: 10),

                            Text(
                              isLogin ? "Login to Account" : "Create Account",
                              style: const TextStyle(
                                color: Color(0xFF202224),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            Text(
                              isLogin
                                  ? "Please enter your credentials to continue"
                                  : "Fill in your details to sign up",
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFADB5BD)),
                            ),
                            const SizedBox(height: 40),

                            if (_errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(color: Colors.red, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // EMAIL
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email*',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: 'example@site.com',
                                    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.green, width: 1),
                                    ),
                                    prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
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
                            const SizedBox(height: 16),

                            // PASSWORD
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Password*',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    hintText: '✱✱✱✱✱✱',
                                    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.green, width: 1),
                                    ),
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),

                                    // 👇 Fixed suffix icon (no hover, no splash, no highlight)
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 20), // <-- Right gap here
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        style: ButtonStyle(
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
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


                            const SizedBox(height: 16),

// PASSKEY
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Passkey*',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passkeyController,
                                  decoration: InputDecoration(
                                    hintText: '✱✱✱✱✱✱✱',
                                    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Colors.green, width: 1),
                                    ),
                                    prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey),

                                    // 👇 Fixed suffix icon (no hover, no splash, no highlight)
                                    suffixIcon: Padding(
                                      padding: const EdgeInsets.only(right: 20), // <-- Right gap here
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          _isPasskeyVisible ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasskeyVisible = !_isPasskeyVisible;
                                          });
                                        },
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        style: ButtonStyle(
                                          overlayColor: MaterialStateProperty.all(Colors.transparent),
                                        ),
                                      ),
                                    ),
                                  ),
                                  obscureText: !_isPasskeyVisible,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Passkey is required.';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (isLogin)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    foregroundColor: Colors.green,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    overlayColor: Colors.transparent, // 👈 removes hover + splash color
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.green,
                                      decorationThickness: 2,
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 30),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submit, // disable tap while loading
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0FC570),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  // 👇 ensures color doesn’t change when disabled (loading)
                                  disabledBackgroundColor: const Color(0xFF0FC570),
                                  disabledForegroundColor: Colors.white,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200), // smooth transition
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

                            const SizedBox(height: 20),

                            // TOGGLE BETWEEN LOGIN & SIGNUP
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLogin
                                      ? "Don’t have an account? "
                                      : "Already have an account? ",
                                  style: const TextStyle(color: Colors.black87),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                    });
                                  },
                                  child: Text(
                                    isLogin ? "Sign Up" : "Login",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
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
}
