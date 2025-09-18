#!/bin/bash
# Test version of main cleanup script
set -e

DRY_RUN=true
VERBOSE=true

echo "🧹 Print Statement Cleanup Tool (Bash)"
echo "Mode: DRY RUN"
echo ""

# Create backup directory
mkdir -p scripts/backups

# Counters
files_processed=0
files_modified=0
print_statements_removed=0
debug_prints_removed=0

# Test on specific files
files=(
    "test_cleanup.dart"
    "lib/constants/dimensions.dart"
)

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Skipping non-existent file: $file"
        continue
    fi

    ((files_processed++))

    # Create temporary file for processing
    temp_file=$(mktemp)
    cp "$file" "$temp_file"

    # Track if file was modified
    modified=false

    # Remove print() statements
    if grep -q "print\s*(" "$file"; then
        sed -i '/print\s*(/d' "$temp_file"
        print_count=$(grep -c "print\s*(" "$file" || echo 0)
        ((print_statements_removed += print_count))
        modified=true
        [ "$VERBOSE" = true ] && echo "  Removed $print_count print statements from: $file"
    fi

    # Remove non-error debugPrint statements (keep ❌ ones)
    if grep -q "debugPrint" "$file"; then
        debug_count_before=$(grep -c "debugPrint" "$temp_file" || echo 0)

        # Remove all debugPrint statements except those with error indicators
        sed -i '/debugPrint.*❌/!{/debugPrint.*[Ee]rror/!{/debugPrint.*[Ff]ailed/!{/debugPrint/d;};};}' "$temp_file"

        debug_count_after=$(grep -c "debugPrint" "$temp_file" || echo 0)

        if [ $debug_count_before -gt $debug_count_after ]; then
            debug_removed=$((debug_count_before - debug_count_after))
            ((debug_prints_removed += debug_removed))
            modified=true
            [ "$VERBOSE" = true ] && echo "  Removed $debug_removed debug prints from: $file"
        fi
    fi

    # Apply changes if modified
    if [ "$modified" = true ]; then
        ((files_modified++))
        [ "$VERBOSE" = true ] && echo "📝 Modified: $file"
    fi

    # Cleanup
    rm -f "$temp_file"
done

echo "📊 Cleanup Statistics:"
echo "  Files processed: $files_processed"
echo "  Files modified: $files_modified"
echo "  Print statements removed: $print_statements_removed"
echo "  Debug prints removed: $debug_prints_removed"

echo ""
echo "💡 This was a dry run test"