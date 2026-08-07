import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NglPage extends StatefulWidget {
  const NglPage({super.key});

  @override
  State<NglPage> createState() => _NglPageState();
}

class _NglPageState extends State<NglPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isRunning = false;
  int counter = 0;
  String statusLog = "";
  Timer? timer;

  final Color bloodRed = const Color(0xFFE53935);
  final Color darkRed = const Color(0xFFB71C1C);
  final Color lightRed = const Color(0xFFFF5252);
  final Color deepBlack = const Color(0xFF0A0A0A);
  final Color cardDark = const Color(0xFF1A1A1A);

  String generateDeviceId(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(16).toRadixString(16)).join();
  }

  Future<void> sendMessage(String username, String message) async {
    final deviceId = generateDeviceId(42);
    final url = Uri.parse("https://ngl.link/api/submit");

    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/109.0",
      "Accept": "*/*",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "X-Requested-With": "XMLHttpRequest",
      "Referer": "https://ngl.link/$username",
      "Origin": "https://ngl.link"
    };

    final body =
        "username=$username&question=$message&deviceId=$deviceId&gameSlug=&referrer=";

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          counter++;
          statusLog = "✅ [$counter] Pesan terkirim";
        });
      } else {
        setState(() {
          statusLog = "❌ Ratelimit (${response.statusCode}), tunggu 5 detik...";
        });
        await Future.delayed(const Duration(seconds: 5));
      }
    } catch (e) {
      setState(() {
        statusLog = "⚠️ Error: $e";
      });
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  void startLoop() {
    final username = usernameController.text.trim();
    final message = messageController.text.trim();

    if (username.isEmpty || message.isEmpty) {
      setState(() {
        statusLog = "⚠️ Harap isi username & pesan!";
      });
      return;
    }

    setState(() {
      isRunning = true;
      counter = 0;
      statusLog = "▶️ Mulai mengirim...";
    });

    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (isRunning) {
        sendMessage(username, message);
      }
    });
  }

  void stopLoop() {
    setState(() {
      isRunning = false;
      statusLog = "⏹️ Dihentikan.";
    });
    timer?.cancel();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepBlack,
      appBar: AppBar(
        title: const Text("NGL Auto Sender"),
        backgroundColor: darkRed,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bloodRed.withOpacity(0.3)),
              ),
              child: TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Username NGL",
                  labelStyle: TextStyle(color: Colors.white70),
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
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bloodRed.withOpacity(0.3)),
              ),
              child: TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Pesan",
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: bloodRed.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: bloodRed, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: isRunning ? null : startLoop,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Start"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bloodRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: isRunning ? stopLoop : null,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bloodRed.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    statusLog,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  if (counter > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Total terkirim: $counter",
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
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
}