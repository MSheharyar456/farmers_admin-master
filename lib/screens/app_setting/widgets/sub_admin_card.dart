import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class SubAdminCard extends StatefulWidget {
  const SubAdminCard({super.key});

  @override
  State<SubAdminCard> createState() => _SubAdminCardState();
}

class _SubAdminCardState extends State<SubAdminCard> {
  final dbRef = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _subAdmins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubAdmins();
  }

  Future<void> _fetchSubAdmins() async {
    try {
      final snapshot = await dbRef.child("adminUsers").get();
      if (snapshot.exists) {
        final List<Map<String, dynamic>> loadedAdmins = [];
        for (var child in snapshot.children) {
          final data = Map<String, dynamic>.from(child.value as Map);
          data['key'] = child.key;

          // Check if sub-admin (optionkey is empty or missing, and not the current user just in case)
          // Actually super admin has optionkey. Sub admin does not.
          final optionkey = data['optionkey']?.toString() ?? "";

          if (optionkey.isEmpty) {
            loadedAdmins.add(data);
          }
        }
        setState(() {
          _subAdmins = loadedAdmins;
        });
      }
    } catch (e) {
      print("Error fetching sub-admins: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSubAdmin(
    String username,
    String email,
    String password,
    String passkey,
    String role,
  ) async {
    FirebaseApp? tempApp;
    try {
      // 1. Create secondary Firebase App to create user without logging out current user
      try {
        tempApp = Firebase.app("tempApp");
      } catch (e) {
        tempApp = await Firebase.initializeApp(
          name: "tempApp",
          options: Firebase.app().options,
        );
      }

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCredential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Store in DB
      final hashedPasskey = BCrypt.hashpw(passkey, BCrypt.gensalt());
      await dbRef.child("adminUsers").child(userCredential.user!.uid).set({
        "username": username,
        "email": email,
        "passkey": hashedPasskey,
        "optionkey": "", // Empty signifies sub-admin
        "role": role, // Sub-admin role: 'edit', 'delete', or 'full'
        "createdAt": DateTime.now().toIso8601String(),
      });

      // 3. Clean up
      await tempAuth.signOut();

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sub Admin created successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        _fetchSubAdmins(); // Refresh list
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
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
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
    // Note: tempApp doesn't need explicit deletion usually, but it's good practice not to leak.
    // However, Firebase.app("tempApp") reuse handles it.
  }

  Future<void> _deleteSubAdmin(
    String key,
    String email,
    String username,
  ) async {
    // First, ask for the sub-admin's password to delete from Auth
    final passwordController = TextEditingController();

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text("Delete $username"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter the sub-admin's password to permanently delete their account:",
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Sub-Admin Password",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (password == null || password.isEmpty) return;

    try {
      // 1. Create or get secondary Firebase App to sign in as sub-admin
      FirebaseApp? tempApp;
      try {
        tempApp = Firebase.app("tempApp");
      } catch (e) {
        tempApp = await Firebase.initializeApp(
          name: "tempApp",
          options: Firebase.app().options,
        );
      }

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // 2. Sign in as the sub-admin
      final userCredential = await tempAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Delete the user from Firebase Auth
      await userCredential.user!.delete();

      // 4. Delete from Database
      await dbRef.child("adminUsers").child(key).remove();

      _fetchSubAdmins();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sub Admin deleted permanently!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg = "Error deleting sub admin.";
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMsg = "Incorrect password. Please try again.";
        } else if (e.code == 'user-not-found') {
          // User doesn't exist in Auth, just delete from DB
          await dbRef.child("adminUsers").child(key).remove();
          _fetchSubAdmins();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sub Admin removed from database."),
              backgroundColor: Colors.green,
            ),
          );
          return;
        } else {
          errorMsg = e.message ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddDialog() {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final passkeyController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;
    bool showPassword = false;
    bool showPasskey = false;
    String selectedRole = 'edit'; // Default role

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              contentPadding: EdgeInsets.all(32),
              // ✅ Border radius 8
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),

              title: const Text("Add New Sub Admin"),

              content: SingleChildScrollView(
                child: SizedBox(
                  width: 350, // Fixed width for the dialog content
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty || !v.contains('@')
                              ? "Valid email required"
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !showPassword,
                          decoration: InputDecoration(
                            labelText: "Password",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) =>
                              v!.length < 6 ? "Min 6 chars" : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: passkeyController,
                          obscureText: !showPasskey,
                          decoration: InputDecoration(
                            labelText: "Passkey",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPasskey
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  showPasskey = !showPasskey;
                                });
                              },
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                        const SizedBox(height: 10),
                        // Role Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: "Permission Role",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'edit',
                              child: Text('Edit Only'),
                            ),
                            DropdownMenuItem(
                              value: 'delete',
                              child: Text('Delete Only'),
                            ),
                          ],
                          onChanged: (value) {
                            setStateDialog(() => selectedRole = value!);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // background
                    foregroundColor: Colors.white, // text & icon color
                  ),
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setStateDialog(() => isCreating = true);
                            await _createSubAdmin(
                              usernameController.text.trim(),
                              emailController.text.trim(),
                              passwordController.text.trim(),
                              passkeyController.text.trim(),
                              selectedRole,
                            );
                            // Dialog closes in _createSubAdmin upon success
                            setStateDialog(() => isCreating = false);
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text("Create"),
                ),
              ],
            );
          },
        );
      },
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
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add New"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _subAdmins.isEmpty
                ? const Center(child: Text("No sub-admins found."))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _subAdmins.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final admin = _subAdmins[index];
                      final role = admin['role']?.toString() ?? '';
                      final roleLabel = role == 'edit'
                          ? 'Edit Only'
                          : role == 'delete'
                          ? 'Delete Only'
                          : '';
                      final roleColor = role == 'edit'
                          ? Colors.blue
                          : role == 'delete'
                          ? Colors.orange
                          : Colors.green;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(admin['username'][0].toUpperCase()),
                        ),
                        title: Text(admin['username']),
                        subtitle: Row(
                          children: [
                            Flexible(child: Text(admin['email'])),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: roleColor, width: 1),
                              ),
                              child: Text(
                                roleLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: roleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteSubAdmin(
                              admin['key'],
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
    );
  }
}
