import 'package:flutter/material.dart';

class LiveRoomPage extends StatelessWidget {
  final Map<String, dynamic> room;
  const LiveRoomPage({Key? key, required this.room}) : super(key: key);

  String get roomId => room['room_id'] ?? '';
  String get title => room['title'] ?? 'Live Room';
  String get thumbnail => room['thumbnail'] ?? '';
  String get playId => room['play_id'] ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(thumbnail, width: 160, height: 220, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'MazzardH', fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Room: $roomId', style: const TextStyle(color: Color(0xFFCCCCCC), fontFamily: 'MazzardH', fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
