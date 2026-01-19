import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:farmers_admin/common/app_header.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const AdminActivityContent(),
    );
  }
}

class AdminActivityContent extends StatefulWidget {
  const AdminActivityContent({super.key});

  @override
  State<AdminActivityContent> createState() => _AdminActivityContentState();
}

class _AdminActivityContentState extends State<AdminActivityContent> {
  // UI state only — no DB
  String _searchQuery = '';
  String? _selectedAdmin = "All";
  String? _selectedActionType = "All";
  String? _selectedDateFilter = "All Time";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                padding: const EdgeInsets.only(right: 30, left: 30, bottom: 30, top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title + breadcrumb
                    isMobile
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Activity Log',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Dashboard / Admin Activity',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.normal, fontFamily: 'Roboto'),
                        ),
                        const SizedBox(height: 15),


                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Admin Activity Log',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Dashboard / Admin Activity',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.normal, fontFamily: 'Roboto'),
                            ),
                            const SizedBox(height: 15),

                          ],
                        ),
                        // Info badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.blue.shade200, width: 1),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue.shade700, size: 14),
                              const SizedBox(width: 8),
                              Text(
                                "Monitor Sub-Admin Actions",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Filters Section
                    isMobile
                        ? Column(
                      children: [
                        // Search bar
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search activities...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.green, width: 2),
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

                        // Admin filter
                        Container(
                          width: double.infinity,
                          height: 48,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border:
                            Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedAdmin,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: const [
                                DropdownMenuItem(
                                    value: "All",
                                    child: Text("All Admins")),
                                DropdownMenuItem(
                                    value: "admin",
                                    child: Text("Main Admin")),
                                DropdownMenuItem(
                                    value: "subadmin",
                                    child: Text("Sub-Admin")),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedAdmin = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Action type filter
                        Container(
                          width: double.infinity,
                          height: 48,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border:
                            Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedActionType,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: const [
                                DropdownMenuItem(
                                    value: "All",
                                    child: Text("All Actions")),
                                DropdownMenuItem(
                                    value: "PostApproved",
                                    child: Text("Post Approved")),
                                DropdownMenuItem(
                                    value: "PostRejected",
                                    child: Text("Post Rejected")),
                                DropdownMenuItem(
                                    value: "UserBlocked",
                                    child: Text("User Blocked")),
                                DropdownMenuItem(
                                    value: "UserUnblocked",
                                    child: Text("User Unblocked")),
                                DropdownMenuItem(
                                    value: "PostDeleted",
                                    child: Text("Post Deleted")),
                                DropdownMenuItem(
                                    value: "SettingsChanged",
                                    child: Text("Settings Changed")),
                              ],
                              onChanged: (val) {
                                setState(() => _selectedActionType = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date filter
                        Container(
                          width: double.infinity,
                          height: 48,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border:
                            Border.all(color: Colors.grey.shade300),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDateFilter,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: const [
                                DropdownMenuItem(
                                    value: "All Time",
                                    child: Text("All Time")),
                                DropdownMenuItem(
                                    value: "Today",
                                    child: Text("Today")),
                                DropdownMenuItem(
                                    value: "Last 7 Days",
                                    child: Text("Last 7 Days")),
                                DropdownMenuItem(
                                    value: "Last 30 Days",
                                    child: Text("Last 30 Days")),
                                DropdownMenuItem(
                                    value: "This Month",
                                    child: Text("This Month")),
                              ],
                              onChanged: (val) {
                                setState(
                                        () => _selectedDateFilter = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Apply filters button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: null, // placeholder
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                    'images/ic_farm_filter.svg',
                                    height: 20,
                                    width: 20,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                const Text("APPLY FILTERS",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )

                        : Row(
                      children: [
                        // Search bar
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 35,
                            child: TextField(
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Search activities...',
                                hintStyle: TextStyle(fontSize: 12),
                                prefixIcon: const Icon(Icons.search, size: 14,),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Colors.green, width: 2)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.toLowerCase();
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Admin Dropdown
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 38,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                  color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedAdmin,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                      value: "All",
                                      child: Text("All Admins", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "admin",
                                      child: Text("Main Admin", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "subadmin",
                                      child: Text("Sub-Admin", style: TextStyle(fontSize: 12),)),
                                ],
                                onChanged: (val) {
                                  setState(() => _selectedAdmin = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Action Type Dropdown
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 38,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedActionType,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                      value: "All",
                                      child: Text("All Actions",  style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "PostApproved",
                                      child: Text("Post Approved", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "PostRejected",
                                      child: Text("Post Rejected" , style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "UserBlocked",
                                      child: Text("User Blocked", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "UserUnblocked",
                                      child: Text("User Unblocked", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "PostDeleted",
                                      child: Text("Post Deleted", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "SettingsChanged",
                                      child: Text("Settings Changed", style: TextStyle(fontSize: 12),)),
                                ],
                                onChanged: (val) {
                                  setState(
                                          () => _selectedActionType = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Date Filter Dropdown
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 38,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDateFilter,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                      value: "All Time",
                                      child: Text("All Time", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "Today",
                                      child: Text("Today", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "Last 7 Days",
                                      child: Text("Last 7 Days", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "Last 30 Days",
                                      child: Text("Last 30 Days", style: TextStyle(fontSize: 12),)),
                                  DropdownMenuItem(
                                      value: "This Month",
                                      child: Text("This Month", style: TextStyle(fontSize: 12),)),
                                ],
                                onChanged: (val) {
                                  setState(
                                          () => _selectedDateFilter = val);
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Apply Filters Button
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              onPressed: null, // placeholder
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 0),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: SvgPicture.asset(
                                        'images/ic_farm_filter.svg',
                                        height: 12,
                                        width: 12,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: const Text("APPLY FILTERS",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Empty state content area
                    Container(

                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      height: 450,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(50.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset('images/image_farm_nothing_remains.png',
                                  height: 150),
                              const SizedBox(height: 24),
                              const Text(
                                "No Activity Logs Yet",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "This area will show all admin and sub-admin activities once you connect to the database. You'll be able to track post approvals, user management, and other actions.",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),


                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}