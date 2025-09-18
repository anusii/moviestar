// Test file for print removal logic
void testFunction() {
  // Single line print - should be removed
  print('Simple message');

  // Multi-line print - should be removed completely
  print(
    'Long message with interpolation ${someVar}',
  );

  // Error print - should be preserved
  debugPrint('❌ Error message');

  // Regular debugPrint - should be preserved
  debugPrint('Regular debug message');

  // Another single line
  print('Another simple message');

  // Complex multi-line with nested parentheses - should be removed
  print(
    'Complex message with ${someFunction(arg1, arg2)} interpolation',
  );

  // Regular code - should be preserved
  final result = someFunction();

  // More regular code
  if (result != null) {
    return result;
  }
}