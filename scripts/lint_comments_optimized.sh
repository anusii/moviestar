#!/bin/bash
# Performance-Optimized Comment Linter

target="${1:-lib/}"
violations=0
files_checked=0

echo "MovieStar Comment Linter (Optimized)"
echo "===================================="
echo "Target: $target"
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

lint_file() {
    local file_path="$1"
    [[ "$file_path" =~ \.g\.dart$ ]] && return 0
    [[ ! -f "$file_path" ]] && return 0

    echo "Checking: $file_path"
    ((files_checked++))

    local file_violations=0
    local line_num=1
    local prev_line=""
    local prev_was_comment=false
    local prev_was_ignore=false

    while IFS= read -r line; do
        local is_comment=false

        # Optimized comment detection - check // first, then ///
        if [[ "$line" =~ ^[[:space:]]*// ]]; then
            is_comment=true

            # Check if this is an ignore directive
            if [[ "$line" =~ "// ignore:" ]]; then
                prev_was_ignore=true
            else
                prev_was_ignore=false
            fi

            # Extract comment content for checking
            local content="${line#*//}"
            [[ "$content" =~ ^/ ]] && content="${content#/}"
            content="${content# }"
            # Strip Windows line endings for consistent checking
            content="${content%$'\r'}"

            # Check if this is an uppercase header (with or without period)
            # Must be ALL uppercase letters and spaces, no lowercase allowed
            # Require at least 2 characters total
            if [[ -n "$content" ]] && [[ ${#content} -ge 2 ]] && [[ "$content" =~ ^[A-Z][A-Z\ ]*[.]?$ ]] && [[ "$content" == "${content^^}" ]]; then
                # For uppercase headers, check they DON'T have a period
                if [[ "$content" =~ [.]$ ]]; then
                    echo "  Line $line_num: Uppercase header should not have period: $line"
                    ((file_violations++))
                fi
            elif ! should_ignore_line "$line"; then
                # For regular comments, check for missing period
                if [[ -n "$content" ]] && [[ ! "$content" =~ [.!?]$ ]]; then
                    echo "  Line $line_num: Comment missing period: $line"
                    ((file_violations++))
                fi
            fi
            prev_was_comment=true
        else
            # Check for missing blank line after comment (but NOT after ignore directives)
            if [[ "$prev_was_comment" == true ]] && [[ "$prev_was_ignore" == false ]] &&
               [[ -n "$line" ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]] &&
               [[ ! "$line" =~ ^[[:space:]]*// ]]; then
                if [[ -n "$prev_line" ]] && [[ ! "$prev_line" =~ ^[[:space:]]*$ ]]; then
                    echo "  Line $line_num: Missing blank line after comment"
                    ((file_violations++))
                fi
            fi
            prev_was_comment=false
            prev_was_ignore=false
        fi

        prev_line="$line"
        ((line_num++))
    done < "$file_path"

    violations=$((violations + file_violations))

    if [[ $file_violations -eq 0 ]]; then
        echo "  ✓ No violations found"
    else
        echo "  Found $file_violations violation(s)"
    fi
}

# Process target - use faster for loop instead of pipeline
if [[ -f "$target" ]]; then
    lint_file "$target"
elif [[ -d "$target" ]]; then
    echo "Scanning directory: $target"
    for dart_file in $(find "$target" -name "*.dart" ! -name "*.g.dart" 2>/dev/null); do
        [[ -f "$dart_file" ]] && lint_file "$dart_file"
    done
else
    echo "Error: Target not found"
    exit 1
fi

echo ""
echo "Summary: $violations violation(s) in $files_checked file(s)"
[[ $violations -eq 0 ]] && exit 0 || exit 1