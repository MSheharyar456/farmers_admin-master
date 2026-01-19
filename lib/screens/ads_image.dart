import 'package:cached_network_image/cached_network_image.dart';
import 'package:farmers_admin/common/app_header.dart';
import 'package:farmers_admin/common/side_menu.dart';
import 'package:farmers_admin/widgets/delete_dialog.dart';
import 'package:farmers_admin/widgets/responsive_scafold.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:farmers_admin/services/permission_helper.dart';

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
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'sliderImages',
  );
  final ImagePicker _picker = ImagePicker();
  bool _isInitialLoad = true;
  final Map<String, bool> _uploadingStates = {};

  // Permission states
  bool _canDelete = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final canDelete = await PermissionHelper.canDelete();
    if (mounted) {
      setState(() {
        _canDelete = canDelete;
      });
    }
  }

  // Generate a random node ID using Firebase push
  String _generateNodeId() {
    return _dbRef.push().key ??
        DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Get the next available order number
  // Finds the first missing order number (gap) or returns maxOrder + 1 if no gaps exist
  Future<int> _getNextOrderNumber() async {
    try {
      final snapshot = await _dbRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        return 1; // First image
      }

      final data = snapshot.value as Map;
      Set<int> existingOrders = {};
      int maxOrder = 0;

      // Collect all existing order numbers
      data.forEach((key, value) {
        if (value != null && value is Map) {
          final order = value['order'];
          if (order != null && order is int) {
            existingOrders.add(order);
            if (order > maxOrder) {
              maxOrder = order;
            }
          }
        }
      });

      // If no orders exist, return 1
      if (existingOrders.isEmpty) {
        return 1;
      }

      // Find the first missing order number starting from 1
      for (int i = 1; i <= maxOrder; i++) {
        if (!existingOrders.contains(i)) {
          // Found a gap, return this missing order number
          return i;
        }
      }

      // No gaps found, return the next number after maxOrder
      return maxOrder + 1;
    } catch (e) {
      print('Error getting next order number: $e');
      return 1;
    }
  }

  Future<void> _pickAndUploadImage({int? specificOrder}) async {
    String? nodeId;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      // Generate random node ID
      nodeId = _generateNodeId();

      // Use specific order if provided, otherwise get next order number
      final orderNumber = specificOrder ?? await _getNextOrderNumber();

      setState(() {
        _uploadingStates[nodeId!] = true;
      });

      // Read image bytes directly without cropping
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
      } else {
        final file = File(pickedFile.path);
        imageBytes = await file.readAsBytes();
      }

      // Upload to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'slider_${nodeId}_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'backgrounds/$fileName',
      );

      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firebase Realtime Database with new structure
      await _dbRef.child(nodeId).set({
        'itemId': nodeId,
        'order': orderNumber,
        'url': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _uploadingStates.remove(nodeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (nodeId != null) {
          setState(() {
            _uploadingStates.remove(nodeId);
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _replaceImage(String nodeId, int order) async {
    try {
      setState(() {
        _uploadingStates[nodeId] = true;
      });

      // Pick a new image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) {
        // User cancelled
        if (mounted) {
          setState(() {
            _uploadingStates.remove(nodeId);
          });
        }
        return;
      }

      // Read image bytes directly without cropping
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
      } else {
        final file = File(pickedFile.path);
        imageBytes = await file.readAsBytes();
      }

      // Upload to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'slider_${nodeId}_$timestamp.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'backgrounds/$fileName',
      );

      await storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Get download URL
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firebase Realtime Database (keep same nodeId and order, update URL)
      await _dbRef.child(nodeId).set({
        'itemId': nodeId,
        'order': order,
        'url': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _uploadingStates.remove(nodeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image replaced successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error in _replaceImage: $e');
      if (mounted) {
        setState(() {
          _uploadingStates.remove(nodeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error replacing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageOptionsDialog(String nodeId, int currentOrder) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // outer dialog
          ),

          // EVERYTHING INSIDE CONTENT
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // only content rounded
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title inside content
                const Text(
                  'Image Options',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 10),

                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.swap_horiz,
                    color: Colors.blue,
                    size: 14,
                  ),
                  title: const Text(
                    'Replace Image',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _replaceImage(nodeId, currentOrder);
                  },
                ),
                ListTile(
                  dense: true,
                  visualDensity: VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.reorder,
                    color: Colors.orange,
                    size: 14,
                  ),
                  title: const Text(
                    'Change Order Position',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showChangeOrderDialog(nodeId, currentOrder);
                  },
                ),

                const SizedBox(height: 10),

                // Cancel button also inside content
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
                        ),
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

  // Show dialog to change image order
  Future<void> _showChangeOrderDialog(String nodeId, int currentOrder) async {
    final TextEditingController orderController = TextEditingController(
      text: currentOrder.toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // smooth corners
          ),

          // FULL CONTENT (same style as your first dialog)
          content: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Change Order Position',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 10),

                Text(
                  'Current position: $currentOrder',
                  style: const TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  height: 30,
                  child: TextField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 12),

                    inputFormatters: [
                      FilteringTextInputFormatter
                          .digitsOnly, // allow digits only
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^[1-9][0-9]*$'),
                      ), // no leading zero
                    ],

                    decoration: const InputDecoration(
                      labelText: 'New Position',
                      labelStyle: TextStyle(fontSize: 12),
                      hintText: 'Enter new order number',
                      hintStyle: TextStyle(fontSize: 12),

                      // Default border
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),
                      // When clicked / focused
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 1),
                      ),

                      // Optional: If you use error state
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),

                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // BUTTONS — same style as your first dialog
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black87, fontSize: 12),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    SizedBox(
                      height: 30,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                        ),
                        onPressed: () {
                          final newOrder = int.tryParse(orderController.text);

                          if (newOrder != null && newOrder > 0) {
                            Navigator.of(context).pop();
                            _changeImageOrder(nodeId, currentOrder, newOrder);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid order number',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Change',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
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

  // Change the order of an image (swap with existing image at target position)
  Future<void> _changeImageOrder(
    String nodeId,
    int oldOrder,
    int newOrder,
  ) async {
    try {
      setState(() {
        _uploadingStates[nodeId] = true;
      });

      // Find if there's an image at the new order position
      final snapshot = await _dbRef.get();
      String? targetNodeId;

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map;
        data.forEach((key, value) {
          if (value != null && value is Map) {
            final imageData = Map<String, dynamic>.from(value);
            final order = imageData['order'];
            if (order == newOrder && key.toString() != nodeId) {
              targetNodeId = key.toString();
            }
          }
        });
      }

      // If there's an image at the target position, swap their orders
      if (targetNodeId != null) {
        // Swap: Move target image to old position
        await _dbRef.child(targetNodeId!).update({'order': oldOrder});
      }

      // Move current image to new position
      await _dbRef.child(nodeId).update({'order': newOrder});

      if (mounted) {
        setState(() {
          _uploadingStates.remove(nodeId);
        });

        final message = targetNodeId != null
            ? 'Swapped positions: $oldOrder ↔ $newOrder'
            : 'Order changed from $oldOrder to $newOrder';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      print('Error changing order: $e');
      if (mounted) {
        setState(() {
          _uploadingStates.remove(nodeId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage(String nodeId) async {
    if (nodeId.isEmpty) return;

    print('DEBUG: Starting deletion for nodeId: $nodeId');

    setState(() {
      _uploadingStates[nodeId] = true;
    });

    bool storageDeleted = false;
    bool nodeDeleted = false;
    String? storageError;

    // Step 1: Delete from Firebase Storage (if URL exists)
    // This is done separately so node deletion always happens even if storage deletion fails
    try {
      print('DEBUG: Fetching URL for node: $nodeId');
      final snapshot = await _dbRef.child(nodeId).child('url').get();
      if (snapshot.exists && snapshot.value != null) {
        final imageUrl = snapshot.value.toString();
        print('DEBUG: Found URL: $imageUrl');

        if (imageUrl.isNotEmpty) {
          try {
            final uri = Uri.parse(imageUrl);
            final filePath = Uri.decodeFull(
              uri.pathSegments.last.split('?').first,
            );
            print('DEBUG: Deleting storage file: $filePath');
            final storageRef = FirebaseStorage.instance.ref().child(filePath);
            await storageRef.delete();
            storageDeleted = true;
            print('DEBUG: Storage file deleted successfully');
          } catch (e) {
            storageError = e.toString();
            print('DEBUG: Storage delete error: $e');
            // Continue to node deletion even if storage deletion fails
          }
        }
      } else {
        print('DEBUG: No URL found for node: $nodeId');
      }
    } catch (e) {
      storageError = e.toString();
      print('DEBUG: Error fetching URL for storage deletion: $e');
      // Continue to node deletion even if URL fetch fails
    }

    // Step 2: Always delete the complete node from Realtime Database
    // This must happen regardless of storage deletion success/failure
    try {
      // Verify node exists before attempting deletion
      print('DEBUG: Verifying node exists: $nodeId');
      final nodeSnapshot = await _dbRef.child(nodeId).get();

      if (nodeSnapshot.exists) {
        print('DEBUG: Node exists. Current data: ${nodeSnapshot.value}');
        print('DEBUG: Attempting to delete complete node: $nodeId');

        // Get the full node reference
        final nodeRef = _dbRef.child(nodeId);

        // Method 1: Try remove() - this should delete the entire node
        print('DEBUG: Calling remove() on node: $nodeId');
        await nodeRef.remove();
        print('DEBUG: remove() completed for node: $nodeId');

        // Wait a moment for the deletion to propagate in Firebase
        await Future.delayed(const Duration(milliseconds: 200));

        // Verify the node is actually deleted
        print('DEBUG: Verifying deletion...');
        final verifySnapshot = await nodeRef.get();

        if (verifySnapshot.exists) {
          print(
            'DEBUG: WARNING - Node still exists after remove(). Data: ${verifySnapshot.value}',
          );
          print('DEBUG: Trying alternative method: set(null)...');

          // Method 2: Try set(null) - this explicitly sets the node to null, which deletes it
          try {
            await nodeRef.set(null);
            print('DEBUG: set(null) completed for node: $nodeId');

            // Wait and verify again
            await Future.delayed(const Duration(milliseconds: 200));
            final verifySnapshot2 = await nodeRef.get();

            if (verifySnapshot2.exists) {
              print(
                'DEBUG: ERROR - Node still exists after set(null). Data: ${verifySnapshot2.value}',
              );
              print(
                'DEBUG: This indicates a Firebase permission or network issue',
              );
              throw Exception(
                'Failed to delete node: Node still exists after remove() and set(null) attempts. Check Firebase rules and network connection.',
              );
            } else {
              nodeDeleted = true;
              print('DEBUG: SUCCESS - Node deleted using set(null) method');
            }
          } catch (e2) {
            print('DEBUG: Error with set(null) method: $e2');
            // Try one more time with remove()
            try {
              print('DEBUG: Retrying with remove() one more time...');
              await nodeRef.remove();
              await Future.delayed(const Duration(milliseconds: 200));
              final finalVerify = await nodeRef.get();
              if (!finalVerify.exists) {
                nodeDeleted = true;
                print('DEBUG: SUCCESS - Node deleted on retry');
              } else {
                throw Exception('Node deletion failed after all attempts');
              }
            } catch (e3) {
              print('DEBUG: Final retry also failed: $e3');
              throw e2; // Throw the original error
            }
          }
        } else {
          nodeDeleted = true;
          print('DEBUG: SUCCESS - Node deleted using remove() method');
        }
      } else {
        // Node doesn't exist, consider it already deleted
        nodeDeleted = true;
        print('DEBUG: Node does not exist, considering it already deleted');
      }
    } catch (e) {
      print('DEBUG: ERROR - Error deleting node from database: $e');
      print('DEBUG: Error type: ${e.runtimeType}');
      if (mounted) {
        setState(() {
          _uploadingStates.remove(nodeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting image node: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    // Step 3: Final verification and show appropriate success/error message
    if (mounted) {
      // Final check to ensure node is deleted
      try {
        final finalCheck = await _dbRef.child(nodeId).get();
        if (finalCheck.exists) {
          print('DEBUG: WARNING - Final check: Node still exists!');
          nodeDeleted = false;
        } else {
          print('DEBUG: Final check: Node successfully deleted');
        }
      } catch (e) {
        print('DEBUG: Error in final verification: $e');
      }

      setState(() {
        _uploadingStates.remove(nodeId);
      });

      if (nodeDeleted) {
        // Node deletion is the critical operation - if it succeeds, show success
        if (storageDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image and file deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (storageError != null) {
          // Node deleted but storage deletion failed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image node deleted, but storage file deletion failed: $storageError',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // Node deleted, no storage file to delete
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Warning: Node deletion may have failed. Please refresh and check.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildImageBox({
    required String? nodeId,
    required String? imageUrl,
    required int? order,
    required bool isUploading,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: !hasImage && !isUploading
          ? () => _pickAndUploadImage(specificOrder: order)
          : null,
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
            // Image or placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16.1 / 9,
                child: isUploading
                    ? Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        ),
                      )
                    : hasImage
                    ? GestureDetector(
                        onTap: nodeId != null && order != null && !isUploading
                            ? () => _showImageOptionsDialog(nodeId, order)
                            : null,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                          ),
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
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add Image',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    "$order", // Show order number
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // // Edit button (only show if image exists)
            // if (hasImage && !isUploading && nodeId != null && order != null)
            //   Positioned(
            //     top: 40,
            //     right: 8,
            //     child: GestureDetector(
            //       onTap: () {
            //         _replaceImage(nodeId, order);
            //       },
            //       child: Container(
            //         padding: const EdgeInsets.all(6),
            //         decoration: BoxDecoration(
            //           color: Colors.blue.shade50,
            //           shape: BoxShape.circle,
            //           border: Border.all(
            //             width: 0.5,
            //             color: Colors.blue.shade200,
            //           ),
            //           boxShadow: [
            //             BoxShadow(
            //               color: Colors.blue.withOpacity(0.2),
            //               blurRadius: 4,
            //               offset: const Offset(0, 2),
            //             ),
            //           ],
            //         ),
            //         child: const Icon(Icons.edit, color: Colors.blue, size: 14),
            //       ),
            //     ),
            //   ),

            // Close/Delete button (only show if image exists and user has delete permission)
            if (hasImage && !isUploading && nodeId != null && _canDelete)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    showDeleteDialog(
                      context: context,
                      title: "Delete Image",
                      message: "Are you sure you want to delete this image?",
                      onConfirm: () => _deleteImage(nodeId),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 0.5,
                        color: Colors.red.shade200,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                padding: EdgeInsets.all(50),
                // padding: EdgeInsets.symmetric(
                //   // horizontal: isMobile ? 12 : 30,
                //   // vertical: isMobile ? 12 : 30,
                // ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ads Image',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Dashboard / Ads Image',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: Colors.grey,
                                      fontSize: 10,
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.normal,
                                      fontFamily: 'Roboto',
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
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Dashboard / Ads Image',
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
                    const SizedBox(height: 20),
                    // Image Grid
                    StreamBuilder<DatabaseEvent>(
                      stream: _dbRef.onValue,
                      builder: (context, snapshot) {
                        if (_isInitialLoad &&
                            snapshot.connectionState ==
                                ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(50.0),
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                          );
                        }

                        if (_isInitialLoad && snapshot.hasData) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _isInitialLoad = false;
                              });
                            }
                          });
                        }

                        // Get all images from Firebase and sort by order
                        List<Map<String, dynamic>> imageList = [];

                        if (snapshot.hasData &&
                            snapshot.data!.snapshot.value != null) {
                          final data = snapshot.data!.snapshot.value as Map;
                          data.forEach((key, value) {
                            if (value != null && value is Map) {
                              final imageData = Map<String, dynamic>.from(
                                value,
                              );

                              // Safely extract order - handle both old and new structure
                              int? order;
                              final orderValue = imageData['order'];
                              if (orderValue != null && orderValue is int) {
                                order = orderValue;
                              }

                              // Only add items that have the new structure with order field
                              // Skip old structure items (they don't have order field)
                              if (order != null) {
                                imageList.add({
                                  'nodeId': key.toString(),
                                  'itemId': imageData['itemId']?.toString(),
                                  'order': order,
                                  'url': imageData['url']?.toString(),
                                });
                              }
                            }
                          });

                          // Sort by order field
                          imageList.sort((a, b) {
                            final orderA = a['order'] as int? ?? 999999;
                            final orderB = b['order'] as int? ?? 999999;
                            return orderA.compareTo(orderB);
                          });
                        }

                        // Only show existing images, no placeholder boxes for missing orders
                        // imageList already contains only existing images, sorted by order

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile
                                    ? 1
                                    : (isTablet ? 2 : 4),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 16 / 9,
                              ),
                          itemCount: imageList.length + 1,
                          itemBuilder: (context, index) {
                            if (index >= imageList.length) {
                              // Add new image button at the end
                              return _buildImageBox(
                                nodeId: null,
                                imageUrl: null,
                                order: null,
                                isUploading: false,
                              );
                            }

                            final imageData = imageList[index];
                            final nodeId = imageData['nodeId'] as String?;
                            final imageUrl = imageData['url'] as String?;
                            final order = imageData['order'] as int?;
                            final isUploading =
                                _uploadingStates[nodeId] ?? false;

                            return _buildImageBox(
                              nodeId: nodeId,
                              imageUrl: imageUrl,
                              order: order,
                              isUploading: isUploading,
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
}
