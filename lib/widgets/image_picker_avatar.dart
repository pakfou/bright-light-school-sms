import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerAvatar extends StatefulWidget {
  final TextEditingController urlController;
  final String label;

  const ImagePickerAvatar({
    super.key,
    required this.urlController,
    required this.label,
  });

  @override
  State<ImagePickerAvatar> createState() => _ImagePickerAvatarState();
}

class _ImagePickerAvatarState extends State<ImagePickerAvatar> {
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    // ករណីទិន្នន័យចាស់ជា Base64
    final text = widget.urlController.text.trim();
    if (text.startsWith('data:image')) {
      try {
        final base64Str = text.split(',').last;
        _imageBytes = base64Decode(base64Str);
      } catch (_) {}
    }
  }

  // មុខងារបើក File Picker លើ Web
  Future<void> _chooseImageFile() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        setState(() {
          _imageBytes = bytes;
          widget.urlController.text = base64String;
        });
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('មិនអាចជ្រើសរើសរូបថតបានឡើយ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = widget.urlController.text.trim();
    final bool isNetworkUrl =
        currentUrl.startsWith('http://') || currentUrl.startsWith('https://');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. រង្វង់ Avatar Preview & Camera Button
          InkWell(
            onTap: _chooseImageFile,
            borderRadius: BorderRadius.circular(50),
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
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : (isNetworkUrl
                              ? Image.network(
                                  currentUrl,
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
                      Icons.photo_camera_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // 2. ប្រអប់ជ្រើសរើសហ្វាល និង Input URL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.label,
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _chooseImageFile,
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text(
                        'ជ្រើសរើសហ្វាល (Upload)',
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
                  controller: widget.urlController,
                  onChanged: (val) {
                    setState(() {
                      if (!val.startsWith('data:image')) {
                        _imageBytes = null;
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText:
                        'ឬបិទភ្ជាប់តំណភ្ជាប់រូបភាព (Photo URL - ជម្រើស)...',
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
