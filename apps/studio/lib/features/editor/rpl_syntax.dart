/// RPL Syntax Highlighter.
/// Returns a list of `TextSpan` for RichText rendering.
library;

import 'package:flutter/material.dart';

// RPL Keywords
const _keywords = {
  'buat',
  'fungsi',
  'kembalikan',
  'jika',
  'maka',
  'selesai',
  'selama',
  'tampilkan',
  'cetak',
  'coba',
  'tangkap',
  'lempar',
  'impor',
  'gabung',
  'pakai',
  'ini',
  'adalah',
  'bukan',
  'dan',
  'atau',
  'jika tidak',
};

const _constants = {'benar', 'salah', 'kosong'};

const _builtins = {
  'panjang',
  'string',
  'angka',
  'waktu',
  'kripto',
  'json',
  'list',
  'db',
  'web',
  'matematika',
};

class RplSyntaxHighlighter {
  /// Highlight RPL source code and return a list of TextSpan.
  /// Colors are resolved from the current theme via [context].
  static List<TextSpan> highlight(String source, BuildContext context) {
    final theme = Theme.of(context);
    final spans = <TextSpan>[];

    final keywordColor = Color.lerp(
      theme.colorScheme.primary,
      Colors.purple,
      0.5,
    )!;
    final stringColor = const Color(0xFF059669); // green-600
    final commentColor = Colors.grey;
    final numberColor = const Color(0xFFD97706); // amber-600
    final constantColor = const Color(0xFF7C3AED); // violet-600
    final builtinColor = theme.colorScheme.secondary;
    final defaultColor = theme.colorScheme.onSurface;

    int i = 0;
    final chars = source.characters.toList();
    final len = chars.length;

    while (i < len) {
      // --- Single-line comment ---
      if (i + 1 < len && chars[i] == '/' && chars[i + 1] == '/') {
        final start = i;
        while (i < len && chars[i] != '\n') {
          i++;
        }
        spans.add(
          TextSpan(
            text: source.substring(start, i),
            style: TextStyle(color: commentColor, fontStyle: FontStyle.italic),
          ),
        );
        continue;
      }

      // --- String (double-quoted) ---
      if (chars[i] == '"') {
        final start = i;
        i++; // skip opening quote
        while (i < len && chars[i] != '"') {
          if (chars[i] == '\\') i++; // skip escape
          i++;
        }
        if (i < len) i++; // skip closing quote
        spans.add(
          TextSpan(
            text: source.substring(start, i),
            style: TextStyle(color: stringColor),
          ),
        );
        continue;
      }

      // --- Template string (backtick) ---
      if (chars[i] == '`') {
        final start = i;
        i++; // skip opening backtick
        while (i < len && chars[i] != '`') {
          if (chars[i] == '\\') i++; // skip escape
          if (i + 1 < len && chars[i] == '\$' && chars[i + 1] == '{') {
            // Simple handling: just pass through
          }
          i++;
        }
        if (i < len) i++; // skip closing backtick
        spans.add(
          TextSpan(
            text: source.substring(start, i),
            style: TextStyle(color: stringColor),
          ),
        );
        continue;
      }

      // --- Number ---
      if (_isDigit(chars[i]) ||
          (chars[i] == '.' && i + 1 < len && _isDigit(chars[i + 1]))) {
        final start = i;
        while (i < len && (_isDigit(chars[i]) || chars[i] == '.')) {
          i++;
        }
        spans.add(
          TextSpan(
            text: source.substring(start, i),
            style: TextStyle(color: numberColor),
          ),
        );
        continue;
      }

      // --- Identifier / Keyword / Constant / Builtin ---
      if (_isAlpha(chars[i]) || chars[i] == '_') {
        final start = i;
        while (i < len && (_isAlphaNumeric(chars[i]) || chars[i] == '_')) {
          i++;
        }
        final word = source.substring(start, i);

        Color color;
        if (_keywords.contains(word)) {
          color = keywordColor;
        } else if (_constants.contains(word)) {
          color = constantColor;
        } else if (_builtins.contains(word)) {
          color = builtinColor;
        } else {
          color = defaultColor;
        }

        spans.add(
          TextSpan(
            text: word,
            style: TextStyle(
              color: color,
              fontWeight: _keywords.contains(word)
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        );
        continue;
      }

      // --- Default character ---
      spans.add(
        TextSpan(
          text: chars[i],
          style: TextStyle(color: defaultColor),
        ),
      );
      i++;
    }

    return spans;
  }

  static bool _isDigit(String c) =>
      c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  static bool _isAlpha(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122) || u == 95;
  }

  static bool _isAlphaNumeric(String c) => _isAlpha(c) || _isDigit(c);
}
