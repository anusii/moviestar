#!/bin/bash
# Batch comment formatting script
# Usage: ./fix_comments_batch.sh [--dry-run] [--live]

DRY_RUN=true

for arg in "$@"; do
    case $arg in
        --live) DRY_RUN=false ;;
        --dry-run) DRY_RUN=true ;;
    esac
done

echo "📝 Batch Comment Formatting Fix"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
echo ""

mkdir -p scripts/backups

# Get files with comments that need fixing
files_with_comments=()
echo "Scanning for files with comments that need periods..."

# Scan lib directory for files with comments missing periods
while IFS= read -r file; do
    if [ -f "$file" ] && grep -q "/// .*[^.!?]$" "$file" 2>/dev/null; then
        files_with_comments+=("$file")
    fi
done < <(find lib -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null)

total=${#files_with_comments[@]}
echo "Found $total files with comments needing periods"
echo ""

if [ $total -eq 0 ]; then
    echo "No files with comments needing periods found!"
    exit 0
fi

processed=0
total_comments=0

for file in "${files_with_comments[@]}"; do
    ((processed++))

    comment_count=$(grep -c "/// .*[^.!?]$" "$file" 2>/dev/null || echo 0)
    ((total_comments += comment_count))

    echo "[$processed/$total] $file ($comment_count comments)"

    if [ "$comment_count" -gt 0 ]; then
        if [ "$DRY_RUN" = false ]; then
            # Create backup
            backup_file="scripts/backups/$(basename "$file")_comments_$(date +%s).backup"
            cp "$file" "$backup_file"

            # Fix comments - add periods to lines that don't end with punctuation
            sed -i 's/^\(\s*\/\/\/\s.*[^.!?]\)$/\1./' "$file"
            echo "  ✓ Fixed (backup: $backup_file)"
        else
            echo "  → Would fix $comment_count comments"
            # Show a sample
            grep -n "/// .*[^.!?]$" "$file" | head -2 | sed 's/^/    /'
        fi
    fi
done

echo ""
echo "📊 Summary:"
echo "  Files processed: $processed"
echo "  Total comments fixed: $total_comments"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run with --live to apply changes"
else
    echo ""
    echo "✅ Comment formatting completed!"
fi