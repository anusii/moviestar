# Comment Linting

The MovieStar project uses the `comment_lint` package for enforcing
comment style guidelines in Dart/Flutter code. This package provides
both detection and automatic fixing of comment style violations.

## Using the Comment Lint Package

The `comment_lint` package is included as a dev dependency and
provides command-line tools for comment style checking and fixing.

### Comment Linter (Detection)

**Purpose**: Detects comment style violations:

1. All single-line comments (`//`) must end with a period (`.`),
   question mark (`?`), or exclamation mark (`!`)

2. All doc comments (`///`) must end with a period (`.`), question
   mark (`?`), or exclamation mark (`!`)

3. Comments must have a blank line between the comment and the
   following code

**Usage**:

```bash
# Check a single file
dart run comment_lint --check path/to/file.dart

# Check entire lib directory (default behavior)
dart run comment_lint --check lib/

# Check with verbose output for debugging
dart run comment_lint --check --verbose lib/
```

### Comment Auto-Fix (Repair)

**Purpose**: Automatically fixes comment style violations:

1. Adds periods to single-line comments (`//`) missing them

2. Adds periods to doc comments (`///`) missing them

3. Adds blank lines between comments and code

**Usage**:

```bash
# Fix a single file (with preview)
dart run comment_lint --dry-run path/to/file.dart

# Fix a single file (apply changes)
dart run comment_lint path/to/file.dart

# Fix entire lib directory (dry-run first!)
dart run comment_lint --dry-run lib/

# Fix entire lib directory (apply changes)
dart run comment_lint lib/
```

**Features**:

- ✅ Detects single-line comments (`//`) missing punctuation
- ✅ Detects doc comments (`///`) missing punctuation
- ✅ Detects missing blank lines after comments
- ✅ Ignores TODO/FIXME/NOTE comments
- ✅ Ignores GPL license headers and copyright statements
- ✅ Ignores timestamp and URL comments
- ✅ Skips generated files (*.g.dart)
- ✅ Cross-platform support (Windows/macOS/Linux)
- ✅ Automatic Git Bash detection on Windows
- ✅ Dry-run mode for safe preview
- ✅ Preserves original indentation and formatting
- ✅ Safe for batch processing
- ✅ Provides detailed line-by-line reporting

## Example Output

**Checking for violations**:

```bash
$ dart run comment_lint --check lib/

Comment Linter
==============
Target: C:/Users/user/project/lib/

Scanning directory: C:/Users/user/project/lib/
Checking: C:/Users/user/project/lib/main.dart
  Line 17: Comment missing period:   // This comment is missing a period
  Line 18: Missing blank line after comment
  Line 24: Comment missing period:   // Another comment missing a period
  Line 25: Missing blank line after comment
  Found 4 violation(s)

Checking: C:/Users/user/project/lib/utils.dart
  ✓ No violations found

Summary: 4 violation(s) in 2 file(s)
```

**Auto-fixing violations** (dry-run):

```bash
$ dart run comment_lint --dry-run lib/

Comment Auto-Fix
================
Target: C:/Users/user/project/lib/
Mode: DRY-RUN (no changes)

Processing: C:/Users/user/project/lib/main.dart
  Would add period to comment
  Would add blank line before code
  Would add period to comment
  Would add blank line before code
  Would apply 4 fix(es)

Summary:
========
Files processed: 1
Fixes that would be applied: 4

Run without --dry-run to apply fixes
```

## Integration

The comment_lint package can be integrated into:

- **Pre-commit hooks** - Prevent commits with comment style violations
- **CI/CD pipelines** - Fail builds on violations
- **Development workflow** - Regular style checks
- **IDE tasks** - Configure as custom tasks in VS Code, IntelliJ, etc.

**Example pre-commit hook**:

```bash
#!/bin/bash
# Check for comment style violations before commit
dart run comment_lint --check lib/ || {
    echo "❌ Comment style violations found. Please fix them before committing."
    echo "💡 Run: dart run comment_lint lib/ --dry-run  # to preview fixes"
    echo "💡 Run: dart run comment_lint lib/            # to apply fixes"
    exit 1
}
```

**Example CI/CD integration**:

```yaml
- name: Check comment style
  run: dart run comment_lint --check lib/
```

## Package Information

- **Repository**: [github](https://github.com/anusii/comment_lint.git)
- **Package**: `comment_lint` (Git dependency)
- **License**: GPL-3.0
- **Cross-platform**: Windows, macOS, Linux

## Implementation Notes

- Cross-platform Dart CLI with bash script core
- Automatic Git Bash detection on Windows with WSL fallback
- Intelligent comment parsing with regex patterns
- Handles Windows line endings properly
- Efficient single-pass file processing with performance optimizations
- Robust error handling for missing files/directories
- Package root detection for both development and dependency scenarios

---

*This addresses GitHub issue #230: "Add lint to ensure all comments
end in a fullstop and have blank line between comment and code"*
