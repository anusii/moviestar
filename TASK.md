# Task: Fix Markdown Linting and Split Large Documentation Files

## Status

**Branch:** `atangster/308_update_docs`

**Current State:** Documentation reorganized, but needs lint compliance and
file size optimization

## Problem

The new integration test documentation has:

1. **Markdown linting violations** (~100+ issues across files)
   - Missing blank lines around code blocks (MD031)
   - Missing blank lines around lists (MD032)
   - Code blocks without language tags (MD040)
   - Lines exceeding 80 characters (MD013)
   - Bold text used as headings (MD036)

2. **Files exceeding 300-line guideline**
   - testing-guide.md: 507 lines
   - adapting.md: 523 lines
   - architecture.md: 466 lines
   - json-files.md: 326 lines (acceptable, cohesive reference)

## Solution: Full Recreation with Lint Compliance

Create new, lint-compliant versions of all documentation files rather than
manually fixing violations.

### Lint-Compliant Template

All files will follow:

```markdown
# Title

> Brief intro paragraph wrapped at 80 chars

## Section Heading

Paragraph text properly wrapped at 80 character maximum for
readability and lint compliance.

List with proper spacing:

+ First item
+ Second item

Code block with language tag and spacing:

​```bash
command here
​```

Next paragraph continues.
```

### Files to Create/Fix (10 total)

#### Group 1: Split testing-guide.md (507 → 280 + 220)

**1. testing-guide.md** (280 lines)

+ Content: Overview, test types, running tests, writing tests, POD auth
+ Sections: Test Types, Running Tests, Writing Tests, POD Authentication,
  Best Practices
+ Code blocks: ~15 (all with language tags: bash, dart, json)
+ Lists: All with blank lines before/after

**2. testing-troubleshooting.md** (220 lines) - NEW FILE

+ Content: Complete troubleshooting section from original
+ Sections: Test Discovery, Invalid Grant, Visual Delays, Batch Failures,
  Device Errors, Browser Automation Issues
+ Code blocks: ~12 (bash, dart)
+ Cross-ref: Links to testing-guide.md

#### Group 2: Split adapting.md (523 → 200 + 150 + 150)

**3. adapting.md** (200 lines)

+ Content: Quick start, reusable components, configuration, writing tests
+ Sections: Checklist, Reusable Components, Configuration Changes,
  Writing Tests
+ Code blocks: ~10 (dart, bash, json)
+ Checklists: Use proper ## headings

**4. adapting-providers.md** (150 lines) - NEW FILE

+ Content: POD provider compatibility (CSS, NSS, ESS)
+ Sections: Supported Providers, Provider-Specific Considerations,
  Troubleshooting
+ Code blocks: ~8 (dart selectors)
+ Tables: Provider comparison table

**5. adapting-cicd.md** (150 lines) - NEW FILE

+ Content: CI/CD integration, GitHub Actions, credentials
+ Sections: GitHub Actions Example, Storing Credentials, Migration Checklist
+ Code blocks: ~6 (yaml, bash)
+ All properly tagged and spaced

#### Group 3: Split architecture.md (466 → 240 + 200)

**6. architecture.md** (240 lines)

+ Content: Component overview, responsibilities, structure, integration
+ Sections: Component Overview, Responsibilities, Directory Structure,
  Integration Points
+ Mermaid: 1 component diagram
+ Code blocks: ~8 (dart)

**7. architecture-flows.md** (200 lines) - NEW FILE

+ Content: Test execution flows, timing, errors, performance
+ Sections: Execution Flows (fresh tokens, expired + regen), Timing,
  Error Handling, Performance
+ Mermaid: 2 sequence diagrams
+ Code blocks: ~6 (dart)

#### Group 4: Fix Existing Files (3 files)

**8. authentication.md** (244 → ~250 lines)

+ Fix: Add blank lines around 15 code blocks
+ Fix: Add language tags (bash, dart, json, text)
+ Fix: Wrap 5 long lines
+ Keep: Both Mermaid diagrams

**9. json-files.md** (326 → ~280 lines)

+ Fix: Add blank lines around 20 code blocks
+ Fix: Add language tags (json, bash, dart)
+ Fix: Wrap 8 long lines
+ Optimize: Condense verbose examples slightly

**10. setup-guide.md** (289 → ~270 lines)

+ Fix: Add blank lines around 10 code blocks
+ Fix: Add language tags (bash, yaml, dart)
+ Fix: Wrap 3 long lines
+ Keep: Platform-specific sections

### Quality Assurance Checklist

For each file created:

+ [ ] Line count < 300
+ [ ] All code blocks have language tags (bash, dart, json, yaml, text)
+ [ ] Blank lines before/after all code blocks
+ [ ] Blank lines before/after all lists
+ [ ] No lines exceed 80 characters
+ [ ] Proper heading hierarchy (##, ###, no bold-as-heading)
+ [ ] Consistent list style (+ for unordered lists)
+ [ ] Working cross-references
+ [ ] Mermaid diagrams render correctly
+ [ ] Content preserved from original

## Execution Plan

### Phase 1: Create Split Files (4 new files)

Easiest to create from scratch, no legacy content:

1. testing-troubleshooting.md (220 lines)
2. adapting-providers.md (150 lines)
3. adapting-cicd.md (150 lines)
4. architecture-flows.md (200 lines)

### Phase 2: Recreate Main Files (3 files)

Clean slate, more content:

1. testing-guide.md (280 lines)
2. adapting.md (200 lines)
3. architecture.md (240 lines)

### Phase 3: Fix Existing Files (3 files)

Targeted edits for lint compliance:

1. authentication.md (~250 lines)
2. json-files.md (~280 lines)
3. setup-guide.md (~270 lines)

### Phase 4: Update Navigation

1. Update integration_test/docs/README.md
   - Add links to 4 new split files
   - Update file list in directory structure

2. Update cross-references in all files
   - Update links to split content
   - Add "See also" sections

### Phase 5: Validate

```bash
# Check line counts
wc -l integration_test/docs/*.md

# Run markdown linting
markdownlint integration_test/docs/*.md

# Expected: 0 errors
```

## Expected Results

After completion:

+ All documentation files pass markdownlint (0 errors)
+ All files under 300 lines
+ All content preserved from original documentation
+ Better organization with focused, single-purpose files
+ Improved navigability with clear cross-references
+ CI markdown lint check will pass

## Estimated Effort

+ **Token usage:** ~40-50k tokens (recreating ~2500 lines of documentation)
+ **Time:** 1-2 hours of processing
+ **Files changed:** 10 files (4 new, 3 recreated, 3 fixed)
+ **Lines added:** ~2500 lines of lint-compliant markdown

## Notes

+ This is a substantial refactoring of documentation
+ Approach: "Clean slate" creation rather than manual fixing
+ Benefit: Guaranteed lint compliance from the start
+ Trade-off: Time investment vs quality improvement

## Tracking

Created: 2025-11-12

Branch: atangster/308_update_docs

Related commits:

+ `257b125` - Reorganize and expand integration test documentation
+ `439ce55` - Fix markdown linting issues and add link checker ignore
