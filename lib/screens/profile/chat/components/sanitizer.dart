/// Fast 5-step response sanitizer for Hisu AI
class ResponseSanitizer {
  static const int _maxLength = 50000;

  /// Sanitize AI response in 5 steps
  static String sanitize(String response) {
    if (response.isEmpty) return response;

    // Length guard
    String cleaned = response.length > _maxLength 
        ? response.substring(0, _maxLength) 
        : response;

    // Step 1: Receive response (validate)
    if (cleaned.trim().isEmpty) return '';

    // Step 2: Remove HTML tags
    cleaned = _removeHtmlTags(cleaned);

    // Step 3: Clean response thoroughly
    cleaned = _deepClean(cleaned);

    // Step 4: Verify and final cleanup
    cleaned = _verifyAndFinalize(cleaned);

    // Step 5: Return cleaned response
    return cleaned.trim();
  }

  /// Step 2: Remove HTML tags
  static String _removeHtmlTags(String text) {
    return text
        // Fix escaped newlines first
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', ' ')
        // Safe HTML tag removal (only actual tags)
        .replaceAll(RegExp(r'<\/?[a-z][^>]*>', caseSensitive: false), '')
        // HTML entities
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'");
  }

  /// Step 3: Deep clean response
  static String _deepClean(String text) {
    return text
        // Remove code blocks first (multiline safe)
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        
        // Remove markdown bold (must be before italic)
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        
        // Remove markdown italic (safe pattern)
        .replaceAll(RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'), r'$1')
        .replaceAll(RegExp(r'(?<!_)_([^_\n]+)_(?!_)'), r'$1')
        
        // Remove inline code
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        
        // Links: keep URL info
        .replaceAll(RegExp(r'\[([^\]]+)\]\(([^\)]+)\)'), r'$1 ($2)')
        
        // AGGRESSIVE line break fixing (Unicode-safe)
        .replaceAll(RegExp(r'(\S)\s*\n+\s*(\S)'), r'$1 $2')
        
        // Clean whitespace efficiently
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'^[ \t]+|[ \t]+$', multiLine: true), '');
  }

  /// Step 4: Verify and finalize
  static String _verifyAndFinalize(String text) {
    return text
        // Remove control characters
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '')
        // Proper sentence spacing
        .replaceAll(RegExp(r'([.!?])\s*([A-Z])'), r'$1 $2')
        .replaceAll(RegExp(r'([.!?])\s{2,}'), r'$1 ')
        // Remove empty lines
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
}
