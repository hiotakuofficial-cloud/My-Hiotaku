import 'package:flutter/material.dart';

class CommentSection extends StatefulWidget {
  final VoidCallback? onViewAll;
  final Function(String)? onCommentSubmit;

  const CommentSection({
    Key? key,
    this.onViewAll,
    this.onCommentSubmit,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Comments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'MazzardH',
                ),
              ),
              TextButton(
                onPressed: widget.onViewAll,
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: Color(0xFFE5003C),
                    fontFamily: 'MazzardH',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'MazzardH',
            ),
            decoration: InputDecoration(
              hintText: 'Add a comment...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.comment, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFF1a1a1a),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 20,
              ),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                widget.onCommentSubmit?.call(value);
                _commentController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
