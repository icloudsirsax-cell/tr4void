import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart'; // Impor url_launcher

import 'anime_home.dart';
import 'change_password.dart';
import 'bug_sender.dart';
import 'nik_check.dart';
import 'admin_page.dart';
import 'home_page.dart';
import 'seller_page.dart';
import 'tools_gateway.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String expiredDate;
  final String sessionKey;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late WebSocketChannel channel;

  // Controller untuk video background
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  late String sessionKey;
  late String username;
  late String password;
  late String role;
  late String expiredDate;
  late List<Map<String, dynamic>> listBug;
  late List<Map<String, dynamic>> listDoos;
  late List<dynamic> newsList;
  String androidId = "unknown";

  int _bottomNavIndex = 0;
  Widget _selectedPage = const Placeholder();

  // New black-red color scheme

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    password = widget.password;
    role = widget.role;
    expiredDate = widget.expiredDate;
    listBug = widget.listBug;
    listDoos = widget.listDoos;
    newsList = widget.news;

    // Inisialisasi video background
    _initializeVideo();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _selectedPage = _buildEnhancedNewsPage();
    _initAndroidIdAndConnect();
  }

  // Fungsi untuk menginisialisasi video
  void _initializeVideo() async {
    // Ganti 'assets/videos/bg.mp4' dengan path video Anda
    _videoController = VideoPlayerController.asset('assets/videos/bg.mp4')
      ..initialize().then((_) {
        // Atur volume ke 0 untuk video background
        _videoController.setVolume(0.0);
        // Atur video agar berulang
        _videoController.setLooping(true);
        // Mulai pemutaran video
        _videoController.play();
        // Update state untuk memberitahu bahwa video telah diinisialisasi
        setState(() {
          _isVideoInitialized = true;
        });
      });
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectToWebSocket();
  }

  void _connectToWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('wss://ws-evo.nullxteam.fun'));
    channel.sink.add(jsonEncode({
      "type": "validate",
      "key": sessionKey,
      "androidId": androidId,
    }));
    channel.sink.add(jsonEncode({"type": "stats"}));

    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo') {
        if (data['valid'] == false) {
          _handleInvalidSession("Session invalid, please re-login.");
        }
      }
    });
  }

  void _handleInvalidSession(String message) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: glassBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: bloodRed.withOpacity(0.5), width: 1),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: bloodRed, size: 28),
              const SizedBox(width: 10),
              Text("Session Expired",
                  style: TextStyle(color: bloodRed, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(
                color: bloodRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                  );
                },
                child: Text("OK", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) _selectedPage = _buildEnhancedNewsPage();
      else if (index == 1) {
        _selectedPage = HomePage(
          username: username,
          password: password,
          listBug: listBug,
          role: role,
          expiredDate: expiredDate,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = ToolsPage(sessionKey: sessionKey, userRole: role, listDoos: listDoos);
      } else if (index == 3) {
        _selectedPage = HomeAnimePage();
      }
    });
  }

  // Fungsi untuk navigasi ke Admin Page
  void _navigateToAdminPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminPage(sessionKey: sessionKey),
      ),
    );
  }

  // Fungsi untuk navigasi ke Seller Page
  void _navigateToSellerPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerPage(keyToken: sessionKey),
      ),
    );
  }

  int onlineUsers = 0;
  int activeConnections = 0;

  final Color bloodRed = const Color(0xFFE53935);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color lightRed = const Color(0xFFFF5252);
  final Color deepBlack = const Color(0xFF0A0A0A);
  final Color glassBlack = Colors.black.withOpacity(0.7);
  final Color primaryDark = Colors.black;
  final Color primaryPurple = const Color(0xFFB71C1C);
  final Color accentPurple = const Color(0xFFB71C1C);
  final Color lightPurple = const Color(0xFFB71C1C);
  final Color primaryWhite = Colors.white;
  final Color accentGrey = Colors.grey.shade400;
  final Color cardDark = const Color(0xFF1A1A1A);
  final Color purpleGradientStart = const Color(0xFFB71C1C);
  final Color purpleGradientEnd = const Color(0xFFB71C1C);

  Widget _buildCompactInfoItem({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    // PERUBAHAN: Bungkus seluruh item dalam Container untuk border penuh
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Beri jarak antar item
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryPurple.withOpacity(0.3)), // Border penuh
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: lightPurple, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'ShareTechMono',
                    shadows: valueColor == primaryWhite ? [
                      Shadow(
                        color: primaryPurple.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ] : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case "owner":
        return Colors.red;
      case "vip":
        return primaryPurple;
      case "reseller":
        return Colors.green;
      case "premium":
        return Colors.orange;
      default:
        return lightPurple;
    }
  }

  // Widget untuk membangun video background
  Widget _buildVideoBackground() {
    if (_isVideoInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController.value.size.width,
            height: _videoController.value.size.height,
            child: VideoPlayer(_videoController),
          ),
        ),
      );
    } else {
      // Tampilkan layar hitam jika video belum dimuat
      return Container(color: deepBlack);
    }
  }

  Widget _buildEnhancedNewsPage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            deepBlack,
            Colors.black,
            Colors.black,
            deepBlack,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Video Background
          _buildVideoBackground(),

          // Overlay untuk membuat konten lebih terlihat
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
            ),
          ),

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Ganti dengan kode ini
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Container(
                      // Container ini akan menjadi kartu dengan background gradien
                      padding: const EdgeInsets.all(20), // Padding internal untuk konten
                      decoration: BoxDecoration(
                        // Gradient dari bloodRed ke darkRed
                        gradient: LinearGradient(
                          colors: [darkRed, darkRed, darkRed, bloodRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24), // Sudut melengkung yang konsisten
                        // Tambahkan border untuk tetap terlihat rapi
                        border: Border.all(
                          color: bloodRed.withOpacity(0.5), // Border yang sedikit lebih terang
                          width: 1.5,
                        ),
                        // Tambahkan bayangan untuk efek kedalaman
                        boxShadow: [
                          BoxShadow(
                            color: bloodRed.withOpacity(0.3), // Bayangan merah
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header "Welcome Back"
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                // Ubah latar ikon menjadi lebih terang agar kontras dengan gradien merah
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.dashboard,
                                  color: Colors.white, // Ikon putih agar kontras
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Welcome back",
                                      style: TextStyle(
                                        color: Colors.white70, // Teks tetap putih keabu-abuan
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Tr4sVloid Dashboard",
                                      style: TextStyle(
                                        color: Colors.white, // Teks utama putih agar kontras
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Quick Stats di dalam kartu
                          Row(
                            children: [
                              _buildQuickStat(
                                icon: Icons.people,
                                label: "Online",
                                value: "$onlineUsers",
                              ),
                              const SizedBox(width: 16),
                              _buildQuickStat(
                                icon: Icons.link,
                                label: "Connections",
                                value: "$activeConnections",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Bungkus "Latest News" dan carousel dalam Column dengan alignment kiri
                  if (newsList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 21),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Ini adalah kuncinya
                        children: [
                          const Text(
                            "Latest News",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Carousel berita
                          SizedBox(
                            width: double.infinity,
                            height: 200,
                            child: PageView.builder(
                              controller: PageController(viewportFraction: 0.9),
                              itemCount: newsList.length,
                              itemBuilder: (context, i) {
                                final item = newsList[i];
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  margin: const EdgeInsets.symmetric(horizontal: 5 ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.8),
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: bloodRed.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: bloodRed.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (item['image'] != null)
                                          NewsMedia(url: item['image']),
                                        // Red Gradient Overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.black.withOpacity(0.8),
                                                Colors.transparent,
                                                Colors.black.withOpacity(0.9),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              stops: const [0.0, 0.5, 1.0],
                                            ),
                                          ),
                                        ),
                                        // Content Container with Red Accent
                                        // Content Container (tanpa blur dan gradien)
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          // Hanya menggunakan padding untuk memberikan jarak pada teks
                                          child: Container(
                                            padding: const EdgeInsets.all(20),
                                            // Tidak ada dekorasi (color, borderRadius, border)
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['title'] ?? 'No Title',
                                                  style: TextStyle(
                                                    // Warna teks diubah menjadi putih agar kontras dengan gambar
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16, // Sedikit diperbesar untuk keterbacaan
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  item['desc'] ?? '',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    // Warna teks diubah menjadi putih agar kontras
                                                    color: Colors.white70,
                                                    fontSize: 12, // Sedikit diperbesar untuk keterbacaan
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (newsList.isNotEmpty) const SizedBox(height: 20),

                  // Enhanced Account Info Card with Red Theme
                  // Enhanced Account Info Card with Red Theme
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header - Dengan gradien ungu
                          Container(
                            width: double.infinity, // PERUBAHAN: Pastikan header memanjang penuh
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryPurple, accentPurple],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryPurple.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPurple.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, color: primaryWhite, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "ACCOUNT INFO",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontSize: 16,
                                    fontFamily: 'Orbitron',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // User Info
                          _buildCompactInfoItem(
                            icon: Icons.person,
                            label: "Username",
                            value: username,
                          ),
                          // PERUBAHAN: Hapus SizedBox(height) karena sudah ada margin di dalam fungsi

                          _buildCompactInfoItem(
                            icon: Icons.verified_user,
                            label: "Role",
                            value: role.toUpperCase(),
                            valueColor: _getRoleColor(role),
                          ),

                          _buildCompactInfoItem(
                            icon: Icons.calendar_today,
                            label: "Expired",
                            value: expiredDate,
                          ),

                          // Stats dalam satu row (Tetap menggunakan Row karena ini adalah 2 item sejajar)
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactInfoItem(
                                  icon: Icons.people,
                                  label: "Online",
                                  value: "$onlineUsers",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCompactInfoItem(
                                  icon: Icons.link,
                                  label: "Connections",
                                  value: "$activeConnections",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // About Me Section
                  // Tombol Manage Bug Sender - Dengan gradien ungu
                  Container(
                    width: 320,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.bug_report, color: primaryWhite, size: 18),
                      label: Text(
                        "MANAGE BUG SENDER",
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: lightPurple.withOpacity(0.5)),
                        ),
                        elevation: 4,
                        shadowColor: primaryPurple.withOpacity(0.5),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BugSenderPage(
                              sessionKey: sessionKey,
                              username: username,
                              role: role,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // About Me Section dengan background cardDark
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      // PERUBAHAN: Hapus border dan boxShadow dari Container luar
                      decoration: BoxDecoration(
                        color: cardDark, // Gunakan warna yang sama dengan Account Info
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header - Dengan gradien ungu (sama seperti Account Info)
                          // PERUBAHAN: Pindahkan border dan boxShadow ke sini
                          Container(
                            width: double.infinity, // PERUBAHAN: Pastikan header memanjang penuh
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryPurple, accentPurple],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: primaryPurple.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPurple.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_outline, color: primaryWhite, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "ACCOUNT INFO",
                                  style: TextStyle(
                                    color: primaryWhite,
                                    fontSize: 16,
                                    fontFamily: 'Orbitron',
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: _buildContactActions(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membangun tombol kontak
  List<Widget> _buildContactActions() {
    return [
      _contactActionButton(
        icon: FontAwesomeIcons.telegram,
        label: "Telegram",
        url: 'https://t.me/EdrikReal12',
        color: lightRed,
      ),
      _contactActionButton(
        icon: FontAwesomeIcons.telegram,
        label: "Channel",
        url: 'https://t.me/Tra4Svloid1',
        color: lightRed,
      ),
      _contactActionButton(
        icon: FontAwesomeIcons.tiktok,
        label: "TikTok",
        url: 'https://www.tiktok.com/@akuedrik1',
        color: lightRed,
      ),
    ];
  }

  Widget _contactActionButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          await launchUrl(uri);
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _enhancedGlassCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glassBlack,
        borderRadius: BorderRadius.circular(24),
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

  Widget _enhancedInfoRow(IconData icon, String label, String value,
      {Color valueColor = Colors.white}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bloodRed.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bloodRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: bloodRed, size: 20),
          ),
          const SizedBox(width: 12),
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // PERUBAHAN: Tambahkan drawer ke Scaffold
      drawer: _buildDrawer(),
      backgroundColor: deepBlack,
      extendBody: true,
// Di dalam method build(), ubah bagian AppBar menjadi:

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Colors.white, Colors.white],
          ).createShader(bounds),
          child: const Text(
            "Tr4sVloid",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          // Dummy notification icon
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Dummy notification action
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("No new notifications"),
                  backgroundColor: bloodRed,
                ),
              );
            },
          ),
          // Logout button
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              // Tampilkan dialog konfirmasi logout
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: cardDark,
                  title: Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    "Are you sure you want to logout?",
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: bloodRed),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Tutup dialog
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        if (!mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                              (route) => false,
                        );
                      },
                      child: Text(
                        "Logout",
                        style: TextStyle(color: bloodRed),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(opacity: _animation, child: _selectedPage),
      bottomNavigationBar: _buildGlassBottomNavBar(),
    );
  }


  // PERUBAHAN: Tambahkan widget Drawer
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: cardDark,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkRed, bloodRed],
              ),
            ),
            // PERUBAHAN: Bungkus konten header dalam Column untuk mengatur tata letak
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PERUBAHAN: Gunakan Row untuk meletakkan logo dan teks sejajar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            bloodRed,
                            lightRed,
                            darkRed,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: bloodRed.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28, // Sedikit diperkecil untuk memberi ruang bagi teks
                        backgroundColor: cardDark,
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: AssetImage('assets/images/logo.jpg'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16), // Jarak antara logo dan teks
                    // Teks "Tr4sVloid" yang baru ditambahkan
                    Expanded(
                      child: Text(
                        'Tr4sVloid',
                        style: TextStyle(
                          color: primaryWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron', // Opsional: gunakan font yang sama dengan appbar
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 5,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Tambahkan jarak sebelum info user
                // Info pengguna tetap di bawah
                Text(
                  'User: $username',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Role: ${role.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Expired At: $expiredDate',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (role == "owner")
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: bloodRed),
              title: Text('Admin Page', style: TextStyle(color: primaryWhite)),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                _navigateToAdminPage(); // Navigasi ke halaman admin
              },
            ),
          if (role == "reseller")
            ListTile(
              leading: Icon(Icons.add_shopping_cart, color: bloodRed),
              title: Text('Seller Page', style: TextStyle(color: primaryWhite)),
              onTap: () {
                Navigator.pop(context); // Tutup drawer
                _navigateToSellerPage(); // Navigasi ke halaman seller
              },
            ),
          ListTile(
            leading: Icon(Icons.lock_clock, color: bloodRed),
            title: Text('Change Password', style: TextStyle(color: primaryWhite)),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangePasswordPage(username: username, sessionKey: sessionKey),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.person, color: bloodRed),
            title: Text('NIK Check', style: TextStyle(color: primaryWhite)),
            onTap: () {
              Navigator.pop(context); // Tutup drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NikCheckerPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGlassBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: glassBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bloodRed.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: bloodRed.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            selectedItemColor: bloodRed,
            unselectedItemColor: Colors.white54,
            currentIndex: _bottomNavIndex,
            onTap: _onBottomNavTapped,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(FontAwesomeIcons.whatsapp),
                label: "WhatsApp",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.build_circle_outlined),
                label: "Tools",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.movie_filter_outlined),
                label: "Anime",
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: glassBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: bloodRed.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: bloodRed.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: bloodRed.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [bloodRed, lightRed],
                  ).createShader(bounds),
                  child: const Text(
                    "Account Info",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                _enhancedInfoRow(Icons.person, "Username", username),
                _enhancedInfoRow(Icons.shield, "Role", role),
                _enhancedInfoRow(Icons.calendar_today, "Expired", expiredDate),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bloodRed, darkRed],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                            (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Hentikan dan dispose video controller
    _videoController.dispose();
    channel.sink.close(status.goingAway);
    _controller.dispose();
    super.dispose();
  }
}

class NewsMedia extends StatefulWidget {
  final String url;
  const NewsMedia({super.key, required this.url});

  @override
  State<NewsMedia> createState() => _NewsMediaState();
}

class _NewsMediaState extends State<NewsMedia> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.url)) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          setState(() {});
          _controller?.setLooping(true);
          _controller?.setVolume(0.0);
          _controller?.play();
        });
    }
  }

  bool _isVideo(String url) =>
      url.endsWith(".mp4") ||
          url.endsWith(".webm") ||
          url.endsWith(".mov") ||
          url.endsWith(".mkv");

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.url)) {
      if (_controller != null && _controller!.value.isInitialized) {
        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      } else {
        return Center(child: CircularProgressIndicator(color: Colors.red));
      }
    } else {
      return Image.network(widget.url, fit: BoxFit.cover);
    }
  }
}

// Custom painter for grid pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const gridSize = 30.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}