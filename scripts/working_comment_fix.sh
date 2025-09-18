#!/bin/bash
# Working comment formatting script
# Usage: ./working_comment_fix.sh [--dry-run] [--verbose]

set -e

DRY_RUN=false
VERBOSE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run|-d)
            DRY_RUN=true
            ;;
        --verbose|-v)
            VERBOSE=true
            ;;
    esac
done

echo "📝 Comment Formatting Fix Tool"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
echo ""

# Create backup directory
mkdir -p scripts/backups

# Get list of dart files
dart_files=($(find lib -name "*.dart" \
    ! -name "*.g.dart" \
    ! -name "*.gr.dart" \
    ! -name "*.freezed.dart" \
    ! -name "*.chopper.dart" \
    ! -name "*.part.dart" \
    ! -name "*.config.dart"))

files_processed=0
files_modified=0
comments_fixed=0

for file in "${dart_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    ((files_processed++))

    # Check if file has comments that need fixing
    if grep -q "/// .*[^.!?]$" "$file"; then
        comment_count=$(grep -c "/// .*[^.!?]$" "$file" || echo 0)

        if [ $comment_count -gt 0 ]; then
            ((files_modified++))
            ((comments_fixed += comment_count))

            if [ "$DRY_RUN" = false ]; then
                # Create backup
                backup_file="scripts/backups/$(basename "$file")_$(date +%s).backup"
                cp "$file" "$backup_file"

                # Fix comments - add periods to lines that don't end with punctuation
                sed -i 's/^\(\s*\/\/\/\s.*[^.!?]\)$/\1./' "$file"
            fi

            [ "$VERBOSE" = true ] && echo "📝 Fixed $comment_count comments in: $file"
        fi
    fi
done

echo "📊 Comment Formatting Statistics:"
echo "  Files processed: $files_processed"
echo "  Files modified: $files_modified"
echo "  Comments fixed: $comments_fixed"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run without --dry-run to apply changes"
else
    echo ""
    echo "✅ Comment formatting completed!"
fi