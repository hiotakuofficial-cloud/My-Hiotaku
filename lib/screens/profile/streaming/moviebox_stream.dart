import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache/cache.dart';

const _bg = Color(0xFF121212);
const _surface = Color(0xFF1A1A1A);
const _red = Color(0xFFDC143C);
const _white = Colors.white;
const _grey = Color(0xFFB0B0B0);
const _font = 'MazzardH';

class MovieBoxStream extends StatefulWidget {
  const MovieBoxStream({Key? key}) : super(key: key);

  @override
  State<MovieBoxStream> createState() => _MovieBoxStreamState();
}

class _MovieBoxStreamState extends State<MovieBoxStream> {
  final _client = Supabase.instance.client;
  List<Map<String, dynamic>> _liveRooms = [];
  List<Map<String, dynamic>> _mostWatching = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadRooms();
    _subscribeRealtime();
  }

  Future<void> _loadRooms() async {
    final res = await _client
        .from('live_rooms')
        .select()
        .order('current_watching', ascending: false);
    if (!mounted) return;
    final rooms = List<Map<String, dynamic>>.from(res);
    setState(() {
      _liveRooms = rooms;
      _mostWatching = [...rooms]..sort((a, b) =>
          (b['current_watching'] as int).compareTo(a['current_watching'] as int));
      _loading = false;
    });
  }

  void _subscribeRealtime() {
    _channel = _client
        .channel('live_rooms_stream')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'live_rooms',
          callback: (_) => _loadRooms(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Live Streams', style: TextStyle(color: _white, fontFamily: _font, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: _white),
            onPressed: () {},
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _red))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Create / Join buttons
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        Expanded(child: _ActionBtn(label: 'Create Room', onTap: () {})),
                        const SizedBox(width: 16),
                        Expanded(child: _ActionBtn(label: 'Join Room', onTap: () {}, outlined: true)),
                      ],
                    ),
                  ),
                ),

                // Live Now
                _sectionTitle('Live Now'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: _liveRooms.isEmpty
                        ? _emptyHint('No live rooms right now')
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _liveRooms.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _LiveRoomCard(room: _liveRooms[i]),
                            ),
                          ),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(top: 24)),

                // Most Watching
                _sectionTitle('Most Watching'),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 220,
                    child: _mostWatching.isEmpty
                        ? _emptyHint('No data yet')
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _mostWatching.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _MostWatchingCard(room: _mostWatching[i]),
                            ),
                          ),
                  ),
                ),

                const SliverPadding(padding: EdgeInsets.only(top: 24)),

                // Create Room card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: _CreateRoomCard(onTap: () {}),
                  ),
                ),
              ],
            ),
    );
  }

  SliverToBoxAdapter _sectionTitle(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Text(title, style: const TextStyle(color: _white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: _font)),
    ),
  );

  Widget _emptyHint(String msg) => Center(
    child: Text(msg, style: const TextStyle(color: _grey, fontFamily: _font)),
  );
}

// ── Live Room Card ────────────────────────────────────────────────────────────
class _LiveRoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  const _LiveRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedImage(url: room['thumbnail'] ?? '', width: 80, height: 140, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(room['title'] ?? '', style: const TextStyle(color: _white, fontWeight: FontWeight.bold, fontFamily: _font, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('Host: ${room['user_id'] ?? ''}', style: const TextStyle(color: _grey, fontSize: 12, fontFamily: _font), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Icon(Icons.remove_red_eye_rounded, size: 14, color: _grey),
                        const SizedBox(width: 4),
                        Text('${room['current_watching'] ?? 0} watching', style: const TextStyle(color: _grey, fontSize: 12, fontFamily: _font)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Most Watching Card ────────────────────────────────────────────────────────
class _MostWatchingCard extends StatelessWidget {
  final Map<String, dynamic> room;
  const _MostWatchingCard({required this.room});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedImage(url: room['thumbnail'] ?? '', height: 140, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: _red.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.local_fire_department_rounded, size: 14, color: _white),
                        const SizedBox(width: 4),
                        Text('${room['current_watching'] ?? 0}', style: const TextStyle(color: _white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: _font)),
                      ]),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(room['title'] ?? '', style: const TextStyle(color: _white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: _font), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create Room Card ──────────────────────────────────────────────────────────
class _CreateRoomCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateRoomCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_red.withOpacity(0.8), _red], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: _red.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.videocam_rounded, size: 48, color: _white),
                const SizedBox(height: 16),
                const Text('Start Your Own Stream', style: TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: _font)),
                const SizedBox(height: 8),
                const Text('Create a room and watch anime together with friends.', style: TextStyle(color: _grey, fontFamily: _font)),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: _red,
                      backgroundColor: _white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: _font),
                    ),
                    child: const Text('Create Room'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionBtn({required this.label, required this.onTap, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return outlined
        ? OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: _white,
              side: const BorderSide(color: _red, width: 1.5),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _font),
            ),
            child: Text(label),
          )
        : ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: _white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _font),
            ),
            child: Text(label),
          );
  }
}
