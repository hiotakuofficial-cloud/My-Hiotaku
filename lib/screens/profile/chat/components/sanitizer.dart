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
    // Remove code blocks first
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    
    // Remove markdown using callbacks (prevents $1 literal issues)
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'(?<!_)_([^_\n]+)_(?!_)'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);
    
    // Links: keep URL info
    text = text.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^\)]+)\)'), (m) => '${m.group(1)} (${m.group(2)})');
    
    // Fix line breaks using callback
    text = text.replaceAllMapped(RegExp(r'(\S)\s*\n+\s*(\S)'), (m) => '${m.group(1)} ${m.group(2)}');
    
    // Clean whitespace
    return text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r'^[ \t]+|[ \t]+$', multiLine: true), '');
  }

  /// Step 4: Verify and finalize
  static String _verifyAndFinalize(String text) {
    // Remove control characters
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    
    // Remove regex placeholders with optional spaces (AI bug)
    text = text.replaceAll(RegExp(r'\$\d+\s*'), '');
    
    // Proper sentence spacing using callback
    text = text.replaceAllMapped(RegExp(r'([.!?])\s*([A-Z])'), (m) => '${m.group(1)} ${m.group(2)}');
    text = text.replaceAllMapped(RegExp(r'([.!?])\s{2,}'), (m) => '${m.group(1)} ');
    
    // Remove empty lines
    return text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .join('\n');
  }
}
