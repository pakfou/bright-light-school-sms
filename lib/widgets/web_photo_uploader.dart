// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WebPhotoUploader extends StatefulWidget {
  final TextEditingController photoController;
  final String title;

  const WebPhotoUploader({
    super.key,
    required this.photoController,
    this.title = 'រូបថតសិស្ស (Student Photo):',
  });

  @override
  State<WebPhotoUploader> createState() => _WebPhotoUploaderState();
}

class _WebPhotoUploaderState extends State<WebPhotoUploader> {
  // ignore: unused_field
  Uint8List? _previewBytes;

  @override
  void initState() {
    super.initState();
    _checkInitialImage();
  }

  void _checkInitialImage() {
    final text = widget.photoController.text.trim();
    if (text.startsWith('data:image')) {
      try {
        final base64Data = text.split(',').last;
        _previewBytes = base64Decode(base64Data);
      } catch (_) {}
    }
  }

  // មុខងារចុចដើម្បីបើក File Picker ពីកុំព្យូទ័រ និងបង្រួមទំហំរូបភាព (Resize & Compress via Canvas)
  void _openFilePicker() {
    if (kIsWeb) {
      final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = 'image/*';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final file = files[0];
          final reader = html.FileReader();
          reader.readAsDataUrl(file);
          reader.onLoadEnd.listen((e) {
            final img = html.ImageElement(src: reader.result as String);
            img.onLoad.listen((_) {
              const int targetWidth = 320;
              final num naturalWidth = img.width ?? targetWidth;
              final double scale = targetWidth / (naturalWidth > 0 ? naturalWidth : targetWidth);
              final int targetHeight = ((img.height ?? targetWidth) * scale).round();

              final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
              final ctx = canvas.context2D;
              ctx.drawImageScaled(img, 0, 0, targetWidth, targetHeight);

              final String compressedBase64 = canvas.toDataUrl('image/jpeg', 0.7);
              if (mounted) {
                setState(() {
                  final commaIdx = compressedBase64.indexOf(',');
                  _previewBytes = base64Decode(compressedBase64.substring(commaIdx + 1));
                  widget.photoController.text = compressedBase64;
                });
              }
            });
          });
        }
      });
    } else {
      _pickImageFallback();
    }
  }

  Future<void> _pickImageFallback() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 350,
        maxHeight: 350,
        imageQuality: 75,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        if (mounted) {
          setState(() {
            _previewBytes = bytes;
            widget.photoController.text = 'data:image/jpeg;base64,$base64String';
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.photoController.text.trim();
    final bool isNetworkUrl =
        currentText.startsWith('http://') || currentText.startsWith('https://');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // រង្វង់ Avatar Preview ដែលអាចចុចបាន
          InkWell(
            onTap: _openFilePicker,
            borderRadius: BorderRadius.circular(50),
            child: Tooltip(
              message: 'ចុចដើម្បីជ្រើសរើសរូបថតពីកុំព្យូទ័រ',
              child: Stack(
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4F46E5),
                        width: 2.5,
                      ),
                      color: const Color(0xFFEEF2FF),
                    ),
                    child: ClipOval(
                      child: _previewBytes != null
                          ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                          : (isNetworkUrl
                                ? Image.network(
                                    currentText,
                                    fit: BoxFit.cover,
                                    // ignore: unnecessary_underscores
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 48,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 48,
                                    color: Color(0xFF4F46E5),
                                  )),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4F46E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),

          // ប៊ូតុង Upload និងប្រអប់ URL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEEF2FF),
                        foregroundColor: const Color(0xFF4F46E5),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _openFilePicker,
                      icon: const Icon(Icons.file_upload_outlined, size: 16),
                      label: const Text(
                        'ជ្រើសរើសរូបថត',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: widget.photoController,
                  onChanged: (val) {
                    setState(() {
                      if (!val.startsWith('data:image')) {
                        _previewBytes = null;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'ឬបិទភ្ជាប់តំណភ្ជាប់រូបភាព (Photo URL)...',
                    prefixIcon: const Icon(
                      Icons.link_rounded,
                      color: Color(0xFF4F46E5),
                      size: 18,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF4F46E5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
