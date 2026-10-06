import 'dart:io';

void main() async {
  var result = await Process.run('flutter', ['analyze', '--no-fatal-infos', '--no-fatal-warnings']);
  File('analyze_output.txt').writeAsStringSync(result.stdout + '\n' + result.stderr);
}
