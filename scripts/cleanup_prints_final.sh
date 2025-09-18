#!/bin/bash
# Final working print statement cleanup script
# Usage: ./cleanup_prints_final.sh [--dry-run] [--verbose] [--test]

set -e

DRY_RUN=false
VERBOSE=false
TEST_MODE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run|-d)
            DRY_RUN=true
            ;;
        --verbose|-v)
            VERBOSE=true
            ;;
        --test|-t)
            TEST_MODE=true
            ;;
    esac
done

echo "🧹 Print Statement Cleanup Tool (Final)"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
[ "$TEST_MODE" = true ] && echo "TEST MODE: Processing limited files only"
echo ""

# Create backup directory
mkdir -p scripts/backups

files_processed=0
files_modified=0
print_statements_removed=0
debug_prints_removed=0

# Get file list based on mode
if [ "$TEST_MODE" = true ]; then
    # Test mode - process just a few files
    echo "Test mode: processing test_cleanup.dart and first 5 lib files"
    find lib -name "*.dart" -type f | head -5 > /tmp/dart_files.txt
    echo "test_cleanup.dart" >> /tmp/dart_files.txt
else
    # Full mode - process all files
    find lib -name "*.dart" \
        ! -name "*.g.dart" \
        ! -name "*.gr.dart" \
        ! -name "*.freezed.dart" \
        ! -name "*.chopper.dart" \
        ! -name "*.part.dart" \
        ! -name "*.config.dart" > /tmp/dart_files.txt
fi

# Count total files for progress
total_files=$(wc -l < /tmp/dart_files.txt)
echo "Found $total_files files to process"
echo ""

while IFS= read -r file; do
    if [ ! -f "$file" ]; then
        continue
    fi

    ((files_processed++))

    # Show progress indicator
    progress=$((files_processed * 100 / total_files))
    printf "\r[%3d%%] (%d/%d) Processing: %-50s" "$progress" "$files_processed" "$total_files" "$(basename "$file")"

    [ "$VERBOSE" = true ] && echo "" && echo "  Full path: $file"

    # Check for print statements
    has_prints=false
    print_count=0
    if grep -q "print\s*(" "$file" 2>/dev/null; then
        has_prints=true
        print_count=$(grep -c "print\s*(" "$file" 2>/dev/null || echo 0)
    fi

    # Check for debugPrint statements
    has_debug=false
    debug_removed=0
    if grep -q "debugPrint" "$file" 2>/dev/null; then
        debug_before=$(grep -c "debugPrint" "$file" 2>/dev/null || echo 0)
        debug_errors=$(grep -c "debugPrint.*❌\|debugPrint.*[Ee]rror\|debugPrint.*[Ff]ailed" "$file" 2>/dev/null || echo 0)
        debug_removed=$((debug_before - debug_errors))
        if [ $debug_removed -gt 0 ]; then
            has_debug=true
        fi
    fi

    if [ "$has_prints" = true ] || [ "$has_debug" = true ]; then
        ((files_modified++))
        ((print_statements_removed += print_count))
        ((debug_prints_removed += debug_removed))

        [ "$VERBOSE" = true ] && echo "  Will remove: $print_count prints, $debug_removed debugPrints"

        if [ "$DRY_RUN" = false ]; then
            # Create backup
            backup_file="scripts/backups/$(basename "$file")_$(date +%s).backup"
            cp "$file" "$backup_file"

            # Remove print statements
            if [ "$has_prints" = true ]; then
                sed -i '/print\s*(/d' "$file"
            fi

            # Remove non-error debugPrint statements
            if [ "$has_debug" = true ]; then
                sed -i '/debugPrint.*❌/!{/debugPrint.*[Ee]rror/!{/debugPrint.*[Ff]ailed/!{/debugPrint/d;};};}' "$file"
            fi
        fi

        [ "$VERBOSE" = true ] && echo "📝 Modified: $file"
    fi

done < /tmp/dart_files.txt

# Cleanup
rm -f /tmp/dart_files.txt

echo ""  # New line after progress indicator
echo "📊 Cleanup Statistics:"
echo "  Files processed: $files_processed"
echo "  Files modified: $files_modified"
echo "  Print statements removed: $print_statements_removed"
echo "  Debug prints removed: $debug_prints_removed"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run without --dry-run to apply changes"
    echo "💡 Use --test flag to test on fewer files first"
else
    echo ""
    echo "✅ Print statement cleanup completed!"
fi