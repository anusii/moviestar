#!/bin/bash
# Working Comment Linter - Simple version

target="${1:-lib/}"
violations=0
files_checked=0

echo "MovieStar Comment Linter"
echo "======================="
echo "Target: $target"
echo ""

should_ignore_line() {
    local line="$1"

    # Skip TODO/FIXME/NOTE comments, timestamps, and URLs
    [[ "$line" =~ (TODO|FIXME|NOTE|Time-stamp|https?://) ]] && return 0

    # Skip empty comments
    [[ "$line" =~ ^[[:space:]]*//[[:space:]]*$ ]] && return 0

    # Skip GPL license header comments
    [[ "$line" =~ "This program is free software" ]] && return 0
    [[ "$line" =~ "the terms of the GNU General Public License" ]] && return 0
    [[ "$line" =~ "Foundation, either version" ]] && return 0
    [[ "$line" =~ "This program is distributed in the hope" ]] && return 0
    [[ "$line" =~ "ANY WARRANTY; without even the implied warranty" ]] && return 0
    [[ "$line" =~ "FOR A PARTICULAR PURPOSE" ]] && return 0
    [[ "$line" =~ "You should have received a copy of the GNU General Public License" ]] && return 0
    [[ "$line" =~ "version\." ]] && return 0
    [[ "$line" =~ "details\." ]] && return 0

    # Skip common license/copyright doc comments
    [[ "$line" =~ "Copyright (C)" ]] && return 0
    [[ "$line" =~ "Licensed under the GNU General Public License" ]] && return 0
    [[ "$line" =~ "Authors:" ]] && return 0

    return 1
}

lint_single_file() {
    local file_path="$1"
    local file_violations=0

    [[ "$file_path" =~ \.g\.dart$ ]] && return 0

    echo "Checking: $file_path"
    ((files_checked++))

    local line_number=1
    local prev_line=""
    local prev_was_comment=false

    exec 3< "$file_path"
    while IFS= read -r line <&3; do
        if [[ "$line" =~ ^[[:space:]]*//[^/] ]] || [[ "$line" =~ ^[[:space:]]*///[[:space:]] ]]; then
            if ! should_ignore_line "$line"; then
                local comment_content
                comment_content=$(echo "$line" | sed 's/^[[:space:]]*\/\/\/\?[[:space:]]*//')
                if [[ ! "$comment_content" =~ [.!?]$ ]] && [[ -n "$comment_content" ]]; then
                    echo "  Line $line_number: Comment missing period: $line"
                    ((file_violations++))
                fi
            fi
            prev_was_comment=true
        else
            if [[ "$prev_was_comment" == true ]] && [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]] && [[ ! "$line" =~ ^[[:space:]]*//[/]? ]]; then
                if [[ -n "$prev_line" ]] && [[ ! "$prev_line" =~ ^[[:space:]]*$ ]]; then
                    echo "  Line $line_number: Missing blank line after comment"
                    ((file_violations++))
                fi
            fi
            prev_was_comment=false
        fi
        prev_line="$line"
        ((line_number++))
    done
    exec 3<&-

    violations=$((violations + file_violations))

    if [[ $file_violations -eq 0 ]]; then
        echo "  ✓ No violations found"
    else
        echo "  Found $file_violations violation(s)"
    fi
}

if [[ -f "$target" ]]; then
    lint_single_file "$target"
elif [[ -d "$target" ]]; then
    echo "Scanning directory: $target"
    for dart_file in $(find "$target" -name "*.dart" ! -name "*.g.dart" 2>/dev/null); do
        [[ -f "$dart_file" ]] && lint_single_file "$dart_file"
    done
else
    echo "Error: Target '$target' not found"
    exit 1
fi

echo ""
echo "Summary: $violations violation(s) in $files_checked file(s)"
[[ $violations -eq 0 ]] && exit 0 || exit 1