import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkController extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool isConnected = true;
  bool wasDisconnected = false;
  VoidCallback? onConnectionRestored;

  NetworkController() {
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Network check error: $e');
    }
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    final hasConnection = result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet;

    if (!isConnected && hasConnection && wasDisconnected) {
      // Connection restored
      wasDisconnected = false;
      if (onConnectionRestored != null) {
        onConnectionRestored!();
      }
    } else if (isConnected && !hasConnection) {
      // Connection lost
      wasDisconnected = true;
    }

    isConnected = hasConnection;
    notifyListeners();
  }

  void setOnConnectionRestored(VoidCallback callback) {
    onConnectionRestored = callback;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
