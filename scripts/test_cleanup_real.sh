#!/bin/bash
# Test cleanup on actual files with print statements

echo "🧹 Testing Print Cleanup on Real Files"
echo ""

# Test files with known print statements
files=(
    "lib/core/services/api/content_service.dart"
    "lib/utils/network_client.dart"
)

for file in "${files[@]}"; do
    echo "=== Processing: $file ==="

    if [ ! -f "$file" ]; then
        echo "File not found!"
        continue
    fi

    # Count before
    print_before=$(grep -c "print(" "$file" 2>/dev/null || echo 0)
    debug_before=$(grep -c "debugPrint" "$file" 2>/dev/null || echo 0)

    echo "Before: $print_before prints, $debug_before debugPrints"

    if [ $print_before -gt 0 ]; then
        echo "Sample print statements:"
        grep -n "print(" "$file" | head -2 | sed 's/^/  /'
    fi

    # Create backup
    mkdir -p scripts/backups
    cp "$file" "scripts/backups/$(basename "$file").test_backup"

    # Apply cleanup (DRY RUN - just show what would happen)
    echo ""
    echo "Would remove these print statements:"
    grep -n "print(" "$file" | sed 's/^/  REMOVE: /'

    echo ""
    echo "----------------------------------------"
done

echo ""
echo "💡 This was a dry run analysis"
echo "📁 Backups created in scripts/backups/"