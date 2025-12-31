import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

class SyncAccountsPage extends StatefulWidget {
  @override
  _SyncAccountsPageState createState() => _SyncAccountsPageState();
}

class _SyncAccountsPageState extends State<SyncAccountsPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _elasticController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _elasticAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _elasticController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _elasticAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _elasticController, curve: Curves.elasticOut));
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
    
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(Duration(milliseconds: 100));
    _fadeController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _elasticController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _elasticController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSyncCard(),
                        SizedBox(height: 20),
                        _buildConnectedAccounts(),
                        SizedBox(height: 20),
                        _buildSyncOptions(),
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

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Accounts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Connect and sync your accounts',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncCard() {
    return ScaleTransition(
      scale: _elasticAnimation,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF8C00).withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.sync, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(
              'Sync Your Data',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Keep your favorites and watch history synced across all devices',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedAccounts() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connected Accounts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildAccountItem(
            icon: Icons.g_mobiledata, // Using available Google-like icon
            title: 'Google Account',
            subtitle: 'user@gmail.com',
            isConnected: true,
          ),
          SizedBox(height: 12),
          _buildAccountItem(
            icon: Icons.facebook,
            title: 'Facebook',
            subtitle: 'Not connected',
            isConnected: false,
          ),
          SizedBox(height: 12),
          _buildAccountItem(
            icon: Icons.apple,
            title: 'Apple ID',
            subtitle: 'Not connected',
            isConnected: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isConnected,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: isConnected 
            ? Border.all(color: Color(0xFFFF8C00).withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected 
                  ? Color(0xFFFF8C00).withOpacity(0.2)
                  : Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isConnected ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.5),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isConnected 
                        ? Color(0xFFFF8C00)
                        : Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isConnected,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              // Handle sync toggle
            },
            activeColor: Color(0xFFFF8C00),
            inactiveThumbColor: Colors.white.withOpacity(0.3),
            inactiveTrackColor: Color(0xFF2A2A2A),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncOptions() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Options',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildSyncOption(
            icon: Icons.favorite,
            title: 'Favorites',
            subtitle: 'Sync your favorite anime',
            isEnabled: true,
          ),
          SizedBox(height: 12),
          _buildSyncOption(
            icon: Icons.history,
            title: 'Watch History',
            subtitle: 'Keep track of watched episodes',
            isEnabled: true,
          ),
          SizedBox(height: 12),
          _buildSyncOption(
            icon: Icons.bookmark,
            title: 'Bookmarks',
            subtitle: 'Sync your bookmarked content',
            isEnabled: false,
          ),
          SizedBox(height: 24),
          _buildSyncButton(),
        ],
      ),
    );
  }

  Widget _buildSyncOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFF8C00), size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              // Handle option toggle
            },
            activeColor: Color(0xFFFF8C00),
            inactiveThumbColor: Colors.white.withOpacity(0.3),
            inactiveTrackColor: Color(0xFF2A2A2A),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return ScaleTransition(
      scale: _elasticAnimation,
      child: Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            // Handle sync action
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF8C00),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sync, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Sync Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
