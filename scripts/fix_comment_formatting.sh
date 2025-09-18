#!/bin/bash
# Script to fix comment formatting - ensure comments end with periods and have proper spacing
# Usage: ./fix_comment_formatting.sh [--dry-run] [--verbose]

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

echo "📝 Comment Formatting Fix Tool (Bash)"
echo "Mode: $([ "$DRY_RUN" = true ] && echo "DRY RUN" || echo "LIVE")"
echo ""

# Create backup directory
mkdir -p scripts/backups

# Counters
files_processed=0
files_modified=0
comments_fixed=0

# Create temp file for file list
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

    # Fix comment formatting
    # 1. Add periods to comment lines that don't end with punctuation
    # 2. Ensure blank line after comment blocks

    # Process the file line by line
    temp_output=$(mktemp)
    previous_line_was_comment=false
    in_comment_block=false

    while IFS= read -r line; do
        # Check if this line is a comment
        if [[ "$line" =~ ^[[:space:]]*///[[:space:]] ]]; then
            in_comment_block=true

            # Extract the comment text (without ///)
            comment_text=$(echo "$line" | sed 's/^[[:space:]]*\/\/\/[[:space:]]*//')

            # Check if comment needs a period
            if [[ ! "$comment_text" =~ \.$|!$|\?$|:$|;$ ]] && [[ -n "$comment_text" ]]; then
                # Add period to comment
                fixed_line=$(echo "$line" | sed 's/$/\./')
                echo "$fixed_line" >> "$temp_output"
                modified=true
                ((comments_fixed++))
                [ "$VERBOSE" = true ] && echo "  Added period to comment in: $file"
            else
                echo "$line" >> "$temp_output"
            fi
            previous_line_was_comment=true

        else
            # Not a comment line
            if [ "$previous_line_was_comment" = true ] && [ "$in_comment_block" = true ]; then
                # Just finished a comment block, ensure blank line
                if [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]]; then
                    # Add blank line before non-empty, non-whitespace line
                    echo "" >> "$temp_output"
                    modified=true
                    [ "$VERBOSE" = true ] && echo "  Added blank line after comment block in: $file"
                fi
            fi
            echo "$line" >> "$temp_output"
            previous_line_was_comment=false
            in_comment_block=false
        fi
    done < "$file"

    # Replace temp file content if modified
    if [ "$modified" = true ]; then
        cp "$temp_output" "$temp_file"
        ((files_modified++))
    fi

    rm -f "$temp_output"

    # Apply changes if modified
    if [ "$modified" = true ]; then
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