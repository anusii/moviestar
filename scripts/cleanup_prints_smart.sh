#!/bin/bash
# Smart Print Statement Cleanup - Handles multi-line statements correctly
# Usage: ./cleanup_prints_smart.sh [--dry-run] [--live] [file1] [file2] ...

DRY_RUN=true
FILES_SPECIFIED=false
TARGET_FILES=()

# Parse arguments
for arg in "$@"; do
    case $arg in
        --live) DRY_RUN=false ;;
        --dry-run) DRY_RUN=true ;;
        *.dart)
            TARGET_FILES+=("$arg")
            FILES_SPECIFIED=true
            ;;
    esac
done

echo "🧹 Smart Print Statement Cleanup"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
echo ""

mkdir -p scripts/backups

# If no files specified, scan for files with print statements
if [ "$FILES_SPECIFIED" = false ]; then
    echo "Scanning for files with print statements..."

    # Scan lib directory recursively for files with print statements
    while IFS= read -r file; do
        if [ -f "$file" ] && grep -q "print(" "$file" 2>/dev/null; then
            TARGET_FILES+=("$file")
        fi
    done < <(find "lib" -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" 2>/dev/null)
fi

total=${#TARGET_FILES[@]}
echo "Found $total files to process"
echo ""

if [ $total -eq 0 ]; then
    echo "No files with print statements found!"
    exit 0
fi

# Create AWK script for smart print removal
cat > /tmp/remove_prints.awk << 'AWK_SCRIPT'
BEGIN {
    in_print = 0
    paren_level = 0
    brace_level = 0
    print_start_line = 0
    skip_lines = ""
    preserve_print = 0
}

{
    line = $0

    # Check if this line starts a print statement
    if (!in_print && match(line, /^[[:space:]]*print[[:space:]]*\(/)) {
        # Check if this print should be preserved (contains error markers)
        if (match(line, /❌/) || match(line, /debugPrint/)) {
            preserve_print = 1
        } else {
            preserve_print = 0
        }

        in_print = 1
        print_start_line = NR
        paren_level = 0
        brace_level = 0
        skip_lines = ""

        # Count parentheses and braces in the current line
        for (i = 1; i <= length(line); i++) {
            char = substr(line, i, 1)
            if (char == "(") paren_level++
            else if (char == ")") paren_level--
            else if (char == "{") brace_level++
            else if (char == "}") brace_level--
        }

        # If statement completes on same line and should be preserved, print it
        if (paren_level <= 0 && preserve_print) {
            print line
            in_print = 0
        }
        # If statement completes on same line and should be removed, skip it
        else if (paren_level <= 0 && !preserve_print) {
            in_print = 0
        }
        # Multi-line statement - store the line if preserving
        else if (preserve_print) {
            skip_lines = skip_lines line "\n"
        }
    }
    # We're in the middle of a multi-line print statement
    else if (in_print) {
        # Count parentheses and braces in the current line
        for (i = 1; i <= length(line); i++) {
            char = substr(line, i, 1)
            if (char == "(") paren_level++
            else if (char == ")") paren_level--
            else if (char == "{") brace_level++
            else if (char == "}") brace_level--
        }

        if (preserve_print) {
            skip_lines = skip_lines line "\n"
        }

        # Check if print statement is complete (balanced parentheses)
        if (paren_level <= 0) {
            if (preserve_print) {
                # Print all stored lines for preserved print statements
                printf "%s", skip_lines
            }
            # Reset state
            in_print = 0
            preserve_print = 0
            skip_lines = ""
        }
    }
    # Regular line - not part of a print statement
    else {
        print line
    }
}
AWK_SCRIPT

processed=0
total_prints_removed=0
total_prints_preserved=0

for file in "${TARGET_FILES[@]}"; do
    ((processed++))

    # Count existing print statements for reporting
    print_count=$(grep -c "print(" "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        print_count=0
    fi

    preserved_count=$(grep -c -E "(❌.*print|debugPrint)" "$file" 2>/dev/null)
    if [ $? -ne 0 ]; then
        preserved_count=0
    fi

    # Calculate removable count safely
    if [ "$preserved_count" -gt "$print_count" ]; then
        removable_count=0
    else
        removable_count=$((print_count - preserved_count))
    fi

    echo "[$processed/$total] $file ($removable_count removable, $preserved_count preserved)"

    if [ "$print_count" -gt 0 ]; then
        if [ "$DRY_RUN" = false ]; then
            # Create backup
            backup_file="scripts/backups/$(basename "$file")_$(date +%s).backup"
            cp "$file" "$backup_file"

            # Apply smart print removal
            awk -f /tmp/remove_prints.awk "$file" > "$file.tmp"

            # Verify the output doesn't have syntax errors (basic check)
            if [ -s "$file.tmp" ]; then
                mv "$file.tmp" "$file"
                ((total_prints_removed += removable_count))
                ((total_prints_preserved += preserved_count))
                echo "  ✓ Processed (backup: $backup_file)"
            else
                rm "$file.tmp"
                echo "  ❌ Error: Output was empty, skipping"
            fi
        else
            echo "  → Would remove $removable_count print statements, preserve $preserved_count"
        fi
    fi
done

# Cleanup temporary AWK script
rm -f /tmp/remove_prints.awk

echo ""
echo "📊 Summary:"
echo "  Files processed: $processed"
if [ "$DRY_RUN" = false ]; then
    echo "  Print statements removed: $total_prints_removed"
    echo "  Print statements preserved: $total_prints_preserved"
else
    echo "  Total removable prints found: $total_prints_removed"
    echo "  Total preserved prints found: $total_prints_preserved"
fi

if [ "$DRY_RUN" = true ]; then
    echo ""
    echo "💡 Run with --live to apply changes"
else
    echo ""
    echo "✅ Smart cleanup completed!"
    echo "💡 Run 'flutter analyze' to verify no syntax errors"
fi