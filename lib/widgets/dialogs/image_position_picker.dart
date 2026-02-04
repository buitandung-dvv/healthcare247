import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/language_provider.dart';

/// A full-screen widget that allows users to drag and position an image
/// Returns the Y offset (0.0 = top, 0.5 = center, 1.0 = bottom)
class ImagePositionPicker extends StatefulWidget {
  final String imagePath;
  final double initialOffset;
  final LanguageProvider lang;
  final bool isCircular; // For avatar circular preview

  const ImagePositionPicker({
    super.key,
    required this.imagePath,
    required this.lang,
    this.initialOffset = 0.5,
    this.isCircular = false,
  });

  @override
  State<ImagePositionPicker> createState() => _ImagePositionPickerState();
}

class _ImagePositionPickerState extends State<ImagePositionPicker> {
  late double _offsetY;
  double _containerHeight = 0;

  @override
  void initState() {
    super.initState();
    _offsetY = widget.initialOffset;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _containerHeight = widget.isCircular ? 120 : 200; // Smaller for avatar
    final previewSize = widget.isCircular ? 120.0 : screenSize.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.lang.getText(en: 'Adjust Position', vi: 'Điều chỉnh vị trí'),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.lang.getText(
                en: 'Drag the image up or down to choose the displayed area',
                vi: 'Kéo ảnh lên hoặc xuống để chọn vùng hiển thị',
              ),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          // Preview container with draggable image
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The preview frame (simulates profile header or avatar)
                  Container(
                    width: previewSize,
                    height: _containerHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.primary, width: 3),
                      shape:
                          widget.isCircular
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                    ),
                    child: ClipRRect(
                      borderRadius:
                          widget.isCircular
                              ? BorderRadius.circular(60)
                              : BorderRadius.zero,
                      child: GestureDetector(
                        onVerticalDragUpdate: (details) {
                          setState(() {
                            // Calculate offset change based on drag
                            final delta = details.delta.dy;
                            // Invert because dragging down should move offset up
                            _offsetY = (_offsetY - delta / 300).clamp(0.0, 1.0);
                          });
                        },
                        child: Stack(
                          children: [
                            // Full image that can be positioned
                            Positioned.fill(
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                                alignment: Alignment(
                                  0,
                                  _offsetY * 2 - 1,
                                ), // Convert 0-1 to -1 to 1
                              ),
                            ),
                            // Dark overlay
                            Container(
                              color: Colors.black.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Position indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getPositionLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Visual slider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      children: [
                        Text(
                          widget.lang.getText(en: 'Top', vi: 'Trên'),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _offsetY,
                            onChanged: (value) {
                              setState(() => _offsetY = value);
                            },
                            activeColor: AppColors.primary,
                            inactiveColor: Colors.white24,
                          ),
                        ),
                        Text(
                          widget.lang.getText(en: 'Bottom', vi: 'Dưới'),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Confirm button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _offsetY),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.lang.getText(en: 'Confirm', vi: 'Xác nhận'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPositionLabel() {
    if (_offsetY < 0.33) {
      return widget.lang.getText(
        en: 'Showing top area',
        vi: 'Hiển thị phần trên',
      );
    } else if (_offsetY > 0.67) {
      return widget.lang.getText(
        en: 'Showing bottom area',
        vi: 'Hiển thị phần dưới',
      );
    } else {
      return widget.lang.getText(
        en: 'Showing center area',
        vi: 'Hiển thị phần giữa',
      );
    }
  }
}
