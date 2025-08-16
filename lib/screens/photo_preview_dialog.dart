import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PhotoPreviewDialog extends StatelessWidget {
  final String imagePath;
  final Function() onCancel;
  final Function() onUpload;

  const PhotoPreviewDialog({
    Key? key,
    required this.imagePath,
    required this.onCancel,
    required this.onUpload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'पौधे की फोटो की समीक्षा करें',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('रद्द करें'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('अपलोड करें'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
