#!/usr/bin/env bash

# Local test script for the GitHub Actions workflow
# This simulates what the workflow does without needing GitHub Actions

set -e

echo "========================================="
echo "Testing Update Cursor Workflow Locally"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Step 1: Check we're in the right directory
print_step "Checking repository..."
if [[ ! -f "flake.nix" ]] || [[ ! -f "update-cursor.sh" ]]; then
    echo "Error: Must be run from the repository root"
    exit 1
fi
print_success "Repository check passed"
echo ""

# Step 2: Check dependencies
print_step "Checking dependencies (like the workflow does)..."
missing=0
for tool in curl htmlq rg nix-prefetch-url sed grep nix; do
    if ! command -v "$tool" &> /dev/null; then
        echo "  ❌ Missing: $tool"
        missing=1
    else
        echo "  ✓ Found: $tool"
    fi
done

if [[ "$missing" -eq 1 ]]; then
    echo ""
    print_warning "Some dependencies are missing. Install with:"
    echo "  nix-env -iA nixpkgs.curl nixpkgs.htmlq nixpkgs.ripgrep"
    exit 1
fi
print_success "All dependencies found"
echo ""

# Step 3: Save current state
print_step "Saving current flake.nix state..."
cp flake.nix flake.nix.backup
ORIGINAL_VERSION=$(grep -o 'version = "[^"]*"' flake.nix | head -1 | sed 's/version = "//;s/"//')
print_success "Backed up (current version: $ORIGINAL_VERSION)"
echo ""

# Step 4: Run the update script
print_step "Running update-cursor.sh..."
echo ""
if ./update-cursor.sh; then
    UPDATE_SUCCESS=true
else
    UPDATE_SUCCESS=false
fi
echo ""

# Step 5: Check for changes
print_step "Checking for changes..."
if diff -q flake.nix flake.nix.backup > /dev/null 2>&1; then
    print_success "No changes (already on latest version)"
    CHANGED=false
else
    NEW_VERSION=$(grep -o 'version = "[^"]*"' flake.nix | head -1 | sed 's/version = "//;s/"//')
    print_success "Changes detected! Version: $ORIGINAL_VERSION → $NEW_VERSION"
    CHANGED=true
fi
echo ""

# Step 6: Show what would be committed
if [[ "$CHANGED" == true ]]; then
    print_step "Changes that would be committed:"
    echo ""
    git diff flake.nix | head -n 50
    echo ""
fi

# Step 7: Restore original state
print_step "Restoring original flake.nix..."
mv flake.nix.backup flake.nix
print_success "Restored to original state"
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Update script: $([ "$UPDATE_SUCCESS" == true ] && echo "✓ Success" || echo "✗ Failed")"
echo "Changes detected: $([ "$CHANGED" == true ] && echo "Yes" || echo "No")"
echo "Workflow simulation: ✓ Complete"
echo ""
echo "The workflow would:"
if [[ "$CHANGED" == true ]]; then
    echo "  1. Update flake.nix"
    echo "  2. Commit with message: 'chore: update Cursor to version $NEW_VERSION'"
    echo "  3. Push to GitHub"
    echo "  4. Create release: v$NEW_VERSION"
else
    echo "  - Do nothing (no changes needed)"
fi
echo ""
print_success "Local test complete! Original state restored."

