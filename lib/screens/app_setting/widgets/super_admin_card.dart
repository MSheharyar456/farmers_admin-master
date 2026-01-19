import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SuperAdminCard extends StatefulWidget {
  const SuperAdminCard({super.key});

  @override
  State<SuperAdminCard> createState() => _SuperAdminCardState();
}

class _SuperAdminCardState extends State<SuperAdminCard> {
  final _formKey = GlobalKey<FormState>();
  // Re-authentication Dialog
  Future<bool> _showReauthDialog() async {
    final passwordController = TextEditingController();
    bool isLoading = false;

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text("Security Check"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "This operation is sensitive and requires a recent login. Please enter your current password to proceed.",
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Current Password",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 15.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (passwordController.text.isEmpty) return;

                              setState(() => isLoading = true);
                              try {
                                AuthCredential credential =
                                    EmailAuthProvider.credential(
                                      email: FirebaseAuth
                                          .instance
                                          .currentUser!
                                          .email!,
                                      password: passwordController.text,
                                    );
                                await FirebaseAuth.instance.currentUser!
                                    .reauthenticateWithCredential(credential);
                                if (context.mounted) {
                                  Navigator.pop(context, true);
                                }
                              } catch (e) {
                                setState(() => isLoading = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Incorrect password. Please try again.",
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Confirm"),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passkeyController = TextEditingController();
  final _optionkeyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  // Visibility toggles
  bool _showPassword = false;
  bool _showPasskey = false;
  bool _showOptionkey = false;

  String? _uid;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    final dbRef = FirebaseDatabase.instance.ref();
    // Get the Super Admin UID from environment variable
    final superAdminUid = dotenv.env['SUPER_ADMIN_UID'];

    if (superAdminUid == null || superAdminUid.isEmpty) {
      debugPrint("Error: SUPER_ADMIN_UID not found in .env");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Fetch the specific admin user using the UID from .env
    final snapshot = await dbRef.child("adminUsers").child(superAdminUid).get();

    if (snapshot.exists) {
      _uid = superAdminUid; // Store the UID

      final data = snapshot.value as Map;
      _usernameController.text = data['username'] ?? '';
      _emailController.text = data['email'] ?? '';
      // Passkey and Optionkey are hashed, so we don't show them, or we show empty to indicate "unchanged"
      // Validating requirement: "change profile username passkey and optionkey and password and gmail"
      // Usually we don't pre-fill passwords/keys.
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_uid == null) return;

    setState(() => _isSaving = true);

    try {
      final dbRef = FirebaseDatabase.instance
          .ref()
          .child("adminUsers")
          .child(_uid!);
      final user = FirebaseAuth.instance.currentUser!;

      // 1. Update Email - DISABLED per requirement (Gmail not editable)
      /*
      if (_emailController.text.trim() != user.email) {
        await user.verifyBeforeUpdateEmail(_emailController.text.trim());
      }
      */

      // 2. Update Password if provided
      if (_passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text.trim());
      }

      // 3. Update DB Data
      Map<String, Object?> updates = {
        "username": _usernameController.text.trim(),
        // "email": _emailController.text.trim(), // No longer updating email from here
      };

      if (_passkeyController.text.isNotEmpty) {
        updates["passkey"] = BCrypt.hashpw(
          _passkeyController.text.trim(),
          BCrypt.gensalt(),
        );
      }

      if (_optionkeyController.text.isNotEmpty) {
        updates["optionkey"] = BCrypt.hashpw(
          _optionkeyController.text.trim(),
          BCrypt.gensalt(),
        );
      }

      await dbRef.update(updates);

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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login' && mounted) {
        // Handle re-authentication
        bool reauthSuccess = await _showReauthDialog();
        if (reauthSuccess) {
          // Retry the update
          await _updateProfile();
          return;
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.message}"),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
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
                    // const SizedBox(height: 15),
                    // _buildTextField(
                    //   "New Password",
                    //   _passwordController,
                    //   Icons.lock,
                    //   isObscure: true,
                    //   isVisible: _showPassword,
                    //   onToggleVisibility: () {
                    //     setState(() {
                    //       _showPassword = !_showPassword;
                    //     });
                    //   },
                    //   hint: "Leave empty to keep current",
                    // ),
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
              borderSide: BorderSide(color: Colors.green),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 0,
            ),
          ),
          validator: (value) {
            if (label == 'Username' || label == 'Gmail') {
              if (value == null || value.isEmpty)
                return 'This field is required';
            }
            return null;
          },
        ),
      ],
    );
  }
}
