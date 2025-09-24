#!/bin/bash
# Comment Auto-Fix Script for MovieStar Project
#
# Automatically fixes comment style violations:
# 1. Adds periods to comments missing them
# 2. Adds blank lines between comments and code

target="${1:-lib/}"
dry_run=false
[[ "$2" == "--dry-run" || "$1" == "--dry-run" ]] && dry_run=true

echo "MovieStar Comment Auto-Fix"
echo "=========================="
echo "Target: $target"
[[ "$dry_run" == true ]] && echo "Mode: DRY-RUN (no changes)" || echo "Mode: LIVE (files will be modified)"
echo ""

should_ignore_line() {
    local line="$1"
    [[ "$line" =~ (TODO|FIXME|NOTE|Time-stamp|https?://) ]] && return 0
    [[ "$line" =~ "This program is free software" ]] && return 0
    [[ "$line" =~ "the terms of the GNU General Public License" ]] && return 0
    [[ "$line" =~ "Foundation, either version" ]] && return 0
    [[ "$line" =~ "This program is distributed in the hope" ]] && return 0
    [[ "$line" =~ "ANY WARRANTY; without even the implied warranty" ]] && return 0
    [[ "$line" =~ "FOR A PARTICULAR PURPOSE" ]] && return 0
    [[ "$line" =~ "You should have received a copy of the GNU General Public License" ]] && return 0
    [[ "$line" =~ "version\." ]] && return 0
    [[ "$line" =~ "details\." ]] && return 0
    return 1
}

fix_file() {
    local file_path="$1"
    [[ "$file_path" =~ \.g\.dart$ ]] && return 0
    [[ ! -f "$file_path" ]] && return 0

    echo "Processing: $file_path"

    local temp1="${file_path}.tmp1"
    local temp2="${file_path}.tmp2"
    local fixes=0

    # Step 1: Fix missing periods
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*//[^/] ]] && ! should_ignore_line "$line"; then
            local comment_content=$(echo "$line" | sed 's/^[[:space:]]*\/\/[[:space:]]*//')
            if [[ ! "$comment_content" =~ [.!?]$ ]] && [[ -n "$comment_content" ]]; then
                local prefix=$(echo "$line" | sed 's/\(^[[:space:]]*\/\/[[:space:]]*\).*/\1/')
                line="${prefix}${comment_content}."
                ((fixes++))
                [[ "$dry_run" == true ]] && echo "  Would add period to comment"
            fi
        fi
        echo "$line"
    done < "$file_path" > "$temp1"

    # Step 2: Fix missing blank lines
    local line_num=0
    local prev_line=""
    local prev_was_comment=false

    while IFS= read -r line; do
        ((line_num++))
        local current_is_comment=false
        [[ "$line" =~ ^[[:space:]]*//[^/] ]] && current_is_comment=true

        # Add blank line if needed
        if [[ "$prev_was_comment" == true ]] && [[ "$current_is_comment" == false ]] &&
           [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]*// ]]; then
            if [[ -n "$prev_line" ]] && [[ ! "$prev_line" =~ ^[[:space:]]*$ ]]; then
                echo ""
                ((fixes++))
                [[ "$dry_run" == true ]] && echo "  Would add blank line before code" >&2
            fi
        fi

        echo "$line"
        prev_line="$line"
        prev_was_comment=$current_is_comment
    done < "$temp1" > "$temp2"

    # Apply changes
    if [[ "$dry_run" == true ]]; then
        echo "  Would apply $fixes fix(es)"
        rm -f "$temp1" "$temp2"
    else
        mv "$temp2" "$file_path"
        rm -f "$temp1"
        echo "  Applied $fixes fix(es)"
    fi

    return $fixes
}

# Main execution
total_fixes=0
files_processed=0

if [[ -f "$target" ]]; then
    fix_file "$target"
    total_fixes=$?
    files_processed=1
elif [[ -d "$target" ]]; then
    echo "Scanning directory: $target"
    for dart_file in $(find "$target" -name "*.dart" ! -name "*.g.dart" 2>/dev/null); do
        if [[ -f "$dart_file" ]]; then
            fix_file "$dart_file"
            file_fixes=$?
            total_fixes=$((total_fixes + file_fixes))
            ((files_processed++))
        fi
    done
else
    echo "Error: Target '$target' not found"
    exit 1
fi

echo ""
echo "Summary:"
echo "========"
echo "Files processed: $files_processed"
if [[ "$dry_run" == true ]]; then
    echo "Fixes that would be applied: $total_fixes"
    echo ""
    echo "Run without --dry-run to apply fixes"
else
    echo "Fixes applied: $total_fixes"
    if [[ $total_fixes -gt 0 ]]; then
        echo ""
        echo "✓ Comment style violations have been automatically fixed!"
        echo "Review changes before committing."
    fi
fi