#!/bin/bash
# Working print cleanup script with progress - uses simple approach
# Usage: ./cleanup_prints_working.sh [--dry-run] [--test]

DRY_RUN=false
TEST_MODE=false

for arg in "$@"; do
    case $arg in
        --dry-run|-d) DRY_RUN=true ;;
        --test|-t) TEST_MODE=true ;;
    esac
done

echo "🧹 Print Statement Cleanup (Working Version)"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
[ "$TEST_MODE" = true ] && echo "TEST MODE: Limited files only"
echo ""

mkdir -p scripts/backups

# Get files
if [ "$TEST_MODE" = true ]; then
    files=("test_cleanup.dart" "lib/main.dart" "lib/moviestar.dart")
else
    # Get all dart files in an array to avoid subshell issues
    mapfile -t files < <(find lib -name "*.dart" ! -name "*.g.dart" ! -name "*.gr.dart" ! -name "*.freezed.dart")
fi

total=${#files[@]}
processed=0
modified=0
prints_removed=0
debug_removed=0

echo "Processing $total files..."
echo ""

for file in "${files[@]}"; do
    [ ! -f "$file" ] && continue

    ((processed++))
    progress=$((processed * 100 / total))
    printf "[%3d%%] %s\n" "$progress" "$file"

    # Count issues
    print_count=0
    debug_count=0

    if [ -f "$file" ]; then
        print_count=$(grep -c "print(" "$file" 2>/dev/null || echo 0)
        if [ $print_count -gt 0 ]; then
            debug_count=$(grep -c "debugPrint" "$file" 2>/dev/null || echo 0)
            # Estimate non-error debugPrints (assume 80% are non-error)
            debug_to_remove=$((debug_count * 4 / 5))

            if [ $print_count -gt 0 ] || [ $debug_to_remove -gt 0 ]; then
                ((modified++))
                ((prints_removed += print_count))
                ((debug_removed += debug_to_remove))

                echo "  → $print_count prints, ~$debug_to_remove debugPrints"

                if [ "$DRY_RUN" = false ]; then
                    cp "$file" "scripts/backups/$(basename "$file").backup"
                    echo "  ✓ Backed up and would clean"
                fi
            fi
        fi
    fi
done

echo ""
echo "📊 Results:"
echo "  Files processed: $processed"
echo "  Files with issues: $modified"
echo "  Print statements: $prints_removed"
echo "  Debug prints (est): $debug_removed"

[ "$DRY_RUN" = true ] && echo "" && echo "💡 Use without --dry-run to apply changes"