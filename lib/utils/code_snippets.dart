/// ─── CodeSnippets ─────────────────────────────────────────────────────────────
/// Emmet-style expansions + language-aware snippets for HTML, CSS, JS, Python.
/// The [trigger] is what the user types. The [body] is what it expands to.
/// Use [cursor] to mark where the cursor should land after expansion (│).

class CodeSnippet {
  final String trigger;  // what user types
  final String label;    // shown in suggestion bar
  final String body;     // expanded code (│ = cursor position marker)
  final String description;

  const CodeSnippet({
    required this.trigger,
    required this.label,
    required this.body,
    this.description = '',
  });
}

class CodeSnippets {
  CodeSnippets._();

  // ── Cursor position marker ─────────────────────────────────────────────────
  static const cursor = '│';

  // ── HTML Emmet + Snippets ──────────────────────────────────────────────────
  static const List<CodeSnippet> html = [
    CodeSnippet(
      trigger: '!',
      label: '! — HTML5 Boilerplate',
      body: '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>│Document</title>
</head>
<body>
  │
</body>
</html>''',
      description: 'Full HTML5 boilerplate',
    ),
    CodeSnippet(
      trigger: 'div',
      label: 'div',
      body: '<div│></div>',
      description: '<div></div>',
    ),
    CodeSnippet(
      trigger: 'p',
      label: 'p',
      body: '<p>│</p>',
      description: '<p></p>',
    ),
    CodeSnippet(
      trigger: 'a',
      label: 'a',
      body: '<a href="│"></a>',
      description: '<a href="">',
    ),
    CodeSnippet(
      trigger: 'img',
      label: 'img',
      body: '<img src="│" alt="">',
      description: '<img src="">',
    ),
    CodeSnippet(
      trigger: 'ul',
      label: 'ul>li',
      body: '<ul>\n  <li>│</li>\n</ul>',
      description: 'Unordered list',
    ),
    CodeSnippet(
      trigger: 'ol',
      label: 'ol>li',
      body: '<ol>\n  <li>│</li>\n</ol>',
      description: 'Ordered list',
    ),
    CodeSnippet(
      trigger: 'table',
      label: 'table',
      body: '<table>\n  <thead>\n    <tr><th>│Header</th></tr>\n  </thead>\n  <tbody>\n    <tr><td>Data</td></tr>\n  </tbody>\n</table>',
      description: 'HTML table',
    ),
    CodeSnippet(
      trigger: 'form',
      label: 'form',
      body: '<form action="│" method="post">\n  <input type="text" name="" placeholder="">\n  <button type="submit">Submit</button>\n</form>',
      description: 'HTML form',
    ),
    CodeSnippet(
      trigger: 'input',
      label: 'input',
      body: '<input type="│text" name="" placeholder="">',
      description: 'Input field',
    ),
    CodeSnippet(
      trigger: 'button',
      label: 'button',
      body: '<button type="button">│Click Me</button>',
      description: 'Button',
    ),
    CodeSnippet(
      trigger: 'link',
      label: 'link:css',
      body: '<link rel="stylesheet" href="│style.css">',
      description: 'CSS link tag',
    ),
    CodeSnippet(
      trigger: 'script',
      label: 'script',
      body: '<script src="│script.js"></script>',
      description: 'Script tag',
    ),
    CodeSnippet(
      trigger: 'meta',
      label: 'meta',
      body: '<meta name="│" content="">',
      description: 'Meta tag',
    ),
    CodeSnippet(
      trigger: 'span',
      label: 'span',
      body: '<span>│</span>',
      description: 'Inline span',
    ),
    CodeSnippet(
      trigger: 'header',
      label: 'header',
      body: '<header>\n  │\n</header>',
      description: 'Header element',
    ),
    CodeSnippet(
      trigger: 'nav',
      label: 'nav',
      body: '<nav>\n  │\n</nav>',
      description: 'Nav element',
    ),
    CodeSnippet(
      trigger: 'section',
      label: 'section',
      body: '<section>\n  │\n</section>',
      description: 'Section element',
    ),
    CodeSnippet(
      trigger: 'footer',
      label: 'footer',
      body: '<footer>\n  │\n</footer>',
      description: 'Footer element',
    ),
    CodeSnippet(
      trigger: 'h1',
      label: 'h1',
      body: '<h1>│</h1>',
    ),
    CodeSnippet(
      trigger: 'h2',
      label: 'h2',
      body: '<h2>│</h2>',
    ),
    CodeSnippet(
      trigger: 'h3',
      label: 'h3',
      body: '<h3>│</h3>',
    ),
  ];

  // ── CSS Snippets ───────────────────────────────────────────────────────────
  static const List<CodeSnippet> css = [
    CodeSnippet(
      trigger: 'flex',
      label: 'flexbox',
      body: 'display: flex;\njustify-content: │center;\nalign-items: center;',
      description: 'Flexbox layout',
    ),
    CodeSnippet(
      trigger: 'grid',
      label: 'grid',
      body: 'display: grid;\ngrid-template-columns: │repeat(3, 1fr);\ngap: 16px;',
      description: 'CSS Grid layout',
    ),
    CodeSnippet(
      trigger: 'glass',
      label: 'glassmorphism',
      body: 'background: rgba(255, 255, 255, 0.1);\nbackdrop-filter: blur(│10px);\nborder: 1px solid rgba(255, 255, 255, 0.2);\nborder-radius: 16px;',
      description: 'Glassmorphism effect',
    ),
    CodeSnippet(
      trigger: 'center',
      label: 'center (flex)',
      body: 'display: flex;\njustify-content: center;\nalign-items: │center;',
      description: 'Center content',
    ),
    CodeSnippet(
      trigger: 'anim',
      label: '@keyframes',
      body: '@keyframes │animName {\n  from { opacity: 0; }\n  to   { opacity: 1; }\n}',
      description: 'CSS animation',
    ),
    CodeSnippet(
      trigger: 'media',
      label: '@media',
      body: '@media (max-width: │768px) {\n  \n}',
      description: 'Media query',
    ),
    CodeSnippet(
      trigger: 'var',
      label: ':root vars',
      body: ':root {\n  --primary: │#6366f1;\n  --bg: #09090b;\n  --text: #ffffff;\n}',
      description: 'CSS variables',
    ),
    CodeSnippet(
      trigger: 'hover',
      label: ':hover',
      body: ':hover {\n  │\n}',
      description: 'Hover state',
    ),
    CodeSnippet(
      trigger: 'shadow',
      label: 'box-shadow',
      body: 'box-shadow: 0 │10px 30px rgba(0, 0, 0, 0.3);',
      description: 'Box shadow',
    ),
    CodeSnippet(
      trigger: 'gradient',
      label: 'gradient',
      body: 'background: linear-gradient(135deg, │#667eea, #764ba2);',
      description: 'Linear gradient',
    ),
    CodeSnippet(
      trigger: 'transition',
      label: 'transition',
      body: 'transition: all │0.3s ease;',
      description: 'CSS transition',
    ),
    CodeSnippet(
      trigger: 'reset',
      label: 'CSS reset',
      body: '* {\n  margin: 0;\n  padding: 0;\n  box-sizing: │border-box;\n}',
      description: 'CSS reset',
    ),
  ];

  // ── JavaScript Snippets ────────────────────────────────────────────────────
  static const List<CodeSnippet> javascript = [
    CodeSnippet(
      trigger: 'cl',
      label: 'console.log',
      body: 'console.log(│);',
      description: 'console.log()',
    ),
    CodeSnippet(
      trigger: 'fun',
      label: 'function',
      body: 'function │name() {\n  \n}',
      description: 'Named function',
    ),
    CodeSnippet(
      trigger: 'arrow',
      label: 'arrow fn',
      body: 'const │fn = () => {\n  \n};',
      description: 'Arrow function',
    ),
    CodeSnippet(
      trigger: 'for',
      label: 'for loop',
      body: 'for (let │i = 0; i < array.length; i++) {\n  \n}',
      description: 'For loop',
    ),
    CodeSnippet(
      trigger: 'fore',
      label: 'forEach',
      body: '│array.forEach((item) => {\n  \n});',
      description: 'Array forEach',
    ),
    CodeSnippet(
      trigger: 'map',
      label: 'array.map',
      body: 'const result = │array.map((item) => {\n  return item;\n});',
      description: 'Array map',
    ),
    CodeSnippet(
      trigger: 'filter',
      label: 'array.filter',
      body: 'const filtered = │array.filter((item) => {\n  return true;\n});',
      description: 'Array filter',
    ),
    CodeSnippet(
      trigger: 'fetch',
      label: 'fetch API',
      body: 'fetch("│url")\n  .then(res => res.json())\n  .then(data => console.log(data))\n  .catch(err => console.error(err));',
      description: 'Fetch API call',
    ),
    CodeSnippet(
      trigger: 'async',
      label: 'async/await',
      body: 'async function │name() {\n  try {\n    const res = await fetch("url");\n    const data = await res.json();\n  } catch (err) {\n    console.error(err);\n  }\n}',
      description: 'Async function',
    ),
    CodeSnippet(
      trigger: 'qs',
      label: 'querySelector',
      body: 'const │el = document.querySelector("");',
      description: 'querySelector',
    ),
    CodeSnippet(
      trigger: 'ae',
      label: 'addEventListener',
      body: '│element.addEventListener("click", (e) => {\n  \n});',
      description: 'Event listener',
    ),
    CodeSnippet(
      trigger: 'class',
      label: 'class',
      body: 'class │ClassName {\n  constructor() {\n    \n  }\n}',
      description: 'JS class',
    ),
    CodeSnippet(
      trigger: 'try',
      label: 'try/catch',
      body: 'try {\n  │\n} catch (err) {\n  console.error(err);\n}',
      description: 'Try catch',
    ),
    CodeSnippet(
      trigger: 'iife',
      label: 'IIFE',
      body: '(() => {\n  │\n})();',
      description: 'Immediately invoked function',
    ),
    CodeSnippet(
      trigger: 'storage',
      label: 'localStorage',
      body: 'localStorage.setItem("│key", JSON.stringify(value));\nconst data = JSON.parse(localStorage.getItem("key"));',
      description: 'localStorage',
    ),
  ];

  // ── Python Snippets ────────────────────────────────────────────────────────
  static const List<CodeSnippet> python = [
    CodeSnippet(
      trigger: 'def',
      label: 'def function',
      body: 'def │function_name():\n    pass',
      description: 'Python function',
    ),
    CodeSnippet(
      trigger: 'class',
      label: 'class',
      body: 'class │ClassName:\n    def __init__(self):\n        pass',
      description: 'Python class',
    ),
    CodeSnippet(
      trigger: 'main',
      label: 'if __main__',
      body: 'if __name__ == "__main__":\n    │main()',
      description: 'Main block',
    ),
    CodeSnippet(
      trigger: 'for',
      label: 'for loop',
      body: 'for │item in items:\n    print(item)',
      description: 'For loop',
    ),
    CodeSnippet(
      trigger: 'while',
      label: 'while loop',
      body: 'while │condition:\n    pass',
      description: 'While loop',
    ),
    CodeSnippet(
      trigger: 'try',
      label: 'try/except',
      body: 'try:\n    │\nexcept Exception as e:\n    print(f"Error: {e}")',
      description: 'Try except',
    ),
    CodeSnippet(
      trigger: 'with',
      label: 'with open',
      body: 'with open("│filename.txt", "r") as f:\n    content = f.read()',
      description: 'File open context',
    ),
    CodeSnippet(
      trigger: 'list',
      label: 'list comp',
      body: 'result = [│item for item in items if condition]',
      description: 'List comprehension',
    ),
    CodeSnippet(
      trigger: 'dict',
      label: 'dict comp',
      body: 'result = {│k: v for k, v in items.items()}',
      description: 'Dict comprehension',
    ),
    CodeSnippet(
      trigger: 'lambda',
      label: 'lambda',
      body: '│fn = lambda x: x',
      description: 'Lambda function',
    ),
    CodeSnippet(
      trigger: 'import',
      label: 'import',
      body: 'import │module',
      description: 'Import statement',
    ),
    CodeSnippet(
      trigger: 'print',
      label: 'print f-string',
      body: 'print(f"│{value}")',
      description: 'f-string print',
    ),
    CodeSnippet(
      trigger: 'arg',
      label: 'argparse',
      body: 'import argparse\n\nparser = argparse.ArgumentParser()\nparser.add_argument("│--name", type=str, help="Name")\nargs = parser.parse_args()',
      description: 'Argument parser',
    ),
    CodeSnippet(
      trigger: 'req',
      label: 'requests',
      body: 'import requests\n\nres = requests.get("│url")\ndata = res.json()\nprint(data)',
      description: 'HTTP request',
    ),
  ];

  /// Returns snippets for the given language string
  static List<CodeSnippet> forLanguage(String lang) {
    switch (lang) {
      case 'html': return html;
      case 'css':  return css;
      case 'javascript':
      case 'js':   return javascript;
      case 'python':
      case 'py':   return python;
      default:     return [];
    }
  }

  /// Filters snippets whose trigger starts with [query]
  static List<CodeSnippet> search(String query, String lang) {
    if (query.isEmpty) return [];
    final all = forLanguage(lang);
    final q = query.toLowerCase();
    return all
        .where((s) =>
            s.trigger.toLowerCase().startsWith(q) ||
            s.label.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  /// Auto-closing pairs — returns the closing character for an opening one
  static String? autoClose(String char) {
    const pairs = {
      '{': '}',
      '(': ')',
      '[': ']',
      '"': '"',
      "'": "'",
    };
    return pairs[char];
  }
}
