import 'dart:convert';

/// Extensible presentation metadata. Ownership stays in RTDB Rules; clients
/// interpret only fields they understand. Never use this for rewards/authority.
class VisualState {
  static const maxLength = 8192;

  static String encode(Map<String, Object?> values) {
    final text = jsonEncode(values);
    if (text.length > maxLength) {
      throw ArgumentError('Visual state exceeds $maxLength characters');
    }
    return text;
  }

  static Map<String, dynamic>? decode(Object? value) {
    if (value is! String || value.length > maxLength) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
