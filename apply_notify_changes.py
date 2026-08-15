import os
import re

file_path = r'f:\flutter projects\farmers_hub-master1\farmers_hub-master\farmers_admin-master\lib\screens\notify_users\notify_users_screen.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add _selectedUsers state variables
if '_selectedUsers' not in content:
    content = content.replace(
        '  final TextEditingController _searchController = TextEditingController();',
        '  final TextEditingController _searchController = TextEditingController();\n  List<UserModel> _selectedUsers = [];'
    )

# 2. Add onRowChecked to PlutoGrid
on_row_checked = '''            rows: rows,
            onRowChecked: (event) {
              setState(() {
                _selectedUsers = stateManager.checkedRows.map((r) => r.cells['userData']!.value as UserModel).toList();
              });
            },
            onLoaded: (event) {'''
if 'onRowChecked: (event) {' not in content:
    content = content.replace(
        '''            rows: rows,
            onLoaded: (event) {''',
        on_row_checked
    )

# 3. Add enableRowChecked to getColumns
enable_row_checked = '''      PlutoColumn(
        title: 'No',
        field: 'no',
        type: PlutoColumnType.number(),
        width: isMobile ? 50 : 60,
        enableRowChecked: true,
        enableEditingMode: false,
      ),'''
if 'enableRowChecked: true' not in content:
    content = re.sub(
        r"      PlutoColumn\(\s*title: 'No',\s*field: 'no',\s*type: PlutoColumnType\.number\(\),\s*width: isMobile \? 50 : 60,\s*enableEditingMode: false,\s*\),",
        enable_row_checked,
        content
    )

# 4. Desktop Button: Find the start of the row containing Add Notification button and insert the new button before it.
# In _buildHeader, we have:
desktop_button_anchor = '''              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddNotifyUserScreen(),'''

desktop_button_replacement = '''              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedUsers.isNotEmpty) ...[
                    ElevatedButton(
                      onPressed: _showSelectedUsersNotificationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.send, size: 14, color: Colors.white),
                          const SizedBox(width: 8),
                          Text("Send to Selected ()", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddNotifyUserScreen(),'''

if '_showSelectedUsersNotificationDialog' not in content:
    content = content.replace(desktop_button_anchor, desktop_button_replacement)

# Mobile Button
mobile_button_anchor = '''                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNotifyUserScreen(),'''

mobile_button_replacement = '''                  Row(
                    children: [
                      if (_selectedUsers.isNotEmpty) ...[
                        ElevatedButton(
                          onPressed: _showSelectedUsersNotificationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.send, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text("Send to Selected ()", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNotifyUserScreen(),'''

if 'Send to Selected' in content and content.count('Send to Selected') == 1: # meaning desktop was added but mobile wasn't
    content = content.replace(mobile_button_anchor, mobile_button_replacement)
elif 'Send to Selected' not in content:
    content = content.replace(mobile_button_anchor, mobile_button_replacement)

# 5. Add Dialog Method at the end of _NotifyUsersContentState
dialog_logic = '''
  void _showSelectedUsersNotificationDialog() {
    final titleController = TextEditingController(text: 'تطبيق محصولك');
    final messageController = TextEditingController();
    bool isSendingDialog = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Send Notification to Selected Users'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('You are about to send a notification to  selected users.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Notification Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notification Message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSendingDialog ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSendingDialog
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out both title and message.'), backgroundColor: Colors.red));
                            return;
                          }

                          setStateDialog(() => isSendingDialog = true);

                          try {
                            final authService = Provider.of<AdminServerAuthService>(context, listen: false);
                            final authToken = authService.authToken;
                            if (authToken == null) throw Exception('Auth token not found');

                            for (var user in _selectedUsers) {
                              await AdminNotificationService.sendNotification(
                                title: titleController.text.trim(),
                                message: messageController.text.trim(),
                                userId: user.uid,
                                type: 'admin_broadcast',
                                authToken: authToken,
                              );
                            }

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification successfully sent to  users.'), backgroundColor: Colors.green));
                            
                            // Clear selection
                            stateManager.toggleAllRowChecked(false);
                            setState(() {
                              _selectedUsers.clear();
                            });
                          } catch (e) {
                            setStateDialog(() => isSendingDialog = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: '), backgroundColor: Colors.red));
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: isSendingDialog
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Notification', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
'''

if 'void _showSelectedUsersNotificationDialog()' not in content:
    last_brace_idx = content.rfind('}')
    content = content[:last_brace_idx] + dialog_logic

# 6. Add imports
if 'admin_notification_service.dart' not in content:
    content = content.replace(
        "import 'package:flutter/services.dart';",
        "import 'package:flutter/services.dart';\nimport 'package:farmers_admin/services/admin_notification_service.dart';\nimport 'package:farmers_admin/services/admin_server_auth_service.dart';"
    )


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated notify_users_screen.dart")
