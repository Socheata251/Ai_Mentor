import 'package:flutter/painting.dart';

/// Small regex-based highlighter (JS / Dart / Python / Java / C++ / SQL look
/// good enough). Cheap enough to run once per snippet. The Code Playground
/// can reuse it later (or swap in a real tokenizer running in an isolate).
abstract final class SyntaxHighlighter {
  static const Color text = Color(0xFFE2E8F0);
  static const Color keyword = Color(0xFFF472B6);
  static const Color string = Color(0xFF86EFAC);
  static const Color comment = Color(0xFF64748B);
  static const Color number = Color(0xFFFBBF77);
  static const Color function = Color(0xFF7DD3FC);

  static const _keywords =
      'async|await|function|const|let|var|return|try|catch|finally|if|else|'
      'throw|new|class|import|export|from|for|while|in|of|def|lambda|int|'
      'void|final|static|public|private|extends|implements|true|false|null|'
      'undefined|this|super|switch|case|break|continue|default|typeof|yield|'
      'String|bool|double|late|required|with|struct|enum|SELECT|FROM|WHERE|'
      'INSERT|UPDATE|DELETE|JOIN|ORDER|BY|GROUP|AND|OR|NOT';

  // groups: 1 comment, 2 string, 3 number, 4 keyword, 5 function call
  static final RegExp _token = RegExp(
    r'(//.*|#.*)'
    r'''|('(?:\\.|[^'\\\n])*'|"(?:\\.|[^"\\\n])*"|`(?:\\.|[^`\\])*`)'''
    r'|(\b\d+(?:\.\d+)?\b)'
    '(\\b(?:$_keywords)\\b)'
    r'|(\b[A-Za-z_]\w*(?=\s*\())',
  );

  static List<TextSpan> highlight(String code, {required TextStyle base}) {
    final plain = base.copyWith(color: text);
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _token.allMatches(code)) {
      if (m.start > last) {
        spans.add(TextSpan(text: code.substring(last, m.start), style: plain));
      }
      final Color color;
      if (m.group(1) != null) {
        color = comment;
      } else if (m.group(2) != null) {
        color = string;
      } else if (m.group(3) != null) {
        color = number;
      } else if (m.group(4) != null) {
        color = keyword;
      } else {
        color = function;
      }
      spans.add(
        TextSpan(
          text: m.group(0),
          style: base.copyWith(color: color),
        ),
      );
      last = m.end;
    }
    if (last < code.length) {
      spans.add(TextSpan(text: code.substring(last), style: plain));
    }
    return spans;
  }
}
