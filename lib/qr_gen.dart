import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui';

class QrGeneratorPage extends StatefulWidget {
  const QrGeneratorPage({super.key});

  @override
  State<QrGeneratorPage> createState() => _QrGeneratorPageState();
}

class _QrGeneratorPageState extends State<QrGeneratorPage> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _qrImage;
  String? _errorMessage;

  final Color bloodRed = const Color(0xFFE53935);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color lightRed = const Color(0xFFFF5252);
  final Color deepBlack = const Color(0xFF0A0A0A);
  final Color cardDark = const Color(0xFF1A1A1A);

  Future<void> _generateQR() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = "Text tidak boleh kosong.";
        _qrImage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _qrImage = null;
    });

    final encodedText = Uri.encodeComponent(text);
    final url = Uri.parse("https://api.siputzx.my.id/api/tools/text2qr?text=$encodedText");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _qrImage = response.bodyBytes;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal generate QR Code.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _shareQR() async {
    if (_qrImage == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/qr_code_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(_qrImage!);

      await Share.shareXFiles([XFile(file.path)],
        text: 'QR Code dari: ${_textController.text}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: darkRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: bloodRed.withOpacity(0.3)),
          ),
        ),
      );
    }
  }

  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardDark,
            cardDark.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: bloodRed.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: bloodRed.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildGlassInputField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            cardDark,
            cardDark.withOpacity(0.8),
          ],
        ),
      ),
      child: TextField(
        controller: _textController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: bloodRed,
        decoration: InputDecoration(
          labelText: 'Masukkan Text/URL',
          labelStyle: const TextStyle(color: Colors.white70),
          hintText: 'Contoh: https://google.com',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(Icons.text_fields, color: bloodRed),
          filled: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: bloodRed.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: bloodRed, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: bloodRed.withOpacity(0.3)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onSubmitted: (_) => _generateQR(),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBlack,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    bloodRed.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    darkRed.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildGlassCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, color: bloodRed, size: 32),
                          const SizedBox(width: 12),
                          const Text(
                            "QR GENERATOR",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    _buildGlassCard(
                      child: Column(
                        children: [
                          _buildGlassInputField(),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            text: "GENERATE QR",
                            icon: Icons.qr_code,
                            onPressed: _generateQR,
                            color: bloodRed,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_errorMessage != null)
                      _buildGlassCard(
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: lightRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    if (_qrImage != null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildGlassCard(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            cardDark,
                                            cardDark.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: bloodRed.withOpacity(0.3)),
                                      ),
                                      child: Image.memory(_qrImage!),
                                    ),

                                    const SizedBox(height: 20),

                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            cardDark,
                                            cardDark.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: bloodRed.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.text_snippet, color: bloodRed, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _textController.text,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    _buildActionButton(
                                      text: "SHARE QR CODE",
                                      icon: Icons.share,
                                      onPressed: _shareQR,
                                      color: darkRed,
                                      isLoading: false,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              _buildGlassCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.info, color: bloodRed, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "QR Code berhasil digenerate dari teks/URL",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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