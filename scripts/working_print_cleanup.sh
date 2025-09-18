#!/bin/bash
# Working print statement cleanup script
# Usage: ./working_print_cleanup.sh [--dry-run] [--verbose]

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

echo "🧹 Print Statement Cleanup Tool"
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
print_statements_removed=0
debug_prints_removed=0

for file in "${dart_files[@]}"; do
    if [ ! -f "$file" ]; then
        continue
    fi

    ((files_processed++))

    # Check for print statements
    has_prints=false
    if grep -q "print\s*(" "$file"; then
        has_prints=true
        print_count=$(grep -c "print\s*(" "$file" || echo 0)
        ((print_statements_removed += print_count))
    fi

    # Check for debugPrint statements
    has_debug=false
    if grep -q "debugPrint" "$file"; then
        debug_before=$(grep -c "debugPrint" "$file" || echo 0)
        # Count how many will be removed (not error messages)
        debug_errors=$(grep -c "debugPrint.*❌\|debugPrint.*[Ee]rror\|debugPrint.*[Ff]ailed" "$file" || echo 0)
        debug_removed=$((debug_before - debug_errors))
        if [ $debug_removed -gt 0 ]; then
            has_debug=true
            ((debug_prints_removed += debug_removed))
        fi
    fi

    if [ "$has_prints" = true ] || [ "$has_debug" = true ]; then
        ((files_modified++))

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
done

echo "📊 Cleanup Statistics:"
echo "  Files processed: $files_processed"
echo "  Files modified: $files_modified"
echo "  Print statements removed: $print_statements_removed"
echo "  Debug prints removed: $debug_prints_removed"

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run without --dry-run to apply changes"
else
    echo ""
    echo "✅ Print statement cleanup completed!"
fi