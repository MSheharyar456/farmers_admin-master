import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pluto_grid/pluto_grid.dart';

class UserFeedbackScreen extends StatefulWidget {
  const UserFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<UserFeedbackScreen> createState() => _UserFeedbackScreenState();
}

class _UserFeedbackScreenState extends State<UserFeedbackScreen> {
  late PlutoGridStateManager stateManager;
  String _searchQuery = '';
  String? _selectedType;
  int _currentPage = 1;
  int _rowsPerPage = 10;
  final double rowHeight = 50;
  final double headerHeight = 50;
  Map<String, String> userNameCache = {};

  List<PlutoColumn> _getColumns(BuildContext context, bool isMobile) {
    return [
      PlutoColumn(
        title: 'No',
        field: 'no',
        type: PlutoColumnType.number(),
        width: isMobile ? 50 : 60,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'User Name',
        field: 'userName',
        type: PlutoColumnType.text(),
        width: isMobile ? 100 : 150,
        enableEditingMode: false,
      ),
      PlutoColumn(
        title: 'Message',
        field: 'message',
        type: PlutoColumnType.text(),
        width: isMobile ? 150 : 300,
        enableEditingMode: false,
        renderer: (rendererContext) {
          final value = rendererContext.cell.value?.toString() ?? '';
          return Container(
            padding: const EdgeInsets.all(8),
            child: Tooltip(
              message: value,
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        },
      ),
      if (!isMobile)
        PlutoColumn(
          title: 'Type',
          field: 'type',
          type: PlutoColumnType.text(),
          width: 120,
          enableEditingMode: false,
          renderer: (rendererContext) {
            final value = rendererContext.cell.value?.toString() ?? 'General';
            Color typeColor;
            IconData typeIcon;

            switch (value) {
              case 'Suggestion':
                typeColor = Colors.blue;
                typeIcon = Icons.lightbulb_outline;
                break;
              case 'Complaint':
                typeColor = Colors.red;
                typeIcon = Icons.report_problem_outlined;
                break;
              case 'General':
                typeColor = Colors.green;
                typeIcon = Icons.chat_bubble_outline;
                break;
              default:
                typeColor = Colors.grey;
                typeIcon = Icons.help_outline;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(typeIcon, color: typeColor, size: 16),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      if (!isMobile)
        PlutoColumn(
          title: 'Date',
          field: 'date',
          type: PlutoColumnType.text(),
          width: 150,
          enableEditingMode: false,
        ),
      PlutoColumn(
        title: 'Actions',
        field: 'actions',
        type: PlutoColumnType.text(),
        width: isMobile ? 80 : 120,
        minWidth: 80,
        enableEditingMode: false,
        enableFilterMenuItem: false,
        enableSorting: false,
        renderer: (ctx) {
          final feedbackMap = ctx.row.cells['feedbackData']?.value;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                      Icons.visibility, size: 18, color: Colors.blue),
                  tooltip: 'View Details',
                  splashRadius: 20,
                  onPressed: () {
                    if (feedbackMap != null && feedbackMap is Map) {
                      _showFeedbackDetails(
                          Map<String, dynamic>.from(feedbackMap));
                    }
                  },
                ),
              ),
              if (!isMobile) const SizedBox(width: 8),
              if (!isMobile)
                Container(
                  height: 30,
                  width: 30,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: SvgPicture.asset(
                      'images/ic_farm_trash.svg',
                      width: 18,
                      height: 18,
                      color: Colors.red,
                    ),
                    tooltip: 'Delete Feedback',
                    splashRadius: 20,
                    onPressed: () async {
                      if (feedbackMap != null && feedbackMap is Map) {
                        final String feedbackId = feedbackMap['id'];

                        await showDeleteDialog(
                          context: context,
                          title: "Delete Feedback",
                          message: "Are you sure you want to delete this feedback?",
                          onConfirm: () async {
                            await FirebaseDatabase.instance.ref('userFeedback/$feedbackId').remove();
                            if (!context.mounted) return;

                            // optional: trigger a UI refresh
                            setState(() {});

                            // (no need for another snackbar because your showDeleteDialog already shows one)
                          },
                        );
                      }
                    },

                  ),
                ),
            ],
          );
        },
      ),
      PlutoColumn(
        title: 'Feedback Data',
        field: 'feedbackData',
        type: PlutoColumnType.text(),
        hide: true,
        enableEditingMode: false,
      ),
    ];
  }

  Future<void> _showFeedbackDetails(Map<String, dynamic> feedbackData) async {
    // Fetch user auth data
    String userName = 'Unknown User';
    String userEmail = 'No email';
    String userContact = 'No contact';
    bool userIsVerified = false;

    final userId = feedbackData['userId'] ?? '';
    if (userId.isNotEmpty) {
      try {
        final userSnapshot = await FirebaseDatabase.instance
            .ref('UsersAuthData/$userId')
            .get();

        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          userName = userData['userName'] ?? 'Unknown User';
          userEmail = userData['userMail'] ?? 'No email';
          userContact = userData['userContact'] ?? 'No contact';
          userIsVerified = userData['userIsVerified'] ?? false;
        }
      } catch (e) {
        print('Error fetching user auth data: $e');
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // User Profile Section
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),

                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade300,
                              border: Border.all(color: Colors.grey.shade400, width: 2),
                            ),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 20),
                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        userName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (userIsVerified)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: userIsVerified ? Colors.blue.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              userIsVerified ? Icons.check_circle : Icons.cancel,
                                              size: 14,
                                              color: userIsVerified ? Colors.blue.shade600 : Colors.red.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              userIsVerified ? 'Verified' : 'Unverified',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: userIsVerified ? Colors.blue.shade600 : Colors.red.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  userEmail,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userContact,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),


                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 10),

                      child: Column(
                        children: [
                          // Feedback Type
                          _buildDetailRow(
                            "Feedback Type",
                            feedbackData['type'] ?? 'General',
                          ),
                          const Divider(thickness: 1, color: Colors.grey),
                          const SizedBox(height: 16),

                          // Gender
                          _buildDetailRow(
                            "Gender",
                            feedbackData['gender'] ?? 'Not specified',
                          ),
                          const Divider(thickness: 1, color: Colors.grey),
                          const SizedBox(height: 16),

                          // Description/Message
                          Align(
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              "Description",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              feedbackData['message'] ?? 'No message',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Date
                    // _buildDetailRow(
                    //   "Query Date",
                    //   feedbackData['formattedDate'] ?? 'N/A',
                    // ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return SizedBox(
      width: double.infinity, // 👈 Makes the row full width
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right, // optional for neat alignment
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFADB5BD),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Future<String> _getUserName(String userId) async {
    if (userNameCache.containsKey(userId)) {
      return userNameCache[userId]!;
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('UsersAuthData/$userId/userName')
          .get();

      if (snapshot.exists) {
        final userName = snapshot.value.toString();
        userNameCache[userId] = userName;
        return userName;
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }

    userNameCache[userId] = 'Unknown User';
    return 'Unknown User';
  }

  bool _matchesFilters(Map<String, dynamic> feedbackData) {
    if (_searchQuery.isNotEmpty) {
      final message = feedbackData['message']?.toString().toLowerCase() ?? '';
      final userName = feedbackData['userName']?.toString().toLowerCase() ?? '';
      final type = feedbackData['type']?.toString().toLowerCase() ?? '';

      if (!message.contains(_searchQuery) &&
          !userName.contains(_searchQuery) &&
          !type.contains(_searchQuery)) {
        return false;
      }
    }

    if (_selectedType != null && _selectedType!.isNotEmpty) {
      final feedbackType = feedbackData['type']?.toString();
      if (_selectedType != feedbackType) {
        return false;
      }
    }

    return true;
  }

  void _applyFilters() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                child: Column(
                  children: [
                    // Header Row
                    isMobile
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "User Feedback",
                          style: Theme
                              .of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Dashboard / User Feedback",
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "User Feedback",
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Dashboard / User Feedback",
                                style: Theme
                                    .of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // FILTERS
                    isMobile
                        ? Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by message, user, or type...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                hint: const Text("Type"),
                                items: const [
                                  DropdownMenuItem<String?>(
                                      value: null, child: Text("All Types")),
                                  DropdownMenuItem<String?>(value: "Suggestion",
                                      child: Text("Suggestion")),
                                  DropdownMenuItem<String?>(value: "Complaint",
                                      child: Text("Complaint")),
                                  DropdownMenuItem<String?>(
                                      value: "General", child: Text("General")),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedType = val;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: SvgPicture.asset(
                                'images/ic_farm_filter.svg',
                                height: 20,
                                width: 20,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search by message, user name, or type...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.green, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.toLowerCase();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String?>(
                            value: _selectedType,
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.green, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                            hint: const Text("Filter by Type"),
                            items: const [
                              DropdownMenuItem<String?>(
                                  value: null, child: Text("All Types")),
                              DropdownMenuItem<String?>(value: "Suggestion",
                                  child: Text("Suggestion")),
                              DropdownMenuItem<String?>(
                                  value: "Complaint", child: Text("Complaint")),
                              DropdownMenuItem<String?>(
                                  value: "General", child: Text("General")),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedType = val;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _applyFilters,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'images/ic_farm_filter.svg',
                                height: 20,
                                width: 20,
                                color: Colors.white,
                              ),
                              if (isDesktop) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  "APPLY FILTERS",
                                  style: TextStyle(color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // PlutoGrid Section
                    StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance
                          .ref('userFeedback')
                          .onValue,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            height: 400,
                            child: Center(child: CircularProgressIndicator(color: Colors.green,)),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.snapshot.value == null) {
                          return SizedBox(
                            height: 400,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                      'images/image_farm_nothing_remains.png',
                                      height: isMobile ? 120 : 150),
                                  const SizedBox(height: 24),
                                  Text(
                                    "You're all caught up!",
                                    style: TextStyle(
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No feedback found",
                                    style: TextStyle(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final data = snapshot.data!.snapshot.value as Map;
                        final feedbackData = Map<String, dynamic>.from(data);

                        return FutureBuilder<List<PlutoRow>>(
                          future: _buildFeedbackRows(feedbackData),
                          builder: (context, rowSnapshot) {
                            if (rowSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                height: 400,
                                child: Center(
                                    child: CircularProgressIndicator(color: Colors.green,)),
                              );
                            }

                            final rows = rowSnapshot.data ?? [];

                            if (rows.isEmpty) {
                              return SizedBox(
                                height: 400,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                          'images/image_farm_nothing_remains.png',
                                          height: isMobile ? 120 : 150),
                                      const SizedBox(height: 24),
                                      Text(
                                        "You're all caught up!",
                                        style: TextStyle(
                                          fontSize: isMobile ? 18 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "No feedback found matching your filters.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isMobile ? 14 : 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Pagination logic
                            int totalRows = rows.length;
                            int totalPages = (totalRows / _rowsPerPage).ceil();
                            int startIndex = (_currentPage - 1) * _rowsPerPage;
                            int endIndex = startIndex + _rowsPerPage;
                            if (endIndex > totalRows) endIndex = totalRows;

                            final paginatedRows = rows.sublist(
                                startIndex, endIndex);

                            return Column(
                              children: [
                                SizedBox(
                                  height: (paginatedRows.length * rowHeight) +
                                      headerHeight,
                                  child: PlutoGrid(
                                    columns: _getColumns(context, isMobile),
                                    rows: paginatedRows,
                                    onLoaded: (event) {
                                      stateManager = event.stateManager;
                                      stateManager.setShowColumnFilter(false);
                                    },
                                    configuration: PlutoGridConfiguration(
                                      columnSize: const PlutoGridColumnSizeConfig(
                                        autoSizeMode: PlutoAutoSizeMode.scale,
                                      ),
                                      style: PlutoGridStyleConfig(
                                        rowHeight: 50,
                                        columnTextStyle: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ),

                                // Responsive Pagination Footer
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isMobile ? 12 : 16,
                                    horizontal: isMobile ? 4 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
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
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.arrow_back_ios_new,
                                                size: 16),
                                            onPressed: _currentPage > 1
                                                ? () =>
                                                setState(() => _currentPage--)
                                                : null,
                                          ),
                                          ...List.generate(
                                            totalPages > 5 ? 5 : totalPages,
                                                (index) {
                                              int pageNum = index + 1;
                                              bool isActive = pageNum ==
                                                  _currentPage;
                                              return GestureDetector(
                                                onTap: () =>
                                                    setState(() =>
                                                    _currentPage = pageNum),
                                                child: Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(horizontal: 2),
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 10,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? const Color(
                                                        0xFFE8F5E9)
                                                        : Colors.white,
                                                    border: Border.all(
                                                      color: isActive
                                                          ? const Color(
                                                          0xFF4CAF50)
                                                          : Colors.grey
                                                          .shade300,
                                                    ),
                                                    borderRadius: BorderRadius
                                                        .circular(6),
                                                  ),
                                                  child: Text(
                                                    '$pageNum',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isActive
                                                          ? const Color(
                                                          0xFF4CAF50)
                                                          : Colors.black87,
                                                      fontWeight: FontWeight
                                                          .w500,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16),
                                            onPressed: _currentPage < totalPages
                                                ? () =>
                                                setState(() => _currentPage++)
                                                : null,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .center,
                                        children: [
                                          Container(
                                            height: 34,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius: BorderRadius
                                                  .circular(6),
                                              color: Colors.white,
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                value: _rowsPerPage,
                                                dropdownColor: Colors.white,
                                                icon: const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: 18),
                                                items: [5, 10, 20, 50]
                                                    .map((e) =>
                                                    DropdownMenuItem(
                                                        value: e, child: Text(
                                                        '$e')))
                                                    .toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      _rowsPerPage = val;
                                                      _currentPage = 1;
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text("/ Page", style: TextStyle(
                                              color: Colors.black54)),
                                        ],
                                      ),
                                    ],
                                  )
                                      : Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.arrow_back_ios_new, size: 16,
                                            color: Colors.grey),
                                        onPressed: _currentPage > 1
                                            ? () =>
                                            setState(() => _currentPage--)
                                            : null,
                                      ),
                                      ...List.generate(totalPages, (index) {
                                        int pageNum = index + 1;
                                        bool isActive = pageNum == _currentPage;
                                        return GestureDetector(
                                          onTap: () =>
                                              setState(() =>
                                              _currentPage = pageNum),
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 3),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: isActive ? const Color(
                                                  0xFFE8F5E9) : Colors.white,
                                              border: Border.all(
                                                color: isActive ? const Color(
                                                    0xFF4CAF50) : Colors.grey
                                                    .shade300,
                                              ),
                                              borderRadius: BorderRadius
                                                  .circular(6),
                                            ),
                                            child: Text(
                                              '$pageNum',
                                              style: TextStyle(
                                                color: isActive ? const Color(
                                                    0xFF4CAF50) : Colors
                                                    .black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.arrow_forward_ios, size: 16,
                                            color: Colors.grey),
                                        onPressed: _currentPage < totalPages
                                            ? () =>
                                            setState(() => _currentPage++)
                                            : null,
                                      ),
                                      const SizedBox(width: 20),
                                      Row(
                                        children: [
                                          Container(
                                            height: 34,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade300),
                                              borderRadius: BorderRadius
                                                  .circular(6),
                                              color: Colors.white,
                                            ),
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<int>(
                                                value: _rowsPerPage,
                                                icon: const Icon(
                                                    Icons.keyboard_arrow_down,
                                                    size: 18),
                                                items: [5, 10, 20, 50]
                                                    .map((e) =>
                                                    DropdownMenuItem(
                                                        value: e, child: Text(
                                                        '$e')))
                                                    .toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      _rowsPerPage = val;
                                                      _currentPage = 1;
                                                    });
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
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<PlutoRow>> _buildFeedbackRows(
      Map<String, dynamic> feedbackData) async {
    final List<PlutoRow> rows = [];
    int counter = 1;

    final List<MapEntry<String, dynamic>> feedbackEntries = feedbackData.entries
        .toList();

    feedbackEntries.sort((a, b) {
      final timestampA = (a.value as Map)['timestamp'] as int? ?? 0;
      final timestampB = (b.value as Map)['timestamp'] as int? ?? 0;
      return timestampB.compareTo(timestampA);
    });

    for (final entry in feedbackEntries) {
      final feedbackId = entry.key;
      final feedback = Map<String, dynamic>.from(entry.value as Map);
      feedback['id'] = feedbackId;

      final userId = feedback['userId'] ?? '';
      final userName = await _getUserName(userId);
      feedback['userName'] = userName;

      final timestamp = feedback['timestamp'] as int? ?? 0;
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final formattedDate = "${date.day}/${date.month}/${date.year} ${date
          .hour}:${date.minute.toString().padLeft(2, '0')}";
      feedback['formattedDate'] = formattedDate;

      if (_matchesFilters(feedback)) {
        rows.add(
          PlutoRow(
            cells: {
              'no': PlutoCell(value: counter),
              'userName': PlutoCell(value: userName),
              'message': PlutoCell(value: feedback['message'] ?? ''),
              'type': PlutoCell(value: feedback['type'] ?? 'General'),
              'date': PlutoCell(value: formattedDate),
              'actions': PlutoCell(value: ''),
              'feedbackData': PlutoCell(value: feedback),
            },
          ),
        );
        counter++;
      }
    }

    return rows;
  }
}