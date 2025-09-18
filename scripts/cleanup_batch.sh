#!/bin/bash
# Batch cleanup script - processes files in small groups
# Usage: ./cleanup_batch.sh [--dry-run] [--live]

DRY_RUN=true

for arg in "$@"; do
    case $arg in
        --live) DRY_RUN=false ;;
        --dry-run) DRY_RUN=true ;;
    esac
done

echo "🧹 Batch Print Statement Cleanup"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
echo ""

mkdir -p scripts/backups

# Get files with print statements
files_with_prints=()
echo "Scanning for files with print statements..."

# Scan specific directories known to have issues
for dir in "lib/core/services" "lib/utils" "lib/screens" "lib/providers"; do
    if [ -d "$dir" ]; then
        while IFS= read -r file; do
            if [ -f "$file" ] && grep -q "print(" "$file" 2>/dev/null; then
                files_with_prints+=("$file")
            fi
        done < <(find "$dir" -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null)
    fi
done

total=${#files_with_prints[@]}
echo "Found $total files with print statements"
echo ""

if [ $total -eq 0 ]; then
    echo "No files with print statements found!"
    exit 0
fi

processed=0
total_prints=0

for file in "${files_with_prints[@]}"; do
    ((processed++))

    print_count=$(grep -c "print(" "$file" 2>/dev/null || echo 0)
    ((total_prints += print_count))

    echo "[$processed/$total] $file ($print_count prints)"

    if [ "$print_count" -gt 0 ]; then
        if [ "$DRY_RUN" = false ]; then
            # Create backup
            backup_file="scripts/backups/$(basename "$file")_$(date +%s).backup"
            cp "$file" "$backup_file"

            # Remove print statements
            sed -i '/print(/d' "$file"
            echo "  ✓ Cleaned (backup: $backup_file)"
        else
            echo "  → Would remove $print_count print statements"
        fi
    fi
done

echo ""
echo "📊 Summary:"
echo "  Files processed: $processed"
echo "  Total print statements: $total_prints"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run with --live to apply changes"
else
    echo ""
    echo "✅ Cleanup completed!"
fi