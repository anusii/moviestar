#!/bin/bash
# Test on just test file and one lib file

echo "🧹 Testing on specific files"

files=(
    "test_cleanup.dart"
    "lib/main.dart"
)

files_processed=0
files_modified=0
print_statements_removed=0

for file in "${files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Skipping $file (not found)"
        continue
    fi

    echo "Processing: $file"
    ((files_processed++))

    # Check for print statements
    if grep -q "print\s*(" "$file"; then
        print_count=$(grep -c "print\s*(" "$file" || echo 0)
        ((print_statements_removed += print_count))
        ((files_modified++))
        echo "  Would remove $print_count print statements"
    fi
done

echo ""
echo "Results:"
echo "  Files processed: $files_processed"
echo "  Files modified: $files_modified"
echo "  Print statements found: $print_statements_removed"