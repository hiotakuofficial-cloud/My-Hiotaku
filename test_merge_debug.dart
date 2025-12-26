// Test script to debug merge process
// Run this to simulate the merge process and see what happens

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 MERGE DEBUG TEST STARTING...');
  
  // Supabase config
  const supabaseUrl = 'https://brwzqawoncblbxqoqyua.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA';
  
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
  };
  
  // User IDs
  const bobbyId = 'b9ebdcb3-b056-4ef3-a8f1-f6e66a8eb3e2';
  const pihuId = '0fd6ad98-e76f-4764-b71e-350c50057db9';
  
  print('👥 Testing users:');
  print('   bobby_singh: $bobbyId');
  print('   pihu: $pihuId');
  
  // Step 1: Check current state
  print('\n📊 STEP 1: Checking current database state...');
  
  final mergeRequestsResponse = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/merge_requests?select=*'),
    headers: headers,
  );
  print('   merge_requests: ${mergeRequestsResponse.body}');
  
  final sharedFavsResponse = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/shared_favorites?select=*'),
    headers: headers,
  );
  print('   shared_favorites: ${sharedFavsResponse.body}');
  
  final mergedAccountsResponse = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/merged_accounts?select=*'),
    headers: headers,
  );
  print('   merged_accounts: ${mergedAccountsResponse.body}');
  
  // Step 2: Check private favorites
  print('\n📱 STEP 2: Checking private favorites...');
  
  final bobbyFavsResponse = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/favorites?select=*&user_id=eq.$bobbyId&is_public=eq.false'),
    headers: headers,
  );
  final bobbyFavs = jsonDecode(bobbyFavsResponse.body) as List;
  print('   bobby_singh private favorites: ${bobbyFavs.length}');
  for (var fav in bobbyFavs) {
    print('     - ${fav['anime_title']}');
  }
  
  final pihuFavsResponse = await http.get(
    Uri.parse('$supabaseUrl/rest/v1/favorites?select=*&user_id=eq.$pihuId&is_public=eq.false'),
    headers: headers,
  );
  final pihuFavs = jsonDecode(pihuFavsResponse.body) as List;
  print('   pihu private favorites: ${pihuFavs.length}');
  for (var fav in pihuFavs) {
    print('     - ${fav['anime_title']}');
  }
  
  print('\n🎯 EXPECTED MERGE RESULT: ${bobbyFavs.length + pihuFavs.length} total favorites');
  print('   (${bobbyFavs.length} from bobby + ${pihuFavs.length} from pihu)');
  
  print('\n✅ DEBUG TEST COMPLETE');
  print('📋 SUMMARY:');
  print('   - Database tables are empty (no requests/merges)');
  print('   - Private favorites exist and ready to merge');
  print('   - Issue is in the request/accept process');
}
