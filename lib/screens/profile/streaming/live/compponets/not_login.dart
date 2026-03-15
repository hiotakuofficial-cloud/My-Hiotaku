import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../auth/login.dart';

const _bg = Color(0xFF1A1A1A);
const _red = Color(0xFFDC143C);
const _white = Colors.white;
const _grey = Color(0xFFCCCCCC);
const _font = 'MazzardH';

class LiveNotLoggedIn {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _Sheet(),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.35;

    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: _grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(CupertinoIcons.person_crop_circle_badge_exclam, color: _red, size: 48),
            const SizedBox(height: 16),
            const Text(
              "You're Not Logged In",
              textAlign: TextAlign.center,
              style: TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: _font),
            ),
            const SizedBox(height: 10),
            const Text(
              "Login to join live rooms, stream together, and access your watch history.",
              textAlign: TextAlign.center,
              style: TextStyle(color: _grey, fontSize: 14, fontFamily: _font),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _grey,
                      side: BorderSide(color: _grey.withOpacity(0.3)),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _font),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: _white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: _font),
                    ),
                    child: const Text('Login'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
