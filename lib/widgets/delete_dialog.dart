import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> showDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onConfirm,
  String confirmText = "Yes, Delete",
  String cancelText = "Cancel",
  bool showSuccessMessage = true,
}) async {
  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                child: SvgPicture.asset(
                  "images/delete.svg",
                  semanticsLabel: "Delete Icon",
                  width: 50,
                  height: 50,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 12,
                          ),
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

  if (confirm == true) {
    await onConfirm();

    if (context.mounted && showSuccessMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
