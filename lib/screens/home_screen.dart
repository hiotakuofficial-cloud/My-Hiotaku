import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../widgets/anime_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  List<AnimeItem> animeList = [];
  bool isLoading = true;
  String error = '';

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    _loadAnime();
  }

  Future<void> _loadAnime() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final result = await ApiService.getHome();
      if (mounted) {
        setState(() {
          animeList = result.data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _loadAnime();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0a0e27), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Text(
            'Trending Anime',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          IconButton(
            onPressed: _onRefresh,
            icon: Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return LoadingWidget();
    }
    
    if (error.isNotEmpty) {
      return CustomErrorWidget(
        error: error,
        onRetry: _loadAnime,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.blue,
      backgroundColor: Color(0xFF16213e),
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: animeList.length,
        itemBuilder: (context, index) {
          return AnimeCard(
            anime: animeList[index],
            index: index,
          );
        },
      ),
    );
  }
}
