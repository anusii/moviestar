#!/bin/bash
# Performance-Optimized Comment Auto-Fix Script for MovieStar Project
#
# Automatically fixes comment style violations:
# 1. Adds periods to comments missing them
# 2. Adds blank lines between comments and code

target="${1:-lib/}"
dry_run=false
[[ "$2" == "--dry-run" || "$1" == "--dry-run" ]] && dry_run=true

echo "MovieStar Comment Auto-Fix (Optimized)"
echo "======================================"
echo "Target: $target"
[[ "$dry_run" == true ]] && echo "Mode: DRY-RUN (no changes)" || echo "Mode: LIVE (files will be modified)"
echo ""

should_ignore_line() {
    local line="$1"

    # Skip empty comments (/// or // with no content)
    [[ "$line" =~ ^[[:space:]]*///[[:space:]]*$ ]] && return 0
    [[ "$line" =~ ^[[:space:]]*//[[:space:]]*$ ]] && return 0

    # Check if this is an uppercase header comment (e.g., "// MOVIE METHODS")
    local content="${line#*//}"
    [[ "$content" =~ ^/ ]] && content="${content#/}"
    content="${content# }"
    content="${content%$'\r'}"  # Strip Windows line endings

    # Skip if content is all uppercase letters and spaces (section headers)
    if [[ -n "$content" ]] && [[ "$content" =~ ^[A-Z][A-Z\ ]+$ ]]; then
        return 0
    fi

    case "$line" in
        *"// ignore:"*) return 0 ;;  # Skip Dart analyzer ignore directives
        *"TODO:"*|*"FIXME:"*|*"NOTE:"*|*"Time-stamp:"*|*"https://"*|*"http://"*) return 0 ;;
        *"This program is free software"*|*"the terms of the GNU General Public License"*) return 0 ;;
        *"Foundation, either version"*|*"This program is distributed in the hope"*) return 0 ;;
        *"ANY WARRANTY; without even the implied warranty"*|*"FOR A PARTICULAR PURPOSE"*) return 0 ;;
        *"You should have received a copy of the GNU General Public License"*) return 0 ;;
        *"version."*|*"details."*) return 0 ;;
        *"Copyright (C)"*|*"Licensed under the GNU General Public License"*|*"Authors:"*) return 0 ;;
        *"License:"*|*"this program"*|*"see <https://www.gnu.org/licenses/"*) return 0 ;;
    esac
    return 1
}

fix_file() {
    local file_path="$1"
    [[ "$file_path" =~ \.g\.dart$ ]] && return 0
    [[ ! -f "$file_path" ]] && return 0

    echo "Processing: $file_path"

    local fixes=0
    local prev_line=""
    local prev_was_comment=false
    local prev_was_ignore=false
    local output=""

    # Read file into array for lookahead capability
    mapfile -t lines < "$file_path"
    local total_lines=${#lines[@]}

    for ((i=0; i<total_lines; i++)); do
        local line="${lines[$i]}"
        local current_is_comment=false
        local processed_line="$line"
        local next_line=""

        # Get next line for continuation check (if exists)
        if [[ $((i+1)) -lt $total_lines ]]; then
            next_line="${lines[$((i+1))]}"
        fi

        # Check if current line is a comment and fix period if needed
        if [[ "$line" =~ ^[[:space:]]*// ]]; then
            current_is_comment=true

            # Check if this is an ignore directive
            local current_is_ignore=false
            if [[ "$line" =~ "// ignore:" ]]; then
                current_is_ignore=true
            fi

            # Fast content extraction using parameter expansion
            local content="${line#*//}"
            [[ "$content" =~ ^/ ]] && content="${content#/}"
            content="${content# }"

            # Strip Windows line endings
            content="${content%$'\r'}"

            # Check if this is an uppercase header (e.g., "MOVIE METHODS")
            # Must be ALL uppercase letters and spaces, no lowercase allowed
            # Require at least 2 characters total
            if [[ -n "$content" ]] && [[ ${#content} -ge 2 ]] && [[ "$content" =~ ^[A-Z][A-Z\ ]*[.]?$ ]] && [[ "$content" == "${content^^}" ]]; then
                # For uppercase headers, remove trailing period if present
                if [[ "$content" =~ [.]$ ]]; then
                    content="${content%\.}"
                    local original_content="${line#*//}"
                    [[ "$original_content" =~ ^/ ]] && original_content="${original_content#/}"
                    original_content="${original_content# }"
                    local prefix="${line%"$original_content"}"
                    processed_line="${prefix}${content}"
                    ((fixes++))
                    [[ "$dry_run" == true ]] && echo "  Would remove period from uppercase header" >&2
                fi
            elif ! should_ignore_line "$line"; then
                # Check if comment ends with : or , (list/continuation indicators)
                if [[ "$content" =~ [,:]$ ]]; then
                    # Don't add period for comments ending in : or ,
                    :
                # Check if next line is a continuation comment
                elif [[ -n "$next_line" ]] && [[ "$next_line" =~ ^[[:space:]]*// ]]; then
                    local next_content="${next_line#*//}"
                    [[ "$next_content" =~ ^/ ]] && next_content="${next_content#/}"
                    next_content="${next_content# }"
                    # If next comment starts with lowercase, number, or dash (list item), this is a multi-line comment
                    if [[ "$next_content" =~ ^[a-z0-9-] ]]; then
                        # Don't add period for continuation comments
                        :
                    elif [[ -n "$content" ]] && [[ ! "$content" =~ [.!?]$ ]]; then
                        # Add period for single-line comment
                        local original_content="${line#*//}"
                        [[ "$original_content" =~ ^/ ]] && original_content="${original_content#/}"
                        original_content="${original_content# }"
                        local prefix="${line%"$original_content"}"
                        processed_line="${prefix}${content}."
                        ((fixes++))
                        [[ "$dry_run" == true ]] && echo "  Would add period to comment" >&2
                    fi
                # For regular single-line comments, add period if missing
                elif [[ -n "$content" ]] && [[ ! "$content" =~ [.!?]$ ]]; then
                    local original_content="${line#*//}"
                    [[ "$original_content" =~ ^/ ]] && original_content="${original_content#/}"
                    original_content="${original_content# }"
                    local prefix="${line%"$original_content"}"
                    processed_line="${prefix}${content}."
                    ((fixes++))
                    [[ "$dry_run" == true ]] && echo "  Would add period to comment" >&2
                fi
            fi
        fi

        # Add blank line if needed (between previous comment and current non-comment)
        # BUT NOT after ignore directives
        if [[ "$prev_was_comment" == true ]] && [[ "$prev_was_ignore" == false ]] &&
           [[ "$current_is_comment" == false ]] &&
           [[ -n "$processed_line" ]] && [[ ! "$processed_line" =~ ^[[:space:]]*$ ]] &&
           [[ ! "$processed_line" =~ ^[[:space:]]*// ]]; then
            if [[ -n "$prev_line" ]] && [[ ! "$prev_line" =~ ^[[:space:]]*$ ]]; then
                output+=$'\n'
                ((fixes++))
                [[ "$dry_run" == true ]] && echo "  Would add blank line before code" >&2
            fi
        fi

        output+="$processed_line"$'\n'
        prev_line="$processed_line"
        prev_was_comment=$current_is_comment
        prev_was_ignore=$current_is_ignore
    done

    # Apply changes
    if [[ "$dry_run" == true ]]; then
        echo "  Would apply $fixes fix(es)"
    else
        # Write directly to file in one operation
        echo -n "$output" > "$file_path"
        echo "  Applied $fixes fix(es)"
    fi

    return $fixes
}

# Main execution - use faster for loop instead of pipeline
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