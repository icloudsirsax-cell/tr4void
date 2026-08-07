import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class NikCheckerPage extends StatefulWidget {
  const NikCheckerPage({super.key});

  @override
  State<NikCheckerPage> createState() => _NikCheckerPageState();
}

class _NikCheckerPageState extends State<NikCheckerPage> with SingleTickerProviderStateMixin {
  final TextEditingController _nikController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  final Color bloodRed = const Color(0xFFE53935);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color lightRed = const Color(0xFFFF5252);
  final Color deepBlack = const Color(0xFF0A0A0A);
  final Color cardDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _nikController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkNik() async {
    final nik = _nikController.text.trim();
    if (nik.isEmpty) {
      setState(() {
        _errorMessage = "NIK tidak boleh kosong.";
        _data = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _data = null;
    });

    final url = Uri.parse("https://api.siputzx.my.id/api/tools/nik-checker?nik=$nik");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == true && json['data'] != null) {
          setState(() {
            _data = json['data'];
            _errorMessage = null;
          });
          _animController.forward(from: 0);
        } else {
          setState(() {
            _errorMessage = "Data tidak ditemukan atau NIK tidak valid.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Gagal mengambil data dari server.";
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

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: darkRed.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: darkRed.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkRed, bloodRed],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveInfoRow({
    required String label,
    required String? value,
    IconData? copyIcon = Icons.copy,
    VoidCallback? onCopy,
  }) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deepBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkRed.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: Icon(copyIcon, color: lightRed, size: 20),
              onPressed: onCopy,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40),
              tooltip: 'Salin $label',
            ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin ke clipboard'),
        backgroundColor: darkRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBlack,
      appBar: AppBar(
        title: const Text(
          'NIK Check',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: darkRed,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: darkRed.withOpacity(0.5), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: darkRed.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Masukkan NIK',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Contoh: 5206085405880001',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: darkRed.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: bloodRed, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: deepBlack,
                        suffixIcon: _isLoading
                            ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: bloodRed,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                            : null,
                      ),
                      onSubmitted: (_) => _checkNik(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkNik,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bloodRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isLoading ? Icons.hourglass_top : Icons.search, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isLoading ? 'MEMPROSES...' : 'CEK DATA NIK',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightRed.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: lightRed),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              if (_data != null)
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildCategoryCard(
                            title: "IDENTITAS DIRI",
                            icon: Icons.person,
                            children: [
                              _buildInteractiveInfoRow(
                                label: "NIK",
                                value: _data!["nik"]?.toString(),
                                onCopy: () => _copyToClipboard(_data!["nik"]?.toString() ?? "", "NIK"),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Nama Lengkap",
                                value: _data!["data"]["nama"]?.toString(),
                                onCopy: () => _copyToClipboard(_data!["data"]["nama"]?.toString() ?? "", "Nama"),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Jenis Kelamin",
                                value: _data!["data"]["kelamin"]?.toString(),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Tempat Lahir",
                                value: _data!["data"]["tempat_lahir"]?.toString(),
                                onCopy: () => _copyToClipboard(_data!["data"]["tempat_lahir"]?.toString() ?? "", "Tempat Lahir"),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Usia",
                                value: _data!["data"]["usia"]?.toString(),
                              ),
                            ],
                          ),
                          _buildCategoryCard(
                            title: "DATA DOMISILI",
                            icon: Icons.location_on,
                            children: [
                              _buildInteractiveInfoRow(
                                label: "Provinsi",
                                value: _data!["data"]["provinsi"]?.toString(),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Kabupaten/Kota",
                                value: _data!["data"]["kabupaten"]?.toString(),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Kecamatan",
                                value: _data!["data"]["kecamatan"]?.toString(),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Kelurahan/Desa",
                                value: _data!["data"]["kelurahan"]?.toString(),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Alamat Lengkap",
                                value: _data!["data"]["alamat"]?.toString(),
                                onCopy: () => _copyToClipboard(_data!["data"]["alamat"]?.toString() ?? "", "Alamat"),
                              ),
                              _buildInteractiveInfoRow(
                                label: "TPS",
                                value: _data!["data"]["tps"]?.toString(),
                              ),
                            ],
                          ),
                          _buildCategoryCard(
                            title: "INFORMASI TAMBAHAN",
                            icon: Icons.info,
                            children: [
                              _buildInteractiveInfoRow(
                                label: "Zodiak",
                                value: _data!["data"]["zodiak"]?.toString(),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Ultah Mendatang",
                                value: _data!["data"]["ultah_mendatang"]?.toString(),
                              ),
                              _buildInteractiveInfoRow(
                                label: "Pasaran",
                                value: _data!["data"]["pasaran"]?.toString(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}