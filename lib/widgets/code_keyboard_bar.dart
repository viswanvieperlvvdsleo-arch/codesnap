import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../utils/code_snippets.dart';

/// ─── CodeKeyboardBar ──────────────────────────────────────────────────────────
/// A smart toolbar that sits between the code editor and the mobile keyboard.
/// Features:
///   • Symbol quick-insert row  ( { } ( ) [ ] ; : = < > / \ " ' )
///   • Live snippet suggestions  based on what the user is typing
///   • Tab key (2-space indent)
///   • Undo shortcut
class CodeKeyboardBar extends StatefulWidget {
  final TextEditingController controller;
  final String language;
  final FocusNode focusNode;

  const CodeKeyboardBar({
    super.key,
    required this.controller,
    required this.language,
    required this.focusNode,
  });

  @override
  State<CodeKeyboardBar> createState() => _CodeKeyboardBarState();
}

class _CodeKeyboardBarState extends State<CodeKeyboardBar> {
  List<CodeSnippet> _suggestions = [];
  String _lastWord = '';

  static const _symbols = [
    ('Tab', null),
    ('{',  '}'),
    ('(',  ')'),
    ('[',  ']'),
    ('"',  '"'),
    ("'",  "'"),
    ('<',  '>'),
    (';',  null),
    (':',  null),
    ('=',  null),
    ('!',  null),
    ('/',  null),
    ('\\', null),
    ('.',  null),
    (',',  null),
    ('_',  null),
    ('#',  null),
    ('%',  null),
    ('&',  null),
    ('|',  null),
    ('?',  null),
    ('+',  null),
    ('-',  null),
    ('*',  null),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CodeKeyboardBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text   = widget.controller.text;
    final cursor = widget.controller.selection.baseOffset;
    if (cursor < 0 || cursor > text.length) return;

    // Extract the current word being typed (before cursor)
    final before = text.substring(0, cursor);
    final wordMatch = RegExp(r'(\w+)$').firstMatch(before);
    final word = wordMatch?.group(1) ?? '';

    if (word == _lastWord) return;
    _lastWord = word;

    setState(() {
      _suggestions = CodeSnippets.search(word, widget.language);
    });
  }

  // ── Insert a symbol at cursor, optionally wrapping selected text ───────────
  void _insertSymbol(String open, String? close) {
    final ctrl      = widget.controller;
    final text      = ctrl.text;
    final selection = ctrl.selection;

    if (!selection.isValid) {
      // Just insert at cursor
      final cursor = selection.baseOffset < 0 ? text.length : selection.baseOffset;
      final newText = text.substring(0, cursor) +
          open +
          (close ?? '') +
          text.substring(cursor);
      final newCursor = cursor + open.length;
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newCursor),
      );
      return;
    }

    final start = selection.start;
    final end   = selection.end;

    if (close != null && start != end) {
      // Wrap selected text between open and close
      final selected = text.substring(start, end);
      final newText   = text.substring(0, start) +
          open + selected + close +
          text.substring(end);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset:  start + open.length,
          extentOffset: end + open.length,
        ),
      );
    } else {
      // Insert at cursor with auto-close
      final cursor  = start;
      final newText = text.substring(0, cursor) +
          open +
          (close ?? '') +
          text.substring(cursor);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + open.length),
      );
    }
  }

  // ── Insert 2-space Tab ─────────────────────────────────────────────────────
  void _insertTab() {
    _insertSymbol('  ', null);
  }

  // ── Expand a snippet at cursor ─────────────────────────────────────────────
  void _expandSnippet(CodeSnippet snippet) {
    final ctrl   = widget.controller;
    final text   = ctrl.text;
    final cursor = ctrl.selection.baseOffset < 0
        ? text.length
        : ctrl.selection.baseOffset;

    // Remove the trigger word before cursor
    final before    = text.substring(0, cursor);
    final wordMatch = RegExp(r'(\w+)$').firstMatch(before);
    final triggerLen = wordMatch?.group(1)?.length ?? 0;
    final insertAt  = cursor - triggerLen;

    // Remove cursor marker from body
    final body     = snippet.body.replaceAll(CodeSnippets.cursor, '');
    final cursorOff = snippet.body.indexOf(CodeSnippets.cursor);
    final finalCursor = insertAt + (cursorOff >= 0 ? cursorOff : body.length);

    final newText = text.substring(0, insertAt) +
        body +
        text.substring(cursor);

    ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: finalCursor),
    );

    // Clear suggestions after expansion
    setState(() {
      _suggestions = [];
      _lastWord = '';
    });

    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
        border: Border(
          top: BorderSide(color: Color(0x26FFFFFF)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Suggestions Row ────────────────────────────────────────────────
          if (_suggestions.isNotEmpty)
            _buildSuggestionsRow(),

          // ── Symbols Row ───────────────────────────────────────────────────
          _buildSymbolsRow(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsRow() {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0C),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => const VerticalDivider(
          width: 1,
          thickness: 1,
          color: Color(0x1AFFFFFF),
          indent: 6,
          endIndent: 6,
        ),
        itemBuilder: (_, i) {
          final s = _suggestions[i];
          return GestureDetector(
            onTap: () => _expandSnippet(s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.zap,
                    size: 10,
                    color: Color(0xFFC678DD),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    s.label,
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFFCCCCDD),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSymbolsRow() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _symbols.length,
        itemBuilder: (_, i) {
          final (sym, close) = _symbols[i];
          final isTab = sym == 'Tab';

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (isTab) {
                _insertTab();
              } else {
                _insertSymbol(sym, close);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: isTab
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.cornerDownRight,
                          size: 12,
                          color: Color(0xFF8888C9),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Tab',
                          style: GoogleFonts.jetBrainsMono(
                            color: const Color(0xFF8888C9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      sym,
                      style: GoogleFonts.jetBrainsMono(
                        color: close != null
                            ? const Color(0xFF98C379) // paired → green
                            : const Color(0xFFCCCCDD),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
