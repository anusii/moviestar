#!/bin/bash
# Test script for comment formatting on single file
set -e

DRY_RUN=true
VERBOSE=true

echo "📝 Testing Comment Formatting on single file"
echo "Mode: DRY RUN"
echo ""

file="test_cleanup.dart"

echo "Processing: $file"

# Check if file exists
if [ ! -f "$file" ]; then
    echo "File not found: $file"
    exit 1
fi

# Show original comments
echo "Original comments:"
grep -n "///" "$file" || echo "No comments found"
echo ""

# Create temporary file for processing
temp_file=$(mktemp)
cp "$file" "$temp_file"

# Track changes
modified=false
comments_fixed=0

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
        if [[ ! "$comment_text" =~ \.$|!$|\?$ ]] && [[ -n "$comment_text" ]]; then
            # Add period to comment
            fixed_line=$(echo "$line" | sed 's/$/\./')
            echo "$fixed_line" >> "$temp_output"
            modified=true
            ((comments_fixed++))
            echo "  Fixed comment: $line -> $fixed_line"
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
                echo "  Added blank line before: $line"
            fi
        fi
        echo "$line" >> "$temp_output"
        previous_line_was_comment=false
        in_comment_block=false
    fi
done < "$file"

echo ""
echo "📊 Results:"
echo "  Comments fixed: $comments_fixed"
echo "  File modified: $modified"

if [ "$modified" = true ]; then
    echo ""
    echo "📝 Fixed comments:"
    grep -n "///" "$temp_output" || echo "No comments found"
fi

# Cleanup
rm -f "$temp_file" "$temp_output"