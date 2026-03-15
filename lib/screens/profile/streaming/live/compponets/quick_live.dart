import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../controllers/live_room_controller.dart';
import '../pages/connector.dart';
import '../../../../auth/handler/supabase.dart';

const _bg = Color(0xFF1E1E1E);
const _surface = Color(0xFF2C2C2C);
const _red = Color(0xFFDC143C);
const _white = Colors.white;
const _grey = Colors.white70;
const _font = 'MazzardH';

class QuickLive {
  static void show(BuildContext context, {
    required String title,
    required String thumbnail,
    required String playId,
    required String subjectType,
    required double rating,
    required String yearOrEpisodes,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickLiveSheet(
        title: title,
        thumbnail: thumbnail,
        playId: playId,
        subjectType: subjectType,
        rating: rating,
        yearOrEpisodes: yearOrEpisodes,
      ),
    );
  }
}

class _QuickLiveSheet extends StatefulWidget {
  final String title, thumbnail, playId, subjectType, yearOrEpisodes;
  final double rating;
  const _QuickLiveSheet({
    required this.title,
    required this.thumbnail,
    required this.playId,
    required this.subjectType,
    required this.rating,
    required this.yearOrEpisodes,
  });

  @override
  State<_QuickLiveSheet> createState() => _QuickLiveSheetState();
}

class _QuickLiveSheetState extends State<_QuickLiveSheet> {
  final _passController = TextEditingController();
  bool _passVisible = false;
  bool _loading = false;
  String _username = '';
  late String _roomId;

  @override
  void initState() {
    super.initState();
    _roomId = _generateRoomId();
    _loadUsername();
  }

  String _generateRoomId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final a = (now % 10000).toString().padLeft(4, '0');
    final b = ((now ~/ 10000) % 10000).toString().padLeft(4, '0');
    return 'HIOTAKU-ROOM-$a-$b';
  }

  Future<void> _loadUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userData = await SupabaseHandler.getUserByFirebaseUID(uid);
    if (mounted) setState(() => _username = userData?['username'] ?? userData?['display_name'] ?? 'User');
  }

  Future<void> _startStream() async {
    setState(() => _loading = true);
    final room = await LiveRoomController.createRoom(
      title: widget.title,
      playId: widget.playId,
      thumbnail: widget.thumbnail,
      password: _passController.text.isEmpty ? null : _passController.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (room == null) {
      Fluttertoast.showToast(msg: 'Failed to create room');
      return;
    }
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LiveRoomPage(room: room),
    ));
  }

  @override
  void dispose() {
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Anime card
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.thumbnail.isNotEmpty
                            ? Image.network(widget.thumbnail, width: 70, height: 100, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _thumbPlaceholder())
                            : _thumbPlaceholder(),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _white, fontFamily: _font),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [
                              Text(widget.subjectType, style: const TextStyle(fontSize: 13, color: _grey, fontFamily: _font)),
                              const Text(' • ', style: TextStyle(color: _grey)),
                              const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 13),
                              const SizedBox(width: 3),
                              Text(widget.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 13, color: _grey, fontFamily: _font)),
                              const Text(' • ', style: TextStyle(color: _grey)),
                              Text(widget.yearOrEpisodes, style: const TextStyle(fontSize: 13, color: _grey, fontFamily: _font)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Username
                  Text('Username: $_username',
                    style: const TextStyle(fontSize: 15, color: _white, fontFamily: _font)),
                  const SizedBox(height: 12),

                  // Room ID
                  const Text('Room ID:', style: TextStyle(fontSize: 15, color: _white, fontFamily: _font)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(_roomId,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _white, fontFamily: _font),
                            overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          icon: const Icon(CupertinoIcons.doc_on_clipboard, color: _grey),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _roomId));
                            Fluttertoast.showToast(msg: 'Room ID copied!');
                          },
                          tooltip: 'Copy Room ID',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password field
                  TextField(
                    controller: _passController,
                    obscureText: !_passVisible,
                    style: const TextStyle(color: _white, fontFamily: _font),
                    decoration: InputDecoration(
                      hintText: 'Set Room Password (optional)',
                      hintStyle: const TextStyle(color: Colors.white54, fontFamily: _font),
                      filled: true,
                      fillColor: _surface,
                      prefixIcon: const Icon(CupertinoIcons.lock_fill, color: _grey),
                      suffixIcon: IconButton(
                        icon: Icon(_passVisible ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill, color: _grey),
                        onPressed: () => setState(() => _passVisible = !_passVisible),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: _red, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _white,
                            side: const BorderSide(color: Colors.white54, width: 1.5),
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _font),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _loading ? null : _startStream,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: _white,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _font),
                          ),
                          child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _white))
                              : const Text('Stream Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    width: 70, height: 100,
    decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
    child: const Icon(Icons.broken_image, color: Colors.white54),
  );
}
