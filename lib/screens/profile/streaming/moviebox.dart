import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/moviebox_service.dart';
import 'components/bottom_nav.dart';
import 'moviebox_detail.dart';
import 'moviebox_search.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  // Palette
  static const bg       = Color(0xFF0A0A0F);
  static const surface  = Color(0xFF13131A);
  static const card     = Color(0xFF1C1C27);
  static const accent   = Color(0xFFE5003C);   // deep crimson
  static const accentLo = Color(0x33E5003C);
  static const gold     = Color(0xFFD4AF37);
  static const white    = Colors.white;
  static const grey60   = Color(0xFF9A9AAF);
  static const grey30   = Color(0xFF3A3A4F);

  // Radii
  static const r4  = Radius.circular(4);
  static const r8  = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);

  // Typography — MazzardH assumed available
  static const String font = 'MazzardH';
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class MovieBoxHome extends StatefulWidget {
  const MovieBoxHome({Key? key}) : super(key: key);

  @override
  State<MovieBoxHome> createState() => _MovieBoxHomeState();
}

class _MovieBoxHomeState extends State<MovieBoxHome>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _heroZoomCtrl;
  late Animation<double>   _heroZoom;
  late AnimationController _heroTextCtrl;
  late Animation<double>   _heroFade;
  late Animation<Offset>   _heroSlide;
  late AnimationController _titleCtrl;
  late Animation<double>   _titleFade;
  late PageController      _pageCtrl;

  Timer? _autoScrollTimer;
  Timer? _titleTimer;

  bool                   _isLoading      = true;
  Map<String, dynamic>?  _trendingData;
  String?                _error;
  int                    _currentPage    = 0;
  int                    _currentNavIdx  = 0;
  int                    _currentTitleIdx = 0;

  static const _titles = ['Streaming', 'Watch Together', 'Live Chatting', 'Friends Mode'];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _pageCtrl = PageController(viewportFraction: 1.0);

    // Hero background slow zoom
    _heroZoomCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat(reverse: true);
    _heroZoom = Tween<double>(begin: 1.0, end: 1.10)
        .animate(CurvedAnimation(parent: _heroZoomCtrl, curve: Curves.easeInOut));

    // Hero text entrance
    _heroTextCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _heroFade  = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _heroTextCtrl, curve: Curves.easeOut));
    _heroSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _heroTextCtrl, curve: Curves.easeOut));

    // AppBar title crossfade
    _titleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _titleFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _titleCtrl, curve: Curves.easeInOut));
    _titleCtrl.forward();

    _startTitleCycle();
    _loadData();
  }

  void _startTitleCycle() {
    _titleTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      await _titleCtrl.reverse();
      setState(() => _currentTitleIdx = (_currentTitleIdx + 1) % _titles.length);
      _titleCtrl.forward();
    });
  }

  void _startAutoScroll(int count) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageCtrl.hasClients || count == 0) return;
      final next = (_currentPage + 1) % count;
      if (next == 0) {
        _pageCtrl.jumpToPage(0);
        setState(() => _currentPage = 0);
      } else {
        _pageCtrl.animateToPage(next,
            duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      }
      _heroTextCtrl.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _titleTimer?.cancel();
    _pageCtrl.dispose();
    _heroZoomCtrl.dispose();
    _heroTextCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final trending = await MovieBoxService.getTrending(perPage: 20);
      setState(() { _trendingData = trending; _isLoading = false; });
      final list = trending['data']?['subjectList'] as List? ?? [];
      if (list.length > 1) _startAutoScroll(list.take(5).length);
      _heroTextCtrl.forward();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    color: _T.accent,
                    backgroundColor: _T.surface,
                    onRefresh: _loadData,
                    child: _buildContent(),
                  ),
      ),
      bottomNavigationBar: StreamingBottomNav(
        currentIndex: _currentNavIdx,
        onTap: (i) { if (i != _currentNavIdx) setState(() => _currentNavIdx = i); },
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      height: kToolbarHeight + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: _T.bg.withOpacity(0.55),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Image.asset('assets/images/logo.png', width: 20, height: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.movie_filter_rounded, color: _T.white, size: 20);
                  },
                ),
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        _titles[_currentTitleIdx],
                        style: const TextStyle(
                          color: _T.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          fontFamily: _T.font,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search_rounded, color: _T.white, size: 24),
                  onPressed: () => Navigator.push(context, _fadeRoute(const MovieBoxSearch())),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── States ─────────────────────────────────────────────────────────────────
  Widget _buildLoading() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40, height: 40,
          child: CircularProgressIndicator(
            color: _T.accent, strokeWidth: 2,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Loading…', style: TextStyle(color: _T.grey60, fontFamily: _T.font, fontSize: 13)),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _T.accentLo,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded, size: 36, color: _T.accent),
          ),
          const SizedBox(height: 20),
          const Text('Something went wrong', style: TextStyle(color: _T.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: _T.font)),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _T.grey60, fontSize: 13, fontFamily: _T.font)),
          const SizedBox(height: 28),
          _PillButton(label: 'Try Again', icon: Icons.refresh_rounded, onTap: _loadData),
        ],
      ),
    ),
  );

  // ── Main Content ───────────────────────────────────────────────────────────
  Widget _buildContent() {
    final trending = _trendingData?['data']?['subjectList'] as List? ?? [];
    final hero = trending.take(5).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── AppBar
        SliverToBoxAdapter(child: _buildAppBar()),
        
        // ── Hero Carousel
        if (hero.isNotEmpty)
          SliverToBoxAdapter(child: _HeroCarousel(
            movies: hero,
            pageCtrl: _pageCtrl,
            zoomAnim: _heroZoom,
            fadeAnim: _heroFade,
            slideAnim: _heroSlide,
            currentPage: _currentPage,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _heroTextCtrl.forward(from: 0);
            },
          )),

        // ── Section gap
        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _SectionHeader(
              label: 'Trending Now',
              trailing: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(foregroundColor: _T.accent, padding: EdgeInsets.zero),
                child: const Text('See all', style: TextStyle(fontFamily: _T.font, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 14)),

        // ── Trending Grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final m = trending[index];
                return _MovieCard(
                  imageUrl:  m['cover']?['url'] ?? '',
                  title:     m['title'] ?? '',
                  rating:    m['imdbRatingValue'] ?? '—',
                  onTap: () => Navigator.push(context, _fadeRoute(MovieBoxDetail(
                    subjectId:  m['subjectId'] ?? '',
                    detailPath: m['detailPath'],
                  ))),
                );
              },
              childCount: trending.length > 9 ? 9 : trending.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.62,
            ),
          ),
        ),

        // Bottom nav padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO CAROUSEL
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCarousel extends StatelessWidget {
  final List<dynamic>     movies;
  final PageController    pageCtrl;
  final Animation<double> zoomAnim;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final int               currentPage;
  final ValueChanged<int> onPageChanged;

  const _HeroCarousel({
    required this.movies,
    required this.pageCtrl,
    required this.zoomAnim,
    required this.fadeAnim,
    required this.slideAnim,
    required this.currentPage,
    required this.onPageChanged,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.62;
    return SizedBox(
      height: h,
      child: PageView.builder(
        controller: pageCtrl,
        physics: const BouncingScrollPhysics(),
        onPageChanged: onPageChanged,
        itemCount: movies.length,
        itemBuilder: (_, i) => _HeroSlide(
          movie:     movies[i],
          height:    h,
          zoomAnim:  zoomAnim,
          fadeAnim:  fadeAnim,
          slideAnim: slideAnim,
          isActive:  i == currentPage,
          dotCount:  movies.length,
          currentDot: currentPage,
        ),
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final Map<String, dynamic> movie;
  final double               height;
  final Animation<double>    zoomAnim;
  final Animation<double>    fadeAnim;
  final Animation<Offset>    slideAnim;
  final bool                 isActive;
  final int                  dotCount;
  final int                  currentDot;

  const _HeroSlide({
    required this.movie,
    required this.height,
    required this.zoomAnim,
    required this.fadeAnim,
    required this.slideAnim,
    required this.isActive,
    required this.dotCount,
    required this.currentDot,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = movie['cover']?['url'] ?? '';
    final title    = movie['title'] ?? '';
    final year     = (movie['releaseDate']?.toString() ?? '').split('-').first;
    final rating   = movie['imdbRatingValue'] ?? '—';
    final genre    = (movie['genre']?.toString() ?? '').split(',').take(2).join(' · ');

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // ── Background zoom
          Positioned.fill(
            child: AnimatedBuilder(
              animation: zoomAnim,
              builder: (_, __) => Transform.scale(
                scale: zoomAnim.value,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E1E2E), _T.bg],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: const Icon(Icons.broken_image, color: _T.grey60, size: 48),
                  ),
                ),
              ),
            ),
          ),

          // ── Cinematic gradient layers
          Positioned.fill(child: _gradientOverlay()),

          // ── Left vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.transparent],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // ── Noise grain texture (subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset('assets/images/noise.png', fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          ),

          // ── Content
          Positioned(
            bottom: 32,
            left: 0, right: 0,
            child: FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: Column(
                  children: [
                    // Genre pill
                    if (genre.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: _T.accent.withOpacity(0.6)),
                          borderRadius: const BorderRadius.all(_T.r4),
                        ),
                        child: Text(genre.toUpperCase(),
                          style: const TextStyle(
                            color: _T.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: _T.font,
                            letterSpacing: 2,
                          )),
                      ),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 36),
                      child: Text(title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _T.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          fontFamily: _T.font,
                          letterSpacing: -0.3,
                          height: 1.15,
                          shadows: [Shadow(color: Colors.black, blurRadius: 24, offset: Offset(0, 4))],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Meta row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _MetaPill(label: year, icon: Icons.calendar_today_rounded, iconSize: 11),
                        const SizedBox(width: 10),
                        _MetaPill(label: rating, icon: Icons.star_rounded, iconSize: 13, accent: true),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // CTA buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PillButton(
                          label: 'Play Now',
                          icon: Icons.play_arrow_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              _fadeRoute(MovieBoxDetail(
                                subjectId: movie['subjectId'] ?? '',
                                detailPath: movie['detailPath'],
                              )),
                            );
                          },
                          filled: true,
                        ),
                        const SizedBox(width: 12),
                        _PillButton(
                          label: 'Details',
                          icon: Icons.info_outline_rounded,
                          onTap: () {
                            Navigator.push(
                              context,
                              _fadeRoute(MovieBoxDetail(
                                subjectId: movie['subjectId'] ?? '',
                                detailPath: movie['detailPath'],
                              )),
                            );
                          },
                          filled: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(dotCount, (i) {
                        final active = i == currentDot;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active ? _T.accent : Colors.white.withOpacity(0.25),
                            borderRadius: const BorderRadius.all(Radius.circular(3)),
                          ),
                        );
                      }),
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

  Widget _gradientOverlay() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.0),
          Colors.black.withOpacity(0.15),
          Colors.black.withOpacity(0.55),
          Colors.black.withOpacity(0.82),
          _T.bg,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// META PILL
// ─────────────────────────────────────────────────────────────────────────────
class _MetaPill extends StatelessWidget {
  final String  label;
  final IconData icon;
  final double  iconSize;
  final bool    accent;

  const _MetaPill({
    required this.label,
    required this.icon,
    this.iconSize = 11,
    this.accent = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(_T.r4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: accent ? _T.accentLo : Colors.white.withOpacity(0.12),
            borderRadius: const BorderRadius.all(_T.r4),
            border: Border.all(color: accent ? _T.accent.withOpacity(0.4) : Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: iconSize, color: accent ? _T.accent : _T.grey60),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(
                color: accent ? _T.accent : _T.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: _T.font,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PILL BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _PillButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final VoidCallback onTap;
  final bool     filled;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        decoration: BoxDecoration(
          color: filled ? _T.accent : Colors.white.withOpacity(0.10),
          borderRadius: const BorderRadius.all(_T.r8),
          border: filled ? null : Border.all(color: Colors.white.withOpacity(0.3)),
          boxShadow: filled
              ? [BoxShadow(color: _T.accent.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 6))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _T.white, size: 20),
            const SizedBox(width: 8),
            Text(label,
              style: const TextStyle(
                color: _T.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: _T.font,
                letterSpacing: 0.3,
              )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _SectionHeader({required this.label, this.trailing, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Accent bar
        Container(
          width: 3,
          height: 20,
          decoration: const BoxDecoration(
            color: _T.accent,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
          style: const TextStyle(
            color: _T.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            fontFamily: _T.font,
            letterSpacing: -0.2,
          )),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOVIE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _MovieCard extends StatefulWidget {
  final String       imageUrl;
  final String       title;
  final String       rating;
  final VoidCallback onTap;

  const _MovieCard({
    required this.imageUrl,
    required this.title,
    required this.rating,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  State<_MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<_MovieCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => _ctrl.forward(),
      onTapUp:    (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() => Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(_T.r12),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 8)),
      ],
    ),
    child: ClipRRect(
      borderRadius: const BorderRadius.all(_T.r12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Poster
          Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: _T.card,
              child: const Icon(Icons.movie_outlined, color: _T.grey30, size: 38),
            ),
          ),

          // Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
          ),

          // Rating badge
          Positioned(
            top: 7, right: 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.all(_T.r4),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: const BorderRadius.all(_T.r4),
                    border: Border.all(color: _T.accent.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 10, color: _T.gold),
                      const SizedBox(width: 3),
                      Text(widget.rating,
                        style: const TextStyle(color: _T.white, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: _T.font)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Play overlay (subtle)
          Center(
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
            ),
          ),

          // Title at bottom
          Positioned(
            left: 8, right: 8, bottom: 8,
            child: Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _T.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: _T.font,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ICON BUTTON (AppBar)
// ─────────────────────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: _T.white, size: 24),
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTE HELPER
// ─────────────────────────────────────────────────────────────────────────────
PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) =>
      FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 300),
);
