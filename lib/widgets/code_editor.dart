import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'code_keyboard_bar.dart';

/// ─── CodeEditor ──────────────────────────────────────────────────────────────
/// Dark glass-theme editor with:
///   • One Dark Pro syntax highlighting
///   • Correct line numbers (expands: true inside LayoutBuilder)
///   • No horizontal overflow (wrap: false + Clip.hardEdge)
///   • Smart CodeKeyboardBar above keyboard (snippets + symbols + Tab)
class CodeEditor extends StatefulWidget {
  final String code;
  final ValueChanged<String> onChanged;
  final String language;

  const CodeEditor({
    super.key,
    required this.code,
    required this.onChanged,
    this.language = 'dart',
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late CodeController _ctrl;
  final FocusNode _focusNode = FocusNode();
  bool _keyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _ctrl = _buildController(widget.code, widget.language);
    _ctrl.addListener(() => widget.onChanged(_ctrl.text));

    _focusNode.addListener(() {
      if (mounted) setState(() => _keyboardVisible = _focusNode.hasFocus);
    });
  }

  CodeController _buildController(String text, String lang) {
    final mode = switch (lang) {
      'css'        => css,
      'javascript' => javascript,
      'js'         => javascript,
      'python'     => python,
      'py'         => python,
      'html'       => xml,
      'text'       => null,
      'none'       => null,
      _            => dart,
    };
    return CodeController(text: text, language: mode);
  }

  @override
  void didUpdateWidget(covariant CodeEditor old) {
    super.didUpdateWidget(old);
    if (old.language != widget.language) {
      _ctrl.dispose();
      _ctrl = _buildController(widget.code, widget.language);
      _ctrl.addListener(() => widget.onChanged(_ctrl.text));
    } else if (widget.code != _ctrl.text) {
      _ctrl.text = widget.code;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF09090B),
        canvasColor: const Color(0xFF09090B),
        colorScheme: const ColorScheme.dark(
          surface:    Color(0xFF09090B),
          background: Color(0xFF09090B),
          primary:    Color(0xFF09090B),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          fillColor: Color(0xFF09090B),
          filled: true,
        ),
      ),
      child: Column(
        children: [
          // ── Code field — fills all available space ─────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF09090B),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width:  constraints.maxWidth,
                    height: constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : 400,
                    child: CodeTheme(
                      data: const CodeThemeData(
                        styles: {
                          'root':         TextStyle(backgroundColor: Color(0xFF09090B), color: Color(0xFFABB2BF)),
                          'comment':      TextStyle(color: Color(0xFF5C6370), fontStyle: FontStyle.italic),
                          'quote':        TextStyle(color: Color(0xFF5C6370), fontStyle: FontStyle.italic),
                          'doctag':       TextStyle(color: Color(0xFF5C6370), fontStyle: FontStyle.italic),
                          'keyword':      TextStyle(color: Color(0xFFC678DD), fontWeight: FontWeight.w600),
                          'selector-tag': TextStyle(color: Color(0xFFC678DD)),
                          'literal':      TextStyle(color: Color(0xFFC678DD)),
                          'title':        TextStyle(color: Color(0xFF61AFEF)),
                          'string':       TextStyle(color: Color(0xFF98C379)),
                          'regexp':       TextStyle(color: Color(0xFF98C379)),
                          'addition':     TextStyle(color: Color(0xFF98C379)),
                          'attribute':    TextStyle(color: Color(0xFF98C379)),
                          'number':       TextStyle(color: Color(0xFFD19A66)),
                          'meta':         TextStyle(color: Color(0xFFD19A66)),
                          'type':         TextStyle(color: Color(0xFF61AFEF)),
                          'class':        TextStyle(color: Color(0xFFE5C07B)),
                          'function':     TextStyle(color: Color(0xFF61AFEF)),
                          'tag':          TextStyle(color: Color(0xFFE06C75)),
                          'name':         TextStyle(color: Color(0xFFE06C75)),
                          'attr':         TextStyle(color: Color(0xFFD19A66)),
                          'built_in':     TextStyle(color: Color(0xFFE5C07B)),
                          'params':       TextStyle(color: Color(0xFFABB2BF)),
                          'variable':     TextStyle(color: Color(0xFFE06C75)),
                          'operator':     TextStyle(color: Color(0xFF56B6C2)),
                          'symbol':       TextStyle(color: Color(0xFF56B6C2)),
                          'subst':        TextStyle(color: Color(0xFFABB2BF)),
                          'deletion':     TextStyle(color: Color(0xFFE06C75)),
                        },
                      ),
                      child: CodeField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        expands: true,
                        wrap: false,
                        background: const Color(0xFF09090B),
                        lineNumberStyle: LineNumberStyle(
                          width: 44,
                          textAlign: TextAlign.right,
                          textStyle: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF404050),
                            fontSize: 12,
                            height: 1.55,
                          ),
                          background: const Color(0xFF0C0C0E),
                        ),
                        textStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          height: 1.55,
                          color: const Color(0xFFABB2BF),
                        ),
                        cursorColor: Colors.white,
                        decoration: const BoxDecoration(color: Color(0xFF09090B)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Smart keyboard bar (only when keyboard is open) ────────────────
          if (_keyboardVisible)
            CodeKeyboardBar(
              controller: _ctrl,
              language: widget.language,
              focusNode: _focusNode,
            ),
        ],
      ),
    );
  }
}
