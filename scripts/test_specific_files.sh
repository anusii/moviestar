#!/bin/bash
# Test script on specific files with print statements

echo "🧹 Testing on files with known print statements"
echo ""

files=(
    "lib/core/services/api/content_service.dart"
    "lib/core/services/favorites/movie_list_file_helper.dart"
    "lib/utils/network_client.dart"
)

for file in "${files[@]}"; do
    echo "=== Testing: $file ==="

    if [ ! -f "$file" ]; then
        echo "File not found!"
        continue
    fi

    # Count print statements before
    print_count=$(grep -c "print(" "$file" 2>/dev/null || echo 0)
    debug_count=$(grep -c "debugPrint" "$file" 2>/dev/null || echo 0)

    echo "Before cleanup:"
    echo "  Print statements: $print_count"
    echo "  DebugPrint statements: $debug_count"

    if [ $print_count -gt 0 ]; then
        echo "  First few print statements:"
        grep -n "print(" "$file" | head -3
    fi

    echo ""
done