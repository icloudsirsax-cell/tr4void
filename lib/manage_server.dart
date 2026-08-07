import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageServerPage extends StatefulWidget {
  final String keyToken;
  const ManageServerPage({super.key, required this.keyToken});

  @override
  State<ManageServerPage> createState() => _ManageServerPageState();
}

class _ManageServerPageState extends State<ManageServerPage> {
  List<Map<String, dynamic>> vpsList = [];
  bool isLoading = false;

  final _hostController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  final Color bloodRed = const Color(0xFFE53935);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color lightRed = const Color(0xFFFF5252);
  final Color deepBlack = const Color(0xFF0A0A0A);
  final Color cardDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _fetchVpsList();
  }

  Future<void> _fetchVpsList() async {
    setState(() => isLoading = true);
    final uri = Uri.parse('https://evo.nullxteam.fun/myServer?key=${widget.keyToken}');
    try {
      final res = await http.get(uri);
      final data = jsonDecode(res.body);
      setState(() {
        vpsList = List<Map<String, dynamic>>.from(data);
      });
    } catch (_) {
      _showError("Gagal mengambil data VPS.");
    }
    setState(() => isLoading = false);
  }

  Future<void> _addVps() async {
    final host = _hostController.text.trim();
    final user = _userController.text.trim();
    final pass = _passController.text.trim();

    if (host.isEmpty || user.isEmpty || pass.isEmpty) {
      _showError("Isi semua field terlebih dahulu.");
      return;
    }

    final uri = Uri.parse('https://evo.nullxteam.fun/addServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
        'username': user,
        'password': pass,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _hostController.clear();
        _userController.clear();
        _passController.clear();
        _fetchVpsList();
      } else {
        _showError(data['error'] ?? 'Gagal menambah VPS');
      }
    } catch (_) {
      _showError("Gagal terhubung ke server.");
    }
  }

  Future<void> _deleteVps(String host) async {
    final uri = Uri.parse('https://evo.nullxteam.fun/delServer');
    try {
      final res = await http.post(uri, body: {
        'key': widget.keyToken,
        'host': host,
      });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _fetchVpsList();
      } else {
        _showError("Gagal menghapus VPS.");
      }
    } catch (_) {
      _showError("Gagal menghubungi server.");
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bloodRed.withOpacity(0.5)),
        ),
        title: Text("Error", style: TextStyle(color: bloodRed)),
        content: Text(msg, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: bloodRed)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: bloodRed.withOpacity(0.5)),
        ),
        title: Text("Tambah VPS", style: TextStyle(color: bloodRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInput("IP VPS", _hostController),
            _buildInput("Username", _userController),
            _buildInput("Password", _passController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("BATAL", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addVps();
            },
            child: Text("TAMBAH", style: TextStyle(color: bloodRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: bloodRed.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: bloodRed, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: deepBlack,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("My VPS List",
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontFamily: 'Orbitron')),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _showAddDialog,
                  )
                ],
              ),
              Divider(color: bloodRed.withOpacity(0.5)),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.builder(
                  itemCount: vpsList.length,
                  itemBuilder: (context, index) {
                    final vps = vpsList[index];
                    return Card(
                      color: cardDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: darkRed.withOpacity(0.3)),
                      ),
                      child: ListTile(
                        title: Text("${vps['host']}", style: const TextStyle(color: Colors.white)),
                        subtitle: Text("User: ${vps['username']}", style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: lightRed),
                          onPressed: () => _deleteVps(vps['host']),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}