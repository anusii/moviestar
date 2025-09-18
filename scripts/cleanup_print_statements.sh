#!/bin/bash
# Script to clean up print statements and non-error debug prints
# Usage: ./cleanup_print_statements.sh [--dry-run] [--verbose]

set -e

DRY_RUN=false
VERBOSE=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            ;;
    esac
done

echo "🧹 Print Statement Cleanup Tool (Bash)"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
echo ""

# Create backup directory
mkdir -p scripts/backups

# Counters
files_processed=0
files_modified=0
print_statements_removed=0
debug_prints_removed=0

# Create temp file for file list to avoid subshell issues
temp_file_list=$(mktemp)
find lib -name "*.dart" \
    ! -name "*.g.dart" \
    ! -name "*.gr.dart" \
    ! -name "*.freezed.dart" \
    ! -name "*.chopper.dart" \
    ! -name "*.part.dart" \
    ! -name "*.config.dart" > "$temp_file_list"

# Process each file
while read -r file; do
    if [ -z "$file" ]; then
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
        # Keep lines containing: ❌, Error, error, Failed, failed
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

        if [ "$DRY_RUN" = false ]; then
            # Create backup
            backup_file="scripts/backups/$(basename "$file")_$(date +%s).backup"
            cp "$file" "$backup_file"

            # Apply changes
            cp "$temp_file" "$file"
        fi

        [ "$VERBOSE" = true ] && echo "📝 Modified: $file"
    fi

    # Cleanup
    rm -f "$temp_file"
done < "$temp_file_list"

# Cleanup temp file list
rm -f "$temp_file_list"

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