#!/bin/bash
# Fixed print cleanup script
# Usage: ./cleanup_prints_fixed.sh [--dry-run]

DRY_RUN=false

for arg in "$@"; do
    case $arg in
        --dry-run|-d) DRY_RUN=true ;;
    esac
done

echo "🧹 Print Statement Cleanup (Fixed Version)"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
echo ""

mkdir -p scripts/backups

# Get all dart files in lib/
dart_files=($(find lib -name "*.dart" ! -name "*.g.dart" ! -name "*.gr.dart" ! -name "*.freezed.dart" ! -name "*.chopper.dart" ! -name "*.part.dart" ! -name "*.config.dart"))

total=${#dart_files[@]}
processed=0
modified=0
prints_removed=0
debug_removed=0

echo "Found $total files to process"
echo ""

for file in "${dart_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    ((processed++))
    progress=$((processed * 100 / total))
    printf "[%3d%%] (%d/%d) %s\n" "$progress" "$processed" "$total" "$file"

    # Count print statements
    print_count=$(grep -c "print(" "$file" 2>/dev/null || echo 0)
    debug_count=$(grep -c "debugPrint" "$file" 2>/dev/null || echo 0)

    if [ "$print_count" -gt 0 ] || [ "$debug_count" -gt 0 ]; then
        ((modified++))
        ((prints_removed += print_count))

        # Estimate non-error debugPrints (assume most are non-error)
        error_debug=$(grep -c "debugPrint.*❌\|debugPrint.*[Ee]rror\|debugPrint.*[Ff]ailed" "$file" 2>/dev/null || echo 0)
        debug_to_remove=$((debug_count - error_debug))
        ((debug_removed += debug_to_remove))

        echo "  → Will remove: $print_count prints, $debug_to_remove debugPrints"

        if [ "$DRY_RUN" = false ]; then
            # Create backup
            backup_file="scripts/backups/$(basename "$file")_$(date +%s).backup"
            cp "$file" "$backup_file"

            # Remove print statements
            if [ "$print_count" -gt 0 ]; then
                sed -i '/print(/d' "$file"
            fi

            # Remove non-error debugPrint statements
            if [ "$debug_to_remove" -gt 0 ]; then
                sed -i '/debugPrint.*❌/!{/debugPrint.*[Ee]rror/!{/debugPrint.*[Ff]ailed/!{/debugPrint/d;};};}' "$file"
            fi

            echo "  ✓ Cleaned and backed up"
        fi
    fi
done

echo ""
echo "📊 Cleanup Statistics:"
echo "  Files processed: $processed"
echo "  Files modified: $modified"
echo "  Print statements removed: $prints_removed"
echo "  Debug prints removed: $debug_removed"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run without --dry-run to apply changes"
else
    echo ""
    echo "✅ Print statement cleanup completed!"
fi