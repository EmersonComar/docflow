class StringUtils {
  /// Extracts variables from a string enclosed in {{curly_braces}}.
  /// matches `{{ variable }}`.
  static Set<String> extractVariables(String content) {
    final regex = RegExp(r'\{\{\s*(.*?)\s*\}\}');
    final matches = regex.allMatches(content);
    return matches.map((m) => m.group(1)!).toSet();
  }

  /// Replaces variables in [content] with values from [variables].
  static String interpolate(String content, Map<String, String> variables) {
    return content.replaceAllMapped(RegExp(r'\{\{\s*(.*?)\s*\}\}'), (match) {
      final variableName = match.group(1)!;
      return variables[variableName] ?? match.group(0)!;
    });
  }
}
