import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // PERUBAHAN: Gunakan satu controller untuk kedua video
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  // Palet warna yang senada dengan dashboard
  final Color bloodRed = const Color(0xFFE53935);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color lightRed = const Color(0xFFFF5252);
  final Color deepBlack = const Color(0xFF0A0A0A);
  final Color glassBlack = Colors.black.withOpacity(0.7);
  final Color cardDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    // PERUBAHAN: Hanya ada satu inisialisasi controller
    _controller = VideoPlayerController.asset("assets/videos/banner.mp4")
      ..initialize().then((_) {
        // Set state untuk memberitahu bahwa video telah diinisialisasi
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    // PERUBAHAN: Hanya dispose satu controller
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gradien yang disesuaikan dengan tema merah
    final gradientRed = LinearGradient(
      colors: [darkRed, bloodRed],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: deepBlack,
      body: Stack(
        children: [
          // 🔹 Background Video (menggunakan controller yang sama)
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          // 🔹 Layer Blur dan Gradien
          Container(
            decoration: BoxDecoration(
              gradient: gradientRed.withOpacity(0.2),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),

          // 🔹 Konten utama
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // PERUBAHAN: Card video banner dengan teks Tr4sVloid di dalamnya
                    Container(
                      width: double.infinity,
                      height: 200, // Atur tinggi sesuai kebutuhan
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: bloodRed.withOpacity(0.3),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: bloodRed.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Video di latar belakang
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _isVideoInitialized
                                ? VideoPlayer(_controller) // Gunakan controller yang sama
                                : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.red,
                              ),
                            ),
                          ),
                          // Teks Tr4sVloid di tengah
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Tr4sVloid",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: lightRed,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                      color: bloodRed.withOpacity(0.8),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Welcome to Tr4sVloid",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: lightRed.withOpacity(0.8), // Teks merah muda
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                            color: bloodRed.withOpacity(0.6), // Bayangan teks merah
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Please log in or register to continue",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // 🔹 Glass container tombol
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: glassBlack,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: bloodRed.withOpacity(0.3), // Border merah
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: bloodRed.withOpacity(0.2), // Bayangan merah
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tombol Login
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: bloodRed, // Tombol merah
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, "/login");
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Tombol Register
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: bloodRed.withOpacity(0.6), // Border merah
                                    width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () =>
                                  _openUrl("https://store.nullxteam.fun"),
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🔹 Sosial media glass footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      decoration: BoxDecoration(
                        color: glassBlack,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: bloodRed.withOpacity(0.3), // Border merah
                        ),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Contact Us",
                            style:
                            TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: FaIcon(
                                  FontAwesomeIcons.telegram,
                                  color: lightRed, // Ikon merah
                                  size: 28,
                                ),
                                onPressed: () =>
                                    _openUrl("https://t.me/xx_o_25"),
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                icon: const FaIcon(
                                  FontAwesomeIcons.tiktok,
                                  color: Colors.white70,
                                  size: 28,
                                ),
                                onPressed: () => _openUrl(
                                    "https://tiktok.com/@akuedrik1"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "© 2025 Tr4sVloid",
                            style:
                            TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
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