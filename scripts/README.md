# Comment Linting Scripts

This directory contains scripts for enforcing comment style guidelines in the MovieStar Flutter project.

## Scripts

### `lint_comments.sh` - Comment Linter (Detection)

**Purpose**: Detects comment style violations:
1. All single-line comments (`//`) must end with a period (`.`), question mark (`?`), or exclamation mark (`!`)
2. All doc comments (`///`) must end with a period (`.`), question mark (`?`), or exclamation mark (`!`)
3. Comments must have a blank line between the comment and the following code

**Usage**:
```bash
# Check a single file
./scripts/lint_comments.sh path/to/file.dart

# Check entire lib directory
./scripts/lint_comments.sh lib/

# Default (checks lib/ directory)
./scripts/lint_comments.sh
```

**Features**:
- ✅ Detects single-line comments (`//`) missing punctuation
- ✅ Detects doc comments (`///`) missing punctuation
- ✅ Detects missing blank lines after comments
- ✅ Ignores TODO/FIXME/NOTE comments
- ✅ Ignores GPL license headers and copyright statements
- ✅ Ignores timestamp and URL comments
- ✅ Skips generated files (*.g.dart)
- ✅ Works on Windows/MinGW environments
- ✅ Provides detailed line-by-line reporting

**Current Status**:
- **Enhanced detection** now includes doc comments (`///`) in addition to single-line comments (`//`)
- GPL license headers and copyright statements properly ignored
- Script exits with code 1 if violations found, 0 if clean
- Ready to detect additional violations with doc comment support

### `fix_comments.sh` - Comment Auto-Fix (Repair)

**Purpose**: Automatically fixes comment style violations:
1. Adds periods to single-line comments (`//`) missing them
2. Adds periods to doc comments (`///`) missing them
3. Adds blank lines between comments and code

**Usage**:
```bash
# Fix a single file (with preview)
./scripts/fix_comments.sh path/to/file.dart --dry-run

# Fix a single file (apply changes)
./scripts/fix_comments.sh path/to/file.dart

# Fix entire lib directory (dry-run first!)
./scripts/fix_comments.sh lib/ --dry-run

# Fix entire lib directory (apply changes)
./scripts/fix_comments.sh lib/
```

**Features**:
- ✅ Automatically adds missing periods to single-line comments (`//`)
- ✅ Automatically adds missing periods to doc comments (`///`)
- ✅ Automatically adds missing blank lines after comments
- ✅ Dry-run mode for safe preview
- ✅ Same ignore rules as linter (TODO/GPL/URLs/etc)
- ✅ Preserves original indentation and formatting
- ✅ Creates backup during processing
- ✅ Safe for batch processing

**Example**:
```bash
$ ./scripts/fix_comments.sh test_file.dart --dry-run

MovieStar Comment Auto-Fix
==========================
Target: test_file.dart
Mode: DRY-RUN (no changes)

Processing: test_file.dart
  Would apply 17 fix(es)

Summary:
========
Files processed: 1
Fixes that would be applied: 17

Run without --dry-run to apply fixes
```

## Example Output

```bash
$ ./scripts/lint_comments.sh test_comment_violations.dart

MovieStar Comment Linter
=======================
Target: test_comment_violations.dart

Checking: test_comment_violations.dart
  Line 17: Comment missing period:   // This comment is missing a period
  Line 18: Missing blank line after comment
  Line 24: Comment missing period:   // This comment is missing a period and no blank line
  Line 25: Missing blank line after comment
  Found 4 violation(s)

Summary: 4 violation(s) in 1 file(s)
```

## Integration

This script can be integrated into:
- **Pre-commit hooks** - Prevent commits with comment style violations
- **CI/CD pipelines** - Fail builds on violations
- **Development workflow** - Regular style checks

## Test Files

- `test_comment_violations.dart` - Contains various comment violations for testing the script
- Script correctly identifies all expected violations (17 violations in the test file)

## Implementation Notes

- Uses bash regex patterns for comment detection
- Handles Windows line endings properly
- Efficient single-pass file processing
- Robust error handling for missing files/directories

---

*This script addresses GitHub issue #230: "Add lint to ensure all comments end in a fullstop and have blank line between comment and code"*