/// Simple test script for deprecated API fixes
import 'dart:io';

void main() {
  final testFile = File('test_cleanup.dart');
  if (!testFile.existsSync()) {
    print('Test file not found');
    return;
  }

  final content = testFile.readAsStringSync();
  print('Original content:');
  print(content);
  print('\n' + '='*50 + '\n');

  // Apply withOpacity fix
  final fixed = content.replaceAll(RegExp(r'\.withOpacity\s*\(\s*([^)]+)\s*\)'), '.withValues(alpha: \$1)');

  print('Fixed content:');
  print(fixed);

  // Show what changed
  final lines = content.split('\n');
  final fixedLines = fixed.split('\n');

  print('\n' + '='*50 + '\n');
  print('Changes made:');
  for (int i = 0; i < lines.length && i < fixedLines.length; i++) {
    if (lines[i] != fixedLines[i]) {
      print('Line ${i + 1}:');
      print('  Before: ${lines[i]}');
      print('  After:  ${fixedLines[i]}');
    }
  }
}