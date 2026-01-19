import 'package:farmers_admin/screens/dashboard/dashboard.dart';
import 'package:farmers_admin/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthScreen extends StatefulWidget {
  final String? errorMessage;

  const AuthScreen({super.key, this.errorMessage});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();

  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasskeyVisible = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() {
    if (_authService.isLoggedIn) {
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

    final result = _isLogin
        ? await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
      passkey: _passkeyController.text,
    )
        : await _authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      passkey: _passkeyController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.isSuccess) {
        if (_isLogin) {
          // Navigate to dashboard on successful login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else {
          // Switch to login mode after successful signup
          setState(() {
            _isLogin = true;
            _emailController.clear();
            _passwordController.clear();
            _passkeyController.clear();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Show error message
        setState(() {
          _errorMessage = result.message;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passkeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                              _isLogin ? "Login to Account" : "Create Account",
                              style: const TextStyle(
                                color: Color(0xFF202224),
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            Text(
                              _isLogin
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

                            _buildEmailField(),
                            const SizedBox(height: 16),

                            _buildPasswordField(),
                            const SizedBox(height: 16),

                            _buildPasskeyField(),
                            const SizedBox(height: 10),

                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    // TODO: Implement forgot password
                                  },
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
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 30),

                            _buildSubmitButton(),

                            const SizedBox(height: 20),

                            _buildToggleAuthMode(),
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

  Widget _buildEmailField() {
    return Column(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }

  Widget _buildPasswordField() {
    return Column(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 1),
            ),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
            suffixIcon: _buildVisibilityToggle(
              isVisible: _isPasswordVisible,
              onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
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
    );
  }

  Widget _buildPasskeyField() {
    return Column(
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.green, width: 1),
            ),
            prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey),
            suffixIcon: _buildVisibilityToggle(
              isVisible: _isPasskeyVisible,
              onToggle: () => setState(() => _isPasskeyVisible = !_isPasskeyVisible),
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
    );
  }

  Widget _buildVisibilityToggle({
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(
          isVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey,
        ),
        onPressed: onToggle,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        style: ButtonStyle(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0FC570),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          disabledBackgroundColor: const Color(0xFF0FC570),
          disabledForegroundColor: Colors.white,
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
            _isLogin ? 'Login' : 'Sign Up',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin
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
          child: Text(
            _isLogin ? "Sign Up" : "Login",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}