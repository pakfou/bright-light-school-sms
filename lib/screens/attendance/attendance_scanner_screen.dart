import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';

class AttendanceScannerScreen extends StatefulWidget {
  final int classroomId;
  final String classroomName;
  final int userId;
  final String shift;

  const AttendanceScannerScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
    required this.userId,
    required this.shift,
  });

  @override
  State<AttendanceScannerScreen> createState() =>
      _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  bool get _isScannerSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  MobileScannerController? _controller;
  bool _isLock = false;
  String _status = 'Present';

  @override
  void initState() {
    super.initState();
    if (_isScannerSupported) {
      _controller = MobileScannerController();
    }
  }

  // State សម្រាប់បង្ហាញ Feedback ពេលស្កេនបាន
  Map<String, dynamic>? _lastScanResult;

  void _onDetect(BarcodeCapture capture) async {
    if (_isLock) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _isLock = true);

    final res = await ApiService.scanAttendance(
      barcode!.rawValue!,
      widget.classroomId,
      widget.userId,
      _status,
      widget.shift,
    );

    if (!mounted) return;

    setState(() {
      _lastScanResult = {
        'success': res['success'] == true,
        'message': res['message'] ?? res['error'] ?? 'ស្កេនបានជោគជ័យ',
        'code': barcode.rawValue!,
      };
    });

    // បើកសោរវិញក្រោយ ២វិនាទី ដើម្បីស្កេនបន្ត
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLock = false;
          _lastScanResult = null; // លុប Feedback ចេញវិញ
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View or Hardware view
          if (_isScannerSupported && _controller != null)
            MobileScanner(controller: _controller!, onDetect: _onDetect)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 72,
                    color: Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ម៉ាស៊ីនស្កេនបាកូដ USB រួចរាល់',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Muol Light',
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'សូមស្កេនកាតតាមរយៈឧបករណ៍ស្កេន Barcode/QR Code',
                    style: TextStyle(
                      fontFamily: 'Khmer OS Battambang',
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // 2. Custom Dark Overlay with Transparent Center
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              // ignore: deprecated_member_use
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Scanner Border & Corner Markers
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  // Animated glowing frame
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF4F46E5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // 4. Top AppBar & Controls (Back, Title, Flash, Camera Switch)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
                Column(
                  children: [
                    const Text(
                      'ស្កេនវត្តមានសិស្ស',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      widget.classroomName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_isScannerSupported && _controller != null)
                  Row(
                    children: [
                      IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: _controller!,
                          builder: (context, state, child) {
                            // ignore: invalid_null_aware_operator
                            final isTorchOn =
                                // ignore: invalid_null_aware_operator
                                state?.torchState == TorchState.on;
                            return Icon(
                              isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: isTorchOn ? Colors.amber : Colors.white,
                            );
                          },
                        ),
                        onPressed: () => _controller?.toggleTorch(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                        ),
                        onPressed: () => _controller?.switchCamera(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 5. Live Scan Result Feedback Banner (Floating Card)
          if (_lastScanResult != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 24,
              right: 24,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _lastScanResult!['success']
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastScanResult!['success']
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lastScanResult!['success']
                                  ? 'ស្កេនជោគជ័យ!'
                                  : 'មានបញ្ហា!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _lastScanResult!['message'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Bottom Status Selector Bar
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _chip('Present', 'មកដល់', Colors.green),
                  _chip('Late', 'យឺត', Colors.orange),
                  _chip('Permission', 'ច្បាប់', Colors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border(
            top:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom:
                alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left:
                alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right:
                alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _chip(String val, String label, Color color) {
    final active = _status == val;
    return GestureDetector(
      onTap: () => setState(() => _status = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: active ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
