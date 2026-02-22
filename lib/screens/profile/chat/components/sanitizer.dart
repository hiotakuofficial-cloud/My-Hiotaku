/// Fast 5-step response sanitizer for Hisu AI
class ResponseSanitizer {
  /// Sanitize AI response in 5 steps
  static String sanitize(String response) {
    if (response.isEmpty) return response;

    // Step 1: Receive response
    String cleaned = response;

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
        .replaceAll(r'\n', '\n') // Convert \\n to actual newline
        .replaceAll(r'\t', ' ') // Convert \\t to space
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove all HTML tags
        .replaceAll(RegExp(r'&nbsp;'), ' ') // Replace &nbsp;
        .replaceAll(RegExp(r'&amp;'), '&') // Replace &amp;
        .replaceAll(RegExp(r'&lt;'), '<') // Replace &lt;
        .replaceAll(RegExp(r'&gt;'), '>') // Replace &gt;
        .replaceAll(RegExp(r'&quot;'), '"') // Replace &quot;
        .replaceAll(RegExp(r'&#39;'), "'"); // Replace &#39;
  }

  /// Step 3: Deep clean response
  static String _deepClean(String text) {
    return text
        // Remove markdown bold/italic
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // **bold**
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // *italic*
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1') // __bold__
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1') // _italic_
        
        // Remove markdown links
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1') // [text](url)
        
        // Remove markdown code blocks
        .replaceAll(RegExp(r'```[^`]*```'), '') // ```code```
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // `code`
        
        // Fix line breaks - aggressive joining
        .replaceAll(RegExp(r'([a-zA-Z,!?])\s*\n\s*([a-zA-Z])'), r'$1 $2') // Join broken sentences
        .replaceAll(RegExp(r'\n\s+'), '\n') // Remove leading spaces after newline
        .replaceAll(RegExp(r'\s+\n'), '\n') // Remove trailing spaces before newline
        
        // Clean excessive whitespace
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Multiple spaces/tabs to single space
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // Max 2 consecutive newlines
        
        // Remove leading/trailing whitespace per line
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .join('\n');
  }

  /// Step 4: Verify and finalize
  static String _verifyAndFinalize(String text) {
    // Remove any remaining special characters that shouldn't be there
    String verified = text
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '') // Control chars
        .replaceAll(RegExp(r'\s+$', multiLine: true), ''); // Trailing spaces
    
    // Ensure proper sentence spacing
    verified = verified
        .replaceAll(RegExp(r'([.!?])\s*([A-Z])'), r'$1 $2') // Space after punctuation
        .replaceAll(RegExp(r'([.!?])\s{2,}'), r'$1 '); // Single space after punctuation
    
    return verified;
  }
}
