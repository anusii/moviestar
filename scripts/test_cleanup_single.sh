#!/bin/bash
# Test script for single file cleanup
set -e

DRY_RUN=true
VERBOSE=true

echo "🧹 Testing Print Statement Cleanup on single file"
echo "Mode: DRY RUN"
echo ""

# Create backup directory
mkdir -p scripts/backups

file="test_cleanup.dart"

echo "Processing: $file"

# Check if file exists
if [ ! -f "$file" ]; then
    echo "File not found: $file"
    exit 1
fi

# Create temporary file for processing
temp_file=$(mktemp)
cp "$file" "$temp_file"

# Track if file was modified
modified=false
print_statements_removed=0
debug_prints_removed=0

# Remove print() statements
if grep -q "print\s*(" "$file"; then
    echo "Found print statements, removing..."
    sed -i '/print\s*(/d' "$temp_file"
    print_count=$(grep -c "print\s*(" "$file" || echo 0)
    print_statements_removed=$print_count
    modified=true
    echo "  Removed $print_count print statements"
fi

# Remove non-error debugPrint statements
if grep -q "debugPrint" "$file"; then
    echo "Found debugPrint statements, processing..."

    # Count before
    debug_count_before=$(grep -c "debugPrint" "$temp_file" || echo 0)
    echo "  debugPrint count before: $debug_count_before"

    # Remove all debugPrint statements except those with error indicators
    # Keep lines containing: ❌, Error, error, Failed, failed
    echo "  Removing non-error debugPrints..."
    sed -i '/debugPrint.*❌/!{/debugPrint.*[Ee]rror/!{/debugPrint.*[Ff]ailed/!{/debugPrint/d;};};}' "$temp_file"
    modified=true

    # Count after
    debug_count_after=$(grep -c "debugPrint" "$temp_file" || echo 0)
    echo "  debugPrint count after: $debug_count_after"

    if [ $debug_count_before -gt $debug_count_after ]; then
        debug_removed=$((debug_count_before - debug_count_after))
        debug_prints_removed=$debug_removed
        echo "  Removed $debug_removed debug prints"
    fi
fi

echo ""
echo "📊 Results:"
echo "  Print statements removed: $print_statements_removed"
echo "  Debug prints removed: $debug_prints_removed"
echo "  File modified: $modified"

if [ "$modified" = true ]; then
    echo ""
    echo "📝 Changes preview:"
    echo "Original file:"
    grep -n "print\|debugPrint" "$file" || echo "No print statements found"
    echo ""
    echo "After cleanup:"
    grep -n "print\|debugPrint" "$temp_file" || echo "No print statements found"
fi

# Cleanup
rm -f "$temp_file"