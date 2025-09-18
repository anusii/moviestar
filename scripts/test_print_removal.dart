// Test file for print removal logic
void testFunction() {
  // Single line print - should be removed

  // Multi-line print - should be removed completely

  // Error print - should be preserved
  debugPrint('❌ Error message');

  // Regular debugPrint - should be preserved
  debugPrint('Regular debug message');

  // Another single line

  // Complex multi-line with nested parentheses - should be removed

  // Regular code - should be preserved
  final result = someFunction();

  // More regular code
  if (result != null) {
    return result;
  }
}
