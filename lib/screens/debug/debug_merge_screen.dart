import 'package:flutter/material.dart';
import '../handler/requests_handler.dart';

class DebugMergeScreen extends StatefulWidget {
  @override
  _DebugMergeScreenState createState() => _DebugMergeScreenState();
}

class _DebugMergeScreenState extends State<DebugMergeScreen> {
  String _debugOutput = '';

  void _testMerge() async {
    setState(() {
      _debugOutput = 'Testing merge function...\n';
    });

    // Test the merge function directly
    const bobbyId = 'b9ebdcb3-b056-4ef3-a8f1-f6e66a8eb3e2';
    const pihuId = '0fd6ad98-e76f-4764-b71e-350c50057db9';

    try {
      final result = await RequestsHandler.testMergeFavoritesDirectly(bobbyId, pihuId);
      
      setState(() {
        _debugOutput += 'Merge result: ${result.toString()}\n';
        _debugOutput += 'Success: ${result['success']}\n';
        _debugOutput += 'Count: ${result['count']}\n';
        if (result['error'] != null) {
          _debugOutput += 'Error: ${result['error']}\n';
        }
      });
    } catch (e) {
      setState(() {
        _debugOutput += 'Error: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Merge Function'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testMerge,
              child: Text('Test Merge Function'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugOutput,
                    style: TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
