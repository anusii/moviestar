#!/bin/bash
# Final working comment formatting script with progress indicators
# Usage: ./fix_comments_final.sh [--dry-run] [--verbose] [--test]

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

echo "📝 Comment Formatting Fix Tool (Final)"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
[ "$TEST_MODE" = true ] && echo "TEST MODE: Processing limited files only"
echo ""

# Create backup directory
mkdir -p scripts/backups

files_processed=0
files_modified=0
comments_fixed=0

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

    # Check if file has comments that need fixing
    if grep -q "/// .*[^.!?]$" "$file" 2>/dev/null; then
        comment_count=$(grep -c "/// .*[^.!?]$" "$file" 2>/dev/null || echo 0)

        if [ $comment_count -gt 0 ]; then
            ((files_modified++))
            ((comments_fixed += comment_count))

            [ "$VERBOSE" = true ] && echo "  Will fix $comment_count comments"

            if [ "$DRY_RUN" = false ]; then
                # Create backup
                backup_file="scripts/backups/$(basename "$file")_$(date +%s).backup"
                cp "$file" "$backup_file"

                # Fix comments - add periods to lines that don't end with punctuation
                sed -i 's/^\(\s*\/\/\/\s.*[^.!?]\)$/\1./' "$file"
            fi

            [ "$VERBOSE" = true ] && echo "📝 Modified: $file"
        fi
    fi

done < /tmp/dart_files.txt

# Cleanup
rm -f /tmp/dart_files.txt

echo ""  # New line after progress indicator
echo "📊 Comment Formatting Statistics:"
echo "  Files processed: $files_processed"
echo "  Files modified: $files_modified"
echo "  Comments fixed: $comments_fixed"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run without --dry-run to apply changes"
    echo "💡 Use --test flag to test on fewer files first"
else
    echo ""
    echo "✅ Comment formatting completed!"
fi