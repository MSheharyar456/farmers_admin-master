import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/services/slider_api_service.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/loading_overlay.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AdsImageScreen extends StatefulWidget {
  const AdsImageScreen({super.key});

  @override
  State<AdsImageScreen> createState() => _AdsImageScreenState();
}

class _AdsImageScreenState extends State<AdsImageScreen> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Farmers Admin",
      sideMenu: const SideMenu(),
      content: const AdsImageContent(),
    );
  }
}

class AdsImageContent extends StatefulWidget {
  const AdsImageContent({super.key});

  @override
  State<AdsImageContent> createState() => _AdsImageContentState();
}

class _AdsImageContentState extends State<AdsImageContent> {
  final ImagePicker _picker = ImagePicker();
  List<SliderItem> _items = [];
  bool _loading = true;
  final Map<String, bool> _uploadingStates = {};
  bool _canDelete = true;

  SliderApiService get _sliderService => context.read<SliderApiService>();

  @override
  void initState() {
    super.initState();
    _loadPermissions();
    _loadImages();
  }

  Future<void> _loadPermissions() async {
    // Keep permission helper if used elsewhere; otherwise assume true
    if (mounted) setState(() => _canDelete = true);
  }

  Future<void> _loadImages() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final list = await _sliderService.getSliderImages();
      await _precacheSliderImages(list);
      if (mounted) setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _items = [];
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _precacheSliderImages(List<SliderItem> items) async {
    final urls = items
        .map((e) => e.url)
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();

    if (urls.isEmpty || !mounted) return;

    await Future.wait(
      urls.map((url) async {
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
        } catch (_) {
          // Ignore image cache failures; the tile error widget will handle it.
        }
      }),
    );
  }

  Future<void> _pickAndUploadImage({int? specificOrder}) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final tempId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    setState(() => _uploadingStates[tempId] = true);
    try {
      final nextOrder = specificOrder ?? (_items.isEmpty ? 1 : (_items.map((e) => e.order).reduce((a, b) => a > b ? a : b) + 1));
      final item = await _sliderService.uploadSliderImage(pickedFile, order: nextOrder);
      if (item != null && mounted) {
        await _loadImages();
        setState(() => _uploadingStates.remove(tempId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!'), backgroundColor: Colors.green),
        );
      } else {
        if (mounted) setState(() => _uploadingStates.remove(tempId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingStates.remove(tempId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _replaceImage(String itemId, int order) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _uploadingStates[itemId] = true);
    try {
      final newItem = await _sliderService.uploadSliderImage(pickedFile, order: order);
      if (newItem != null) {
        await _sliderService.deleteSliderImage(itemId);
        if (mounted) {
          await _loadImages();
          setState(() => _uploadingStates.remove(itemId));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image replaced successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) setState(() => _uploadingStates.remove(itemId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Replace failed'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingStates.remove(itemId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error replacing image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showImageOptionsDialog(String itemId, int currentOrder) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Image Options', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.swap_horiz, color: Colors.blue, size: 14),
                  title: const Text('Replace Image', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _replaceImage(itemId, currentOrder);
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.reorder, color: Colors.orange, size: 14),
                  title: const Text('Change Order Position', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangeOrderDialog(itemId, currentOrder);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontSize: 12)),
                      ),
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

  Future<void> _showChangeOrderDialog(String itemId, int currentOrder) async {
    final orderController = TextEditingController(text: currentOrder.toString());
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Change Order Position', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text('Current position: $currentOrder', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*$')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'New Position',
                      labelStyle: TextStyle(fontSize: 12),
                      hintText: 'Enter new order number',
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 1)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                        ),
                        onPressed: () {
                          final newOrder = int.tryParse(orderController.text);
                          if (newOrder != null && newOrder > 0) {
                            Navigator.of(context).pop();
                            _changeImageOrder(itemId, currentOrder, newOrder);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid order number'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        child: const Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
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

  Future<void> _changeImageOrder(String itemId, int oldOrder, int newOrder) async {
    setState(() => _uploadingStates[itemId] = true);
    try {
      final candidates = _items.where((e) => e.itemId != itemId && e.order == newOrder).toList();
      final other = candidates.isNotEmpty ? candidates.first : null;
      if (other != null) {
        await _sliderService.updateSliderImage(other.itemId, order: oldOrder);
      }
      await _sliderService.updateSliderImage(itemId, order: newOrder);
      if (mounted) {
        await _loadImages();
        setState(() => _uploadingStates.remove(itemId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(other != null ? 'Swapped positions: $oldOrder ↔ $newOrder' : 'Order changed from $oldOrder to $newOrder'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingStates.remove(itemId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteImage(String itemId) async {
    if (itemId.isEmpty) return;
    setState(() => _uploadingStates[itemId] = true);
    try {
      await _sliderService.deleteSliderImage(itemId);
      if (mounted) {
        await _loadImages();
        setState(() => _uploadingStates.remove(itemId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingStates.remove(itemId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildImageBox({
    required SliderItem? item,
    required bool isUploading,
  }) {
    final itemId = item?.itemId;
    final imageUrl = item?.url;
    final order = item?.order;
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return GestureDetector(
      onTap: !hasImage && !isUploading ? () => _pickAndUploadImage(specificOrder: order) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? Colors.grey.shade300 : Colors.grey.shade400,
            width: hasImage ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16.1 / 9,
                child: isUploading
                    ? Container(
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(color: Colors.green)),
                      )
                    : hasImage
                        ? GestureDetector(
                            onTap: itemId != null && order != null && !isUploading
                                ? () => _showImageOptionsDialog(itemId, order)
                                : null,
                            child: Stack(
                              children: [
                                // Main image
                                CachedNetworkImage(
                                  imageUrl: imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade100,
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                                  ),
                                ),
                                // Optimization indicator
                                if (item?.imageUrls != null)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Optimized',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade50,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                                    child: const Icon(Icons.add, size: 20, color: Colors.green),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text('Add Image', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
            if (hasImage && order != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                    border: Border.all(width: 0.5, color: Colors.white),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text('$order', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            if (hasImage && !isUploading && itemId != null && _canDelete)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    showDeleteDialog(
                      context: context,
                      title: 'Delete Image',
                      message: 'Are you sure you want to delete this image?',
                      onConfirm: () => _deleteImage(itemId),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(width: 0.5, color: Colors.red.shade200),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ads Image',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Dashboard / Ads Image',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Roboto',
                                ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ads Image',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Dashboard / Ads Image',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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
                    const SizedBox(height: 20),
                    if (_loading)
                      const SizedBox(
                        height: 320,
                        child: Center(
                          child: LoadingOverlay(
                            text: 'Loading ads images...',
                            showBackdrop: false,
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 4),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 16 / 9,
                        ),
                        itemCount: _items.length + 1,
                        itemBuilder: (context, index) {
                          if (index >= _items.length) {
                            return _buildImageBox(
                              item: null,
                              isUploading: false,
                            );
                          }
                          final item = _items[index];
                          final isUploading = _uploadingStates[item.itemId] ?? false;
                          return _buildImageBox(
                            item: item,
                            isUploading: isUploading,
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
}
