import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:farmers_admin/common/app_header.dart';

class AdsImageScreen extends StatefulWidget {
  const AdsImageScreen({super.key});

  @override
  State<AdsImageScreen> createState() => _AdsImageScreenState();
}

class _AdsImageScreenState extends State<AdsImageScreen> {
  // UI state only — no DB
  String _searchQuery = '';
  String? _selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isMobile = screenWidth < 768;
    // mimic posts rowHeight/headerHeight usage style (not strictly required)
    const double rowHeight = 45;
    const double headerHeight = 50;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(), // keep same header
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                padding: EdgeInsets.all(isMobile ? 12 : 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title + breadcrumb + Add button (same pattern)
                    isMobile
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ads Image',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Dashboard / Ads Image",
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: null, // disabled for now (no DB)
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text("Add Ads Image", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ads Image',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Dashboard / Ads Image",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: null, // disabled while no DB
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("Add Ads Image", style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Filters Section (placeholder but matches layout)
                    isMobile
                        ? Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Search ads images...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.green, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.toLowerCase();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: null, // placeholder
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('images/ic_farm_filter.svg', height: 20, width: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text("APPLY FILTERS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            width: isTablet ? 200 : 300,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search ads images...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.green, width: 2)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

                        // Category Dropdown (placeholder)
                        Expanded(
                          flex: 1,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(value: "All", child: Text("All")),
                                  DropdownMenuItem(value: "HomeBanner", child: Text("Home Banner")),
                                  DropdownMenuItem(value: "Sidebar", child: Text("Sidebar")),
                                  DropdownMenuItem(value: "Footer", child: Text("Footer")),
                                ],
                                onChanged: (val) {
                                  // placeholder only
                                  setState(() => _selectedCategory = val);
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          flex: 1,
                          child: ElevatedButton(
                            onPressed: null, // placeholder
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.asset('images/ic_farm_filter.svg', height: 20, width: 20, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text("APPLY FILTERS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Grid / Table area — mimic same card style but show empty placeholder
                    Container(
                      color: Colors.white,
//                      height: (1 * rowHeight) + headerHeight + 40,
                    height: 450,
                      // small height to show placeholder; you can change to Expanded if needed
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.asset(
                                  'images/image_farm_nothing_remains.png',
                                  height: isMobile ? 120 : 150,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                "No Ads Images yet",
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "This area will show ads images (bread image, ads banners) once you connect to the database.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // // Pagination / footer (placeholder) to keep pattern consistent
                    // Container(
                    //   width: double.infinity,
                    //   padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: isMobile ? 4 : 8),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(10),
                    //     boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                    //   ),
                    //   child: Center(
                    //     child: Text(
                    //       "No pages available",
                    //       style: TextStyle(color: Colors.grey.shade600),
                    //     ),
                    //   ),
                    // ),
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
