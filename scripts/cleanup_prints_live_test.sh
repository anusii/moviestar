#!/bin/bash
# Live test of print cleanup on one file

echo "🧹 Live Test: Print Statement Cleanup"
echo ""

# Test on just one file first
test_file="lib/utils/network_client.dart"

echo "Testing on: $test_file"

if [ ! -f "$test_file" ]; then
    echo "File not found!"
    exit 1
fi

# Count before
print_before=$(grep -c "print(" "$test_file" 2>/dev/null || echo 0)
echo "Print statements before: $print_before"

if [ $print_before -eq 0 ]; then
    echo "No print statements to remove!"
    exit 0
fi

echo ""
echo "Print statements that will be removed:"
grep -n "print(" "$test_file" | sed 's/^/  /'

echo ""
read -p "Proceed with cleanup? (y/N): " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled."
    exit 0
fi

# Create backup
mkdir -p scripts/backups
backup_file="scripts/backups/$(basename "$test_file")_$(date +%s).backup"
cp "$test_file" "$backup_file"
echo "✓ Backup created: $backup_file"

# Perform cleanup using sed
sed -i '/print(/d' "$test_file"

# Check after
print_after=$(grep -c "print(" "$test_file" 2>/dev/null || echo 0)
echo "✓ Print statements after: $print_after"

echo ""
echo "📊 Results:"
echo "  Removed: $((print_before - print_after)) print statements"
echo "  Backup: $backup_file"

if [ $print_after -eq 0 ]; then
    echo "🎉 All print statements successfully removed!"
else
    echo "⚠️  Some print statements remain (possibly multi-line)"
fi