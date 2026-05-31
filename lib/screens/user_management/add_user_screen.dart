import 'package:flutter/material.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/repositories/user_repository.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';

class _CountryItem {
  const _CountryItem(this.name, this.code, this.dialCode);
  final String name;
  final String code;
  final String dialCode;
}

const List<_CountryItem> _kCountryList = [
  _CountryItem('Syria', 'SY', '+963'),
  _CountryItem('Turkey', 'TR', '+90'),
  _CountryItem('Saudi Arabia', 'SA', '+966'),
  _CountryItem('United Arab Emirates', 'AE', '+971'),
  _CountryItem('Qatar', 'QA', '+974'),
  _CountryItem('Lebanon', 'LB', '+961'),
  _CountryItem('Kuwait', 'KW', '+965'),
  _CountryItem('Iraq', 'IQ', '+964'),
  _CountryItem('Jordan', 'JO', '+962'),
  _CountryItem('Egypt', 'EG', '+20'),
  _CountryItem('Germany', 'DE', '+49'),
  _CountryItem('Netherlands', 'NL', '+31'),
  _CountryItem('France', 'FR', '+33'),
  _CountryItem('Sweden', 'SE', '+46'),
  _CountryItem('Austria', 'AT', '+43'),
  _CountryItem('Norway', 'NO', '+47'),
  _CountryItem('Belgium', 'BE', '+32'),
  _CountryItem('Switzerland', 'CH', '+41'),
  _CountryItem('Finland', 'FI', '+358'),
  _CountryItem('Italy', 'IT', '+39'),
  _CountryItem('Spain', 'ES', '+34'),
  _CountryItem('Luxembourg', 'LU', '+352'),
  _CountryItem('Greece', 'GR', '+30'),
  _CountryItem('United States', 'US', '+1'),
  _CountryItem('United Kingdom', 'GB', '+44'),
  _CountryItem('Russia', 'RU', '+7'),
];

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final AdminServerAuthService _authService = AdminServerAuthService();
  late final UserRepository _userRepository;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  _CountryItem _selectedCountry = _kCountryList.firstWhere((c) => c.code == 'SY');

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(_authService);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<_CountryItem>(
      context: context,
      backgroundColor: const Color(0xFFF7F9FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.35,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Select country code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _kCountryList.length,
                      itemBuilder: (_, index) {
                        final country = _kCountryList[index];
                        final selected = country.code == _selectedCountry.code;
                        return ListTile(
                          title: Text('${country.name} (${country.code})'),
                          subtitle: Text(country.dialCode),
                          trailing: Radio<String>(
                            value: country.code,
                            groupValue: _selectedCountry.code,
                            onChanged: (_) => Navigator.pop(sheetContext, country),
                          ),
                          selected: selected,
                          onTap: () => Navigator.pop(sheetContext, country),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedCountry = picked);
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _userRepository.createUser({
        'username': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneComplete': '${_selectedCountry.dialCode}${_phoneController.text.trim()}',
        'phoneCountryCode': _selectedCountry.dialCode,
        'phoneCountryIso': _selectedCountry.code,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create user: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Widget _field(TextEditingController c, String label, {TextInputType? type, String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      keyboardType: type,
      validator: validator,
      decoration: _dec(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Farmers Admin',
      sideMenu: const SideMenu(),
      content: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Add User',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a new account for transfer or normal admin use.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _field(_nameController, 'Username',
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field(_emailController, 'Email',
                                  type: TextInputType.emailAddress,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            SizedBox(
                              width: 130,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _pickCountry,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  side: const BorderSide(color: Color(0xFFE0E4EC)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  backgroundColor: Colors.white,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _selectedCountry.dialCode,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: _field(_phoneController, 'Phone Number')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _createUser,
                              icon: const Icon(Icons.person_add_alt_1, size: 16),
                              label: const Text('Create User'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LoadingOverlay(
              text: 'Creating user...',
              showBackdrop: true,
            ),
        ],
      ),
    );
  }
}
