// screens/user_management/deleted_user_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/models/deleted_user_model.dart';
import 'package:farmers_admin/models/post_model.dart';
import 'package:farmers_admin/models/user_model.dart';
import 'package:farmers_admin/repositories/user_repository.dart';
import 'package:farmers_admin/screens/post_management/edit_post_screen.dart';
import 'package:farmers_admin/services/deleted_users_api_service.dart';
import 'package:farmers_admin/services/admin_server_auth_service.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';

class DeletedUserDetailScreen extends StatefulWidget {
  final String userId;

  const DeletedUserDetailScreen({super.key, required this.userId});

  @override
  State<DeletedUserDetailScreen> createState() =>
      _DeletedUserDetailScreenState();
}

class _DeletedUserDetailScreenState extends State<DeletedUserDetailScreen> {
  late AdminServerAuthService _authService;
  late DeletedUsersApiService _apiService;
  late UserRepository _userRepository;
  DeletedUserFullDetails? _details;
  bool _isLoading = false;
  bool _isTransferring = false;
  bool _isTransferDialogOpen = false;
  bool _isNavigatingToEdit = false;
  String? _error;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  bool _isGridLoaded = false;
  final double rowHeight = 40;
  final double headerHeight = 50;

  String _searchQuery = '';
  String _tempSearchQuery = '';
  String? _selectedApproval;
  String? _tempSelectedApproval;
  String? _selectedCategory;
  String? _tempSelectedCategory;

  final Map<String, String> _categoryMapping = {
    'All': 'All',
    'Fruits': 'fruits',
    'Vegetables': 'vegetables',
    'Jam': 'jam',
    'Pomegranate': 'pomegranate',
    'Apples': 'apples',
    'Honey': 'honey',
    'Grains & Seeds': 'grain_seeds',
    'Fertilizers': 'fertilizers',
    'Animals Feed': 'animalsFeed',
    'Cheese': 'Cheese',
    'Leafy Green': 'leafyGreen',
    'Olive Oil': 'olive_oil',
    'Pesticides': 'pesticides',
    'Agricultural Tools': 'agriculturalTools',
    'Delivery': 'delivery',
    'Equipments': 'equipments',
    'Machine': 'machine',
    'Solar Panel': 'solar_panel',
    'Land Services': 'landServices',
    'Worker Services': 'workerServices',
    'Irrigation': 'irrigation',
    'Live Stock': 'live_stock',
    'Others': 'others',
  };
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authService = Provider.of<AdminServerAuthService>(
        context,
        listen: false,
      );
      _apiService = DeletedUsersApiService(_authService);
      _userRepository = UserRepository(_authService);
      _searchController = TextEditingController();
      _loadDetails();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final details = await _apiService.getFullDetails(widget.userId);
      setState(() {
        _details = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load user details: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEditPost(DeletedUserPost post) async {
    if (_isNavigatingToEdit) return;
    setState(() => _isNavigatingToEdit = true);

    try {
      final postModel = Post(
        postId: post.id,
        postTitle: post.title,
        postGender: '',
        postCity: post.city ?? '',
        postVillage: post.village ?? '',
        postLocation: '',
        postCategory: post.category ?? '',
        postUserVerified: false,
        postAge: 0,
        postPrice: 0,
        postAverageWeight: 0,
        postWeightCategory: null,
        postQuantity: 0,
        postWeight: 0,
        postDate: DateTime.now().millisecondsSinceEpoch,
        postIsApproved: (post.status ?? '').toLowerCase() == 'approved',
        postImages: post.images,
        postIsFeatured: false,
        postIsHomePost: false,
        postIsLiked: false,
        postIsColored: false,
        postIsSold: false,
        postIsSoldStatus: 0,
        postIsTop: false,
        postIsUpdate: false,
        postCancelApproved: false,
        postIsCancelled: false,
        postAdditionalDetails: post.description,
        postArea: 0,
        postLiquidQuantity: 0,
        postLiveStockCategory: null,
        postServiceType: null,
        postBarCode: post.barcode ?? '',
        postUserContact: _details!.user.phoneComplete ?? '',
        postUserId: _details!.user.uid,
        postUserImage: _details!.user.profileImage ?? '',
        postUserLocation: '',
        postUserLoginDate: DateTime.now().millisecondsSinceEpoch,
        postUserMail: _details!.user.userEmail,
        postUserName: _details!.user.userName,
        postViews: 0,
        postUserImageColor: '#cccccc',
        postCurrencyCategory: null,
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditPostScreen(
            post: postModel,
            sourceScreen: 'deleted_user_detail',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open edit screen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigatingToEdit = false);
      }
    }
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  List<DeletedUserPost> get _posts => _details?.posts ?? [];

  Future<void> _showTransferPostsDialog() async {
    if (_details == null || _posts.isEmpty || _isTransferDialogOpen) return;

    bool isTargetsLoadingOverlayVisible = false;
    try {
      setState(() => _isTransferDialogOpen = true);
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black45,
        builder: (_) =>
            const LoadingOverlay(text: 'Loading target accounts...'),
      );
      isTargetsLoadingOverlayVisible = true;
      final users = await _userRepository.getUsers(limit: 500);
      if (!mounted) return;
      final targets = users.where((u) => u.uid != widget.userId).toList();
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      isTargetsLoadingOverlayVisible = false;
      if (!mounted) return;
      if (targets.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No live target users found')),
        );
        return;
      }

      UserModel selectedUser = targets.first;
      final sourceUserName = _details?.user.userName ?? 'Deleted account';

      await showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.white,
                title: const Text('Transfer Posts'),
                content: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Move ${_posts.length} posts from "$sourceUserName" to another active account.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 38,
                        child: DropdownButtonFormField<String>(
                          value: selectedUser.uid,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.green,
                                width: 1,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 0,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            size: 20,
                            color: Colors.grey,
                          ),
                          dropdownColor: Colors.white,
                          menuMaxHeight: 150,
                          items: targets
                              .map(
                                (u) => DropdownMenuItem<String>(
                                  value: u.uid,
                                  child: Text(
                                    '${u.userName} • ${u.userEmail}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            final match = targets
                                .where((u) => u.uid == value)
                                .toList();
                            if (match.isNotEmpty) {
                              setDialogState(() {
                                selectedUser = match.first;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    style: ButtonStyle(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return Colors.transparent; // remove hover background
                        }
                        return null;
                      }),
                    ),
                    onPressed: _isTransferring
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          6,
                        ), // reduced border radius
                      ),
                    ),
                    onPressed: _isTransferring
                        ? null
                        : () async {
                            bool isTransferLoadingOverlayVisible = false;
                            setState(() => _isTransferring = true);
                            if (!mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.black45,
                              builder: (_) => const LoadingOverlay(
                                text: 'Transferring posts...',
                              ),
                            );
                            isTransferLoadingOverlayVisible = true;
                            try {
                              final result = await _apiService
                                  .transferDeletedUserPosts(
                                    userId: widget.userId,
                                    targetUserId: selectedUser.uid,
                                  );

                              if (!mounted) return;

                              if (Navigator.of(
                                context,
                                rootNavigator: true,
                              ).canPop()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                              }
                              isTransferLoadingOverlayVisible = false;
                              Navigator.pop(dialogContext);
                              Navigator.of(context).pop(true);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Transferred ${result['transferredPosts'] ?? 0} posts to ${selectedUser.userName}',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (isTransferLoadingOverlayVisible &&
                                  mounted &&
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).canPop()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                isTransferLoadingOverlayVisible = false;
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Transfer failed: $e'),
                                  ),
                                );
                              }
                            } finally {
                              if (isTransferLoadingOverlayVisible &&
                                  mounted &&
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).canPop()) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();
                                isTransferLoadingOverlayVisible = false;
                              }
                              if (mounted) {
                                setState(() => _isTransferring = false);
                              }
                            }
                          },
                    icon: _isTransferring
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.swap_horiz),
                    label: const Text('Transfer'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (isTargetsLoadingOverlayVisible &&
          mounted &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        isTargetsLoadingOverlayVisible = false;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load target users: $e')),
      );
    } finally {
      if (isTargetsLoadingOverlayVisible &&
          mounted &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        isTargetsLoadingOverlayVisible = false;
      }
      if (mounted) {
        setState(() => _isTransferDialogOpen = false);
      }
    }
  }

  String _formatDisplayText(String text) {
    if (text.isEmpty) return text;
    final specialCases = {
      'fruits': 'Fruits',
      'vegetables': 'Vegetables',
      'jam': 'Jam',
      'pomegranate': 'Pomegranate',
      'apples': 'Apples',
      'honey': 'Honey',
      'grain_seeds': 'Grains & Seeds',
      'fertilizers': 'Fertilizers',
      'animalsFeed': 'Animals Feed',
      'Cheese': 'Cheese',
      'leafyGreen': 'Leafy Green',
      'olive_oil': 'Olive Oil',
      'pesticides': 'Pesticides',
      'agriculturalTools': 'Agricultural Tools',
      'delivery': 'Delivery',
      'equipments': 'Equipments',
      'machine': 'Machine',
      'solar_panel': 'Solar Panel',
      'landServices': 'Land Services',
      'workerServices': 'Worker Services',
      'irrigation': 'Irrigation',
      'live_stock': 'Live Stock',
      'others': 'Others',
    };
    if (specialCases.containsKey(text)) {
      return specialCases[text]!;
    }
    String result = text
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .trim();
    return result
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  bool _matchesFilters(DeletedUserPost post) {
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final title = post.title.toLowerCase();
      final category = (post.category ?? '').toLowerCase();
      final city = (post.city ?? '').toLowerCase();
      final village = (post.village ?? '').toLowerCase();
      final barcode = (post.barcode ?? '').toLowerCase();
      if (!title.contains(query) &&
          !category.contains(query) &&
          !city.contains(query) &&
          !village.contains(query) &&
          !barcode.contains(query)) {
        return false;
      }
    }

    if (_selectedApproval != null && _selectedApproval != "All") {
      final status = (post.status ?? 'pending').toLowerCase();
      final approvalStr = status == 'approved' ? 'Approved' : 'Pending';
      if (_selectedApproval != approvalStr) return false;
    }

    if (_selectedCategory != null && _selectedCategory != "All") {
      final postCat = (post.category ?? '')
          .trim()
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('&', '');
      final selectedDbValue = (_categoryMapping[_selectedCategory] ?? '')
          .toLowerCase()
          .replaceAll(' ', '')
          .replaceAll('_', '')
          .replaceAll('&', '');
      if (postCat != selectedDbValue) return false;
    }

    return true;
  }

  List<DeletedUserPost> get _filteredPosts {
    final filtered = _posts.where(_matchesFilters).toList();
    filtered.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));
    return filtered;
  }

  int get totalPages => (_filteredPosts.length / _rowsPerPage).ceil();

  List<DeletedUserPost> get _paginatedPosts {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;
    return _filteredPosts.sublist(
      startIndex,
      endIndex > _filteredPosts.length ? _filteredPosts.length : endIndex,
    );
  }

  void _updatePlutoGridRows() {
    if (mounted) {
      setState(() {});
    }
  }

  void _applyFilters() {
    setState(() {
      _searchQuery = _tempSearchQuery;
      _selectedApproval = _tempSelectedApproval;
      _selectedCategory = _tempSelectedCategory;
      _currentPage = 1;
    });
    _updatePlutoGridRows();
  }

  List<PlutoColumn> _getColumns() {
    return [
      PlutoColumn(
        title: '#',
        field: 'numbering',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 60,
        minWidth: 40,
      ),
      PlutoColumn(
        title: 'BarCode',
        field: 'barcode',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Post Title',
        field: 'post_title',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 200,
        minWidth: 150,
      ),
      PlutoColumn(
        title: 'Category',
        field: 'category',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
        minWidth: 120,
        renderer: (ctx) {
          final rawValue = ctx.cell.value?.toString() ?? '';
          final formattedValue = _formatDisplayText(rawValue);
          return Text(
            formattedValue,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          );
        },
      ),
      PlutoColumn(
        title: 'City',
        field: 'city',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Village',
        field: 'village',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
      ),
      PlutoColumn(
        title: 'Approval Status',
        field: 'approvalStatus',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 150,
        minWidth: 120,
        renderer: (ctx) {
          final value = ctx.cell.value?.toString() ?? 'Pending';
          final isApproved = value == 'Approved';
          final statusColor = isApproved ? Colors.green : Colors.orange;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        enableEditingMode: false,
        width: 120,
        minWidth: 100,
        renderer: (ctx) {
          final postId = ctx.row.cells['postId']?.value?.toString() ?? '';
          final post = _posts.firstWhere(
            (p) => p.id == postId,
            orElse: () => _posts.first,
          );
          return Align(
            alignment: Alignment.center,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit, size: 18, color: Colors.green),
              tooltip: 'Edit Post',
              onPressed: _isNavigatingToEdit
                  ? null
                  : () => _navigateToEditPost(post),
            ),
          );
        },
      ),
    ];
  }

  List<PlutoRow> _buildRows() {
    final rows = <PlutoRow>[];
    int counter = ((_currentPage - 1) * _rowsPerPage) + 1;

    for (final post in _paginatedPosts) {
      final approvalStatus =
          (post.status ?? 'pending').toLowerCase() == 'approved'
          ? 'Approved'
          : 'Pending';

      rows.add(
        PlutoRow(
          cells: {
            'numbering': PlutoCell(value: counter.toString()),
            'postId': PlutoCell(value: post.id),
            'barcode': PlutoCell(value: post.barcode ?? ''),
            'post_title': PlutoCell(value: post.title),
            'category': PlutoCell(value: post.category ?? ''),
            'city': PlutoCell(value: post.city ?? ''),
            'village': PlutoCell(value: post.village ?? ''),
            'approvalStatus': PlutoCell(value: approvalStatus),
            'actions': PlutoCell(value: ''),
          },
        ),
      );
      counter++;
    }

    return rows;
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    final user = _details!.user;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        user.profileImage != null &&
                            user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child:
                        user.profileImage == null || user.profileImage!.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: const Text('DELETED'),
                              backgroundColor: Colors.red[100],
                              labelStyle: TextStyle(color: Colors.red[800]),
                            ),
                            if (user.isAdmin)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Chip(
                                  label: Text('ADMIN'),
                                  backgroundColor: Colors.purple,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Contact Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Phone',
                    '${user.phoneCountryCode ?? ''} ${user.phoneComplete ?? 'N/A'}',
                  ),
                  _buildInfoRow('Account Created', _formatDate(user.createdAt)),
                  _buildInfoRow('Deleted On', _formatDate(user.deletedAt)),
                  _buildInfoRow('User ID', user.uid),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Post Limits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Post Limits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Post Limit', '${user.userPostLimit}'),
                  _buildInfoRow('Used', '${user.userPostLimitUsed}'),
                  _buildInfoRow('Edit Limit', '${user.userUpdatePostLimit}'),
                  _buildInfoRow(
                    'Min Following Required',
                    '${user.userFollowing}',
                  ),
                  _buildInfoRow(
                    'Post Limit Days',
                    '${user.userTotalPostsTime}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedUserPostsOnly() {
    final user = _details!.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage:
                        user.profileImage != null &&
                            user.profileImage!.isNotEmpty
                        ? NetworkImage(user.profileImage!)
                        : null,
                    child:
                        user.profileImage == null || user.profileImage!.isEmpty
                        ? const Icon(Icons.person, size: 32)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.userEmail,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: const Text('DELETED'),
                              backgroundColor: Colors.red[100],
                              labelStyle: TextStyle(color: Colors.red[800]),
                            ),
                            Chip(
                              label: Text(
                                'Posts: ${_details!.stats.postsCount}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Posts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildPostsTab()),
      ],
    );
  }

  Widget _buildPostsTab() {
    final posts = _details!.posts;
    if (posts.isEmpty) {
      return const Center(child: Text('No posts found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post.images.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: post.images.length,
                      itemBuilder: (context, imgIndex) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.images[imgIndex],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (post.description != null && post.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      post.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(post.status ?? 'unknown'),
                      backgroundColor: post.status == 'active'
                          ? Colors.green[100]
                          : Colors.grey[200],
                    ),
                    const Spacer(),
                    if (post.date != null)
                      Text(
                        post.date!,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context, bool isMobile) {
    return isMobile
        ? Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, barcode or location...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: (val) {
                  _tempSearchQuery = val;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _tempSelectedApproval,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: const Text("Approval"),
                      dropdownColor: Colors.white,
                      menuMaxHeight: 150,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text("All"),
                        ),
                        DropdownMenuItem<String?>(
                          value: "Approved",
                          child: Text("Approved"),
                        ),
                        DropdownMenuItem<String?>(
                          value: "Pending",
                          child: Text("Pending"),
                        ),
                      ],
                      onChanged: (val) {
                        _tempSelectedApproval = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _tempSelectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: const Text("Category"),
                      dropdownColor: Colors.white,
                      menuMaxHeight: 150,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text("All"),
                        ),
                        DropdownMenuItem<String?>(
                          value: "Fruits",
                          child: Text("Fruits"),
                        ),
                        DropdownMenuItem<String?>(
                          value: "Vegetables",
                          child: Text("Vegetables"),
                        ),
                      ],
                      onChanged: (val) {
                        _tempSelectedCategory = val;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SvgPicture.asset(
      'images/ic_farm_filter.svg',
      height: 12,
      width: 12,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
    const SizedBox(width: 4),
    const Text(
      "APPLY",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    ),
  ],
),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _tempSearchQuery = '';
                          _searchQuery = '';
                          _tempSelectedApproval = null;
                          _selectedApproval = null;
                          _tempSelectedCategory = null;
                          _selectedCategory = null;
                          _currentPage = 1;
                          _applyFilters();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("REMOVE FILTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 38,
                                child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Search by title, barcode or location...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                    onChanged: (val) {
                      _tempSearchQuery = val;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 38,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _tempSelectedApproval,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 0,
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                    hint: const Text(
                      "Approval",
                      style: TextStyle(fontSize: 12),
                    ),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 150,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text("All", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem<String?>(
                        value: "Approved",
                        child: Text("Approved", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem<String?>(
                        value: "Pending",
                        child: Text("Pending", style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (val) {
                      _tempSelectedApproval = val;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 38,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _tempSelectedCategory,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 0,
                      ),
                    ),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                    hint: const Text(
                      "Category",
                      style: TextStyle(fontSize: 12),
                    ),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 150,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text("All", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem<String?>(
                        value: "Fruits",
                        child: Text("Fruits", style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem<String?>(
                        value: "Vegetables",
                        child: Text(
                          "Vegetables",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      _tempSelectedCategory = val;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    SvgPicture.asset(
      'images/ic_farm_filter.svg',
      height: 12,
      width: 12,
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
    ),
    const SizedBox(width: 4),
    const Text(
      "APPLY",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    ),
  ],
),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _tempSearchQuery = '';
                            _searchQuery = '';
                            _tempSelectedApproval = null;
                            _selectedApproval = null;
                            _tempSelectedCategory = null;
                            _selectedCategory = null;
                            _currentPage = 1;
                            _applyFilters();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        child: const Text("CLEAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Widget _buildPostsLikeManagement(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final hasFilters =
        _searchQuery.isNotEmpty ||
        (_selectedApproval != null && _selectedApproval != "All") ||
        (_selectedCategory != null && _selectedCategory != "All");

    if (_isLoading) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: LoadingOverlay(text: 'Loading...', showBackdrop: false),
        ),
      );
    }

    if (_posts.isEmpty) {
      return Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'images/image_farm_nothing_remains.png',
                  height: 150,
                ),

                const SizedBox(height: 24),
                const Text(
                  "No posts available",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "This deleted user has no posts",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_filteredPosts.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('images/image_farm_nothing_remains.png', height: 150),
              const SizedBox(height: 24),
              const Text(
                "You're all caught up!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "No posts found",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gridHeight = (_paginatedPosts.length * rowHeight) + headerHeight;

    return Column(
      children: [
        SizedBox(
          height: (_paginatedPosts.length * rowHeight) + headerHeight,
          key: ValueKey(
            'deleted-user-grid-${_currentPage}-${_rowsPerPage}-${_searchQuery.hashCode}-${_selectedApproval ?? ''}-${_selectedCategory ?? ''}-${_filteredPosts.length}',
          ),
          child: PlutoGrid(
            columns: _getColumns(),
            rows: _buildRows(),
            onLoaded: (event) {
              event.stateManager.setShowColumnFilter(false);
              setState(() => _isGridLoaded = true);
            },
            configuration: PlutoGridConfiguration(
              columnSize: const PlutoGridColumnSizeConfig(
                autoSizeMode: PlutoAutoSizeMode.scale,
              ),
              style: PlutoGridStyleConfig(
                rowHeight: 40,
                columnTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                cellTextStyle: const TextStyle(fontSize: 12),
                enableColumnBorderHorizontal: true,
                enableCellBorderHorizontal: true,
                enableColumnBorderVertical: true,
                enableRowColorAnimation: false,
                oddRowColor: Colors.white,
                evenRowColor: Colors.grey.shade50,
              ),
            ),
          ),
        ),

        _buildDeletedPostsPagination(context, isMobile),
      ],
    );
  }

  Widget _buildDeletedPostsPagination(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 12 : 5,
        horizontal: isMobile ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                              _updatePlutoGridRows();
                            }
                          : null,
                    ),
                    Text(
                      '$_currentPage / $totalPages',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      onPressed: _currentPage < totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                              _updatePlutoGridRows();
                            }
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _rowsPerPage,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          items: [5, 10, 20, 50]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$e',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _rowsPerPage = val;
                                _currentPage = 1;
                              });
                              _updatePlutoGridRows();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "/ Page",
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                          _updatePlutoGridRows();
                        }
                      : null,
                ),
                ...List.generate(totalPages > 7 ? 7 : totalPages, (index) {
                  int pageNum;
                  if (totalPages <= 7) {
                    pageNum = index + 1;
                  } else if (_currentPage <= 4) {
                    pageNum = index + 1;
                  } else if (_currentPage >= totalPages - 3) {
                    pageNum = totalPages - 6 + index;
                  } else {
                    pageNum = _currentPage - 3 + index;
                  }

                  final isActive = pageNum == _currentPage;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _currentPage = pageNum);
                      _updatePlutoGridRows();
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFE8F5E9)
                            : Colors.white,
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF4CAF50)
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          color: isActive
                              ? const Color(0xFF4CAF50)
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                  onPressed: _currentPage < totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                          _updatePlutoGridRows();
                        }
                      : null,
                ),
                const SizedBox(width: 20),
                Row(
                  children: [
                    Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _rowsPerPage,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
                          items: [5, 10, 20, 50]
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    '$e',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _rowsPerPage = val;
                                _currentPage = 1;
                              });
                              _updatePlutoGridRows();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      "/ Page",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildActivityTab() {
    final follows = _details!.follows;
    final stats = _details!.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Likes & Views
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Engagement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Likes Given', '${stats.likesGiven}'),
                  _buildInfoRow('Likes Received', '${stats.likesReceived}'),
                  _buildInfoRow('Total Views', '${stats.viewsReceived}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Blocks
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Blocks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Blocks Given', '${stats.blocksGiven}'),
                  _buildInfoRow('Blocks Received', '${stats.blocksReceived}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Following
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Following (${follows.following.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (follows.following.isEmpty)
                    const Text('Not following anyone')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: follows.following.map((f) {
                        return Chip(
                          avatar: const CircleAvatar(
                            child: Icon(Icons.person, size: 16),
                          ),
                          label: Text(f.username),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Followers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Followers (${follows.followers.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (follows.followers.isEmpty)
                    const Text('No followers')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: follows.followers.map((f) {
                        return Chip(
                          avatar: const CircleAvatar(
                            child: Icon(Icons.person, size: 16),
                          ),
                          label: Text(f.username),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationsTab() {
    final messages = _details!.messages;
    final feedback = _details!.feedback;
    final reports = _details!.reports;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Messages Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  _buildInfoRow('Messages Sent', '${messages.sent}'),
                  _buildInfoRow('Messages Received', '${messages.received}'),
                  const SizedBox(height: 8),
                  Text(
                    'Conversation Partners (${messages.conversationPartners.length})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  if (messages.conversationPartners.isEmpty)
                    const Text('No conversations')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: messages.conversationPartners.map((p) {
                        return Chip(
                          avatar: const CircleAvatar(
                            child: Icon(Icons.person, size: 16),
                          ),
                          label: Text(p.username),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Feedback
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback (${feedback.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (feedback.isEmpty)
                    const Text('No feedback submitted')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: feedback.length,
                      itemBuilder: (context, index) {
                        final fb = feedback[index];
                        return ListTile(
                          title: Text(fb.type ?? 'General'),
                          subtitle: Text(fb.message ?? ''),
                          trailing: fb.rating != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(
                                    fb.rating!,
                                    (i) => const Icon(
                                      Icons.star,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reports Filed (${reports.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (reports.isEmpty)
                    const Text('No reports filed')
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        final report = reports[index];
                        return ListTile(
                          title: Text(
                            report.postTitle ?? 'Post #${report.postId}',
                          ),
                          subtitle: Text(report.additionalDetails ?? ''),
                          trailing: report.reportDate != null
                              ? Text(report.reportDate!)
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionsTab() {
    final commissions = _details!.commissions;
    if (commissions.isEmpty) {
      return const Center(child: Text('No commission transfers'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final c = commissions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('${c.commissionAmount} ${c.currency ?? ''}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c.name} - ${c.bank}'),
                if (c.postCode != null) Text('Post: ${c.postCode}'),
              ],
            ),
            trailing: Chip(
              label: Text(c.status ?? 'pending'),
              backgroundColor: c.status == 'completed'
                  ? Colors.green[100]
                  : c.status == 'rejected'
                  ? Colors.red[100]
                  : Colors.orange[100],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWorkingStatusTab() {
    final workingStatus = _details!.workingStatus;
    if (workingStatus.isEmpty) {
      return const Center(child: Text('No working status entries'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workingStatus.length,
      itemBuilder: (context, index) {
        final ws = workingStatus[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: const Text('App Message'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ws.messageAr != null && ws.messageAr!.isNotEmpty)
                  Text('AR: ${ws.messageAr}'),
                if (ws.messageEn != null && ws.messageEn!.isNotEmpty)
                  Text('EN: ${ws.messageEn}'),
                if (ws.createdAt != null)
                  Text(
                    'Created: ${ws.createdAt}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const SideMenu(),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.of(context).size.width >= 1024)
              const SizedBox(width: 200, child: SideMenu()),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppHeader(),
                      const SizedBox(height: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const SizedBox(width: 4),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Deleted User Posts',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineLarge
                                            ?.copyWith(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Deleted Users / Posts',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: Colors.grey,
                                              fontSize: 10,
                                              letterSpacing: 0.5,
                                              fontWeight: FontWeight.normal,
                                              fontFamily: 'Roboto',
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_posts.isNotEmpty)
                                    Text(
                                      '${_filteredPosts.length} posts',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (_posts.isNotEmpty)
                                    const SizedBox(width: 12),
                                  if (_posts.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed:
                                          _isLoading ||
                                              _isTransferring ||
                                              _isTransferDialogOpen
                                          ? null
                                          : _showTransferPostsDialog,
                                      icon: _isTransferring
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.swap_horiz,
                                              size: 16,
                                              color: Colors.white,
                                            ),

                                      label: const Text(
                                        'Transfer Posts',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.transparent,
                                        ),
                                        backgroundColor: Colors.green,
                                        surfaceTintColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildFilters(
                            context,
                            MediaQuery.of(context).size.width < 600,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            // height: 760,
                            child: _buildPostsLikeManagement(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
