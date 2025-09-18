#!/bin/bash
# Simple comment formatting fix using sed
set -e

echo "📝 Simple Comment Formatting Test"

file="test_cleanup.dart"

echo "Original comments without periods:"
grep -n "/// .*[^.]$" "$file" || echo "None found"

echo ""
echo "Fixing comments..."

# Create temp file
temp_file=$(mktemp)
cp "$file" "$temp_file"

# Fix comments that don't end with punctuation
# Match lines that start with ///, have content, but don't end with . ! ?
sed -i 's/^\(\s*\/\/\/\s.*[^.!?]\)$/\1./' "$temp_file"

echo "After fixing:"
grep -n "///" "$temp_file"

# Cleanup
rm -f "$temp_file"

echo ""
echo "Test completed."