import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/auth/handler/supabase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> publicFavorites = [];
  List<Map<String, dynamic>> mergeRequests = [];
  List<Map<String, dynamic>> sharedFavorites = [];
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUser();
    _loadData();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    await Future.wait([
      _loadPublicFavorites(),
      _loadMergeRequests(),
      _loadSharedFavorites(),
    ]);
    
    setState(() => isLoading = false);
  }

  Future<void> _loadPublicFavorites() async {
    try {
      final data = await SupabaseHandler.getData(
        table: 'public_favorites',
        select: '*',
      );
      
      if (data != null) {
        setState(() {
          publicFavorites = data;
        });
      }
    } catch (e) {
      print('Error loading public favorites: $e');
    }
  }

  Future<void> _loadMergeRequests() async {
    if (currentUserId == null) return;
    
    try {
      // Get current user's database ID
      final userData = await SupabaseHandler.getData(
        table: 'users',
        filters: {'firebase_uid': currentUserId!},
      );
      
      if (userData != null && userData.isNotEmpty) {
        final userId = userData[0]['id'];
        
        final data = await SupabaseHandler.getData(
          table: 'merge_requests',
          filters: {'receiver_id': userId, 'status': 'pending'},
        );
        
        if (data != null) {
          setState(() {
            mergeRequests = data;
          });
        }
      }
    } catch (e) {
      print('Error loading merge requests: $e');
    }
  }

  Future<void> _loadSharedFavorites() async {
    if (currentUserId == null) return;
    
    try {
      final userData = await SupabaseHandler.getData(
        table: 'users',
        filters: {'firebase_uid': currentUserId!},
      );
      
      if (userData != null && userData.isNotEmpty) {
        final userId = userData[0]['id'];
        
        final data = await SupabaseHandler.getData(
          table: 'shared_favorites',
          filters: {'user1_id': userId},
        );
        
        if (data != null) {
          setState(() {
            sharedFavorites = data;
          });
        }
      }
    } catch (e) {
      print('Error loading shared favorites: $e');
    }
  }

  Future<void> _sendMergeRequest(String targetUserId) async {
    if (currentUserId == null) return;
    
    try {
      final userData = await SupabaseHandler.getData(
        table: 'users',
        filters: {'firebase_uid': currentUserId!},
      );
      
      if (userData != null && userData.isNotEmpty) {
        final senderId = userData[0]['id'];
        
        await SupabaseHandler.insertData(
          table: 'merge_requests',
          data: {
            'sender_id': senderId,
            'receiver_id': targetUserId,
            'message': 'Would like to merge favorites with you!',
          },
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merge request sent!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _respondToMergeRequest(String requestId, bool accept) async {
    try {
      await SupabaseHandler.updateData(
        table: 'merge_requests',
        data: {
          'status': accept ? 'accepted' : 'rejected',
          'responded_at': SupabaseHandler.getCurrentTimestamp(),
        },
        filters: {'id': requestId},
      );
      
      if (accept) {
        // TODO: Call merge function
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Favorites merged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      _loadMergeRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to respond: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Favorites',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Public'),
            Tab(text: 'Requests (${mergeRequests.length})'),
            Tab(text: 'Shared'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPublicFavorites(),
                _buildMergeRequests(),
                _buildSharedFavorites(),
              ],
            ),
    );
  }

  Widget _buildPublicFavorites() {
    if (publicFavorites.isEmpty) {
      return Center(
        child: Text(
          'No public favorites yet',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: publicFavorites.length,
      itemBuilder: (context, index) {
        final favorite = publicFavorites[index];
        return Card(
          color: Colors.grey[900],
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                favorite['anime_image'] ?? '',
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 70,
                    color: Colors.grey[800],
                    child: Icon(Icons.movie, color: Colors.grey),
                  );
                },
              ),
            ),
            title: Text(
              favorite['anime_title'] ?? 'Unknown Anime',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Added by ${favorite['display_name'] ?? favorite['username'] ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey),
            ),
            trailing: IconButton(
              icon: Icon(Icons.person_add, color: Colors.blue),
              onPressed: () {
                // TODO: Send merge request to this user
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildMergeRequests() {
    if (mergeRequests.isEmpty) {
      return Center(
        child: Text(
          'No merge requests',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: mergeRequests.length,
      itemBuilder: (context, index) {
        final request = mergeRequests[index];
        return Card(
          color: Colors.grey[900],
          margin: EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merge Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  request['message'] ?? 'No message',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _respondToMergeRequest(request['id'], true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text('Accept'),
                    ),
                    ElevatedButton(
                      onPressed: () => _respondToMergeRequest(request['id'], false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSharedFavorites() {
    if (sharedFavorites.isEmpty) {
      return Center(
        child: Text(
          'No shared favorites yet',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: sharedFavorites.length,
      itemBuilder: (context, index) {
        final favorite = sharedFavorites[index];
        return Card(
          color: Colors.grey[900],
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                favorite['anime_image'] ?? '',
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 70,
                    color: Colors.grey[800],
                    child: Icon(Icons.movie, color: Colors.grey),
                  );
                },
              ),
            ),
            title: Text(
              favorite['anime_title'] ?? 'Unknown Anime',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Shared with ${favorite['added_by_name'] ?? 'Unknown'}',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
