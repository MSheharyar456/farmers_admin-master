import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/sub_admin_service.dart';
import '../../../widgets/delete_dialog.dart';

class SubAdminCard extends StatefulWidget {
  final ValueChanged<bool>? onLoadingChanged;

  const SubAdminCard({super.key, this.onLoadingChanged});

  @override
  State<SubAdminCard> createState() => _SubAdminCardState();
}

class _SubAdminCardState extends State<SubAdminCard> {
  final _subAdminService = SubAdminService();

  List<Map<String, dynamic>> _subAdmins = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubAdmins();
  }

  Future<void> _fetchSubAdmins() async {
    try {
      final admins = await _subAdminService.fetchSubAdmins();

      if (mounted) {
        setState(() {
          _subAdmins = admins;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint("Error fetching sub-admins: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading sub-admins: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      widget.onLoadingChanged?.call(false);
    }
  }

  Future<void> _createSubAdmin(
    String username,
    String email,
    String password,
    String passkey,
    String role,
  ) async {
    try {
      final result = await _subAdminService.createSubAdmin(
        username: username,
        email: email,
        password: password,
        passkey: passkey,
        role: role,
      );

      if (mounted) {
        if (result.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sub Admin created successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _fetchSubAdmins();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${result.message}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteSubAdmin(
    String userId,
    String email,
    String username,
  ) async {
    try {
      await showDeleteDialog(
        context: context,
        title: 'Delete Sub-Admin',
        message: 'Are you sure you want to delete $username ($email)?',
        confirmText: 'Delete',
        cancelText: 'Cancel',
        onConfirm: () async {
          final result = await _subAdminService.deleteSubAdmin(userId);
          if (!result.success) {
            throw Exception(result.message);
          }
          if (mounted) {
            _fetchSubAdmins();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting sub-admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddDialog() {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final passkeyController = TextEditingController();
    String selectedRole = 'edit';
    bool showPasswordUsername = false;
    bool showPasswordEmail = false;
    bool showPasswordPass = false;
    bool showPasswordKey = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isCreating = false;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.green,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Add Sub Admin",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),

                                  Text(
                                    "Create a new sub-admin account",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Username and Email in one row
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: "Username",
                                controller: usernameController,
                                icon: Icons.person_outline,
                                hint: "Enter admin username",
                                isPassword: false,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInputField(
                                label: "Email Address",
                                controller: emailController,
                                icon: Icons.email_outlined,
                                hint: "Enter admin email",
                                keyboardType: TextInputType.emailAddress,
                                isPassword: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Password and Passkey in one row
                        Row(
                          children: [
                            Expanded(
                              child: _buildPasswordField(
                                label: "Password",
                                controller: passwordController,
                                hint: "Enter password (6+ characters)",
                                isVisible: showPasswordUsername,
                                onVisibilityToggle: (visible) {
                                  setStateDialog(
                                    () => showPasswordUsername = visible,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPasswordField(
                                label: "Passkey",
                                controller: passkeyController,
                                hint: "Enter passkey (security)",
                                isVisible: showPasswordEmail,
                                onVisibilityToggle: (visible) {
                                  setStateDialog(
                                    () => showPasswordEmail = visible,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Role Dropdown
                        _buildRoleDropdown(
                          selectedRole: selectedRole,
                          onChanged: (value) {
                            if (value != null) {
                              setStateDialog(() => selectedRole = value);
                            }
                          },
                        ),
                        const SizedBox(height: 28),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isCreating
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  side: const BorderSide(
                                    color: Colors.grey,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isCreating
                                    ? null
                                    : () async {
                                        if (usernameController.text.isEmpty) {
                                          _showErrorSnack("Username required");
                                          return;
                                        }
                                        if (emailController.text.isEmpty) {
                                          _showErrorSnack("Email required");
                                          return;
                                        }
                                        if (!emailController.text.contains(
                                          '@',
                                        )) {
                                          _showErrorSnack("Enter valid email");
                                          return;
                                        }
                                        if (passwordController.text.length <
                                            6) {
                                          _showErrorSnack(
                                            "Password min 6 chars",
                                          );
                                          return;
                                        }
                                        if (passkeyController.text.isEmpty) {
                                          _showErrorSnack("Passkey required");
                                          return;
                                        }

                                        setStateDialog(() => isCreating = true);

                                        await _createSubAdmin(
                                          usernameController.text.trim(),
                                          emailController.text.trim(),
                                          passwordController.text.trim(),
                                          passkeyController.text.trim(),
                                          selectedRole,
                                        );

                                        setStateDialog(
                                          () => isCreating = false,
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor: Colors.green
                                      .withOpacity(0.5),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: isCreating
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        "Create Admin",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
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
            );
          },
        );
      },
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required Function(bool) onVisibilityToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isVisible,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey.shade400,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: () => onVisibilityToggle(!isVisible),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown({
    required String selectedRole,
    required Function(String?) onChanged,
  }) {
    const roleOptions = [
      {'value': 'edit', 'label': 'Edit Only', 'icon': Icons.edit},
      {'value': 'delete', 'label': 'Delete Only', 'icon': Icons.delete},
      // {
      //   'value': 'full',
      //   'label': 'Full Access',
      //   'icon': Icons.admin_panel_settings,
      // },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Role & Permissions",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedRole,
          items: roleOptions.map((role) {
            return DropdownMenuItem<String>(
              value: role['value'] as String,
              child: Row(
                children: [
                  Icon(
                    role['icon'] as IconData,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    role['label'] as String,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.security,
              color: Colors.grey.shade400,
              size: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: AbsorbPointer(
          absorbing: _isLoading,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Sub Admins",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _errorMessage == null ? _showAddDialog : null,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text("Add New"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    border: Border.all(color: Colors.red, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Error',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetchSubAdmins,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (_subAdmins.isEmpty)
                const Center(child: Text("No sub-admins found."))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subAdmins.length,
                  separatorBuilder: (c, i) => const Divider(),
                  itemBuilder: (context, index) {
                    final admin = _subAdmins[index];
                    final username = admin['username'] ?? '';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text(
                          username.isNotEmpty ? username[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(username),
                      subtitle: Text(admin['email'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteSubAdmin(
                            admin['id'],
                            admin['email'],
                            admin['username'],
                          );
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
