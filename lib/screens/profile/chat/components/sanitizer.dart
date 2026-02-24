/// Fast response sanitizer for Hisu AI - preserves formatting
class ResponseSanitizer {
  static const int _maxLength = 50000;

  /// Sanitize AI response
  static String sanitize(String response) {
    if (response.isEmpty) return response;

    // Length guard
    String text = response.length > _maxLength 
        ? response.substring(0, _maxLength) 
        : response;

    if (text.trim().isEmpty) return '';

    // Step 1: Fix escaped characters
    text = text
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', ' ');

    // Step 2: Remove HTML
    text = text
        .replaceAll(RegExp(r'<\/?[a-z][^>]*>', caseSensitive: false), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Step 3: Remove code blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), '');

    // Step 4: Remove markdown (using callbacks to prevent $1 issues)
    text = text.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'__([^_]+)__'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'(?<!_)_([^_\n]+)_(?!_)'), (m) => m.group(1)!);
    text = text.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1)!);

    // Step 5: Remove $1 $2 placeholders
    text = text.replaceAll(RegExp(r'\$\d+'), ' ');

    // Step 6: Clean each line (preserves line breaks for lists)
    text = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');

    // Step 7: Clean whitespace
    text = text
        .replaceAll(RegExp(r'  +'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Step 8: Remove control characters
    text = text.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');

    return text.trim();
  }
}
