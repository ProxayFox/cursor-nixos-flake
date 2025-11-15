#!/usr/bin/env bash

# Simple script to update Cursor version in a package-only flake
# Now with automatic link finding!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 1. CHECK DEPENDENCIES
# ------------------------------------------------
check_deps() {
    print_info "Checking for required tools..."
    local missing=0
    for tool in curl nix-prefetch-url sed grep; do
        if ! command -v "$tool" &> /dev/null; then
            print_error "Required tool '$tool' is not installed."
            missing=1
        fi
    done

    if [[ "$missing" -eq 1 ]]; then
        print_error "Please install missing tools to continue."
        print_info "You may be able to install them with: nix-shell -p curl nix"
        exit 1
    fi
    print_success "All required tools found."
}
check_deps
echo ""

# 2. CHECK DIRECTORY
# ------------------------------------------------
if [[ ! -f "flake.nix" ]]; then
    print_error "This script must be run from the cursor-flake directory"
    exit 1
fi

print_info "Cursor Package Flake Updater"
echo ""

# 3. GET CURRENT VALUES
# ------------------------------------------------
CURRENT_VERSION=$(grep -o 'version = "[^"]*"' flake.nix | head -1 | sed 's/version = "//;s/"//')
CURRENT_URL=$(grep -o 'https://downloads[.]cursor[.]com/[^"]*' flake.nix | head -1)
CURRENT_HASH=$(grep -o 'sha256 = "[^"]*"' flake.nix | head -1 | sed 's/sha256 = "//;s/"//')

print_info "Current version: ${CURRENT_VERSION:-unknown}"
print_info "Current URL: $CURRENT_URL"
echo ""

# 4. FIND LATEST URL (AUTOMATIC)
# ------------------------------------------------
print_info "Finding latest AppImage URL from https://cursor.com/download..."

# The download page now uses API URLs that redirect to the actual AppImage
# First, get the API URL from the download page
API_URL=$(curl -s https://cursor.com/download | \
          grep -o 'https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/[^"]*' | \
          head -n 1)

if [[ -z "$API_URL" ]]; then
    print_error "Could not find API download URL on the download page."
    print_error "The website structure may have changed."
    exit 1
fi

print_info "Found API URL: $API_URL"

# Follow the redirect to get the actual AppImage URL with version number
NEW_URL=$(curl -sIL "$API_URL" | grep -i "^location:" | tail -n 1 | sed 's/location: //i' | tr -d '\r\n')

if [[ -z "$NEW_URL" ]]; then
    print_error "Could not follow redirect to find actual AppImage URL."
    print_error "The API endpoint may have changed."
    exit 1
fi

print_success "Found latest URL: $NEW_URL"

# Check if it's actually a new URL
if [[ "$NEW_URL" == "$CURRENT_URL" ]]; then
    print_success "You are already on the latest version ($CURRENT_VERSION)."
    print_info "No update needed."
    exit 0
fi

# Extract version from URL (e.g., .../Cursor-2.0.34-x86_64.AppImage -> 2.0.34)
NEW_VERSION=$(echo "$NEW_URL" | sed -n 's/.*Cursor-\(.*\)-x86_64\.AppImage/\1/p')

if [[ -z "$NEW_VERSION" ]]; then
    print_warning "Could not automatically determine new version from URL."
    print_warning "The file name format may have changed."
    # Fallback: ask user
    read -p "Please enter the new version number: " NEW_VERSION
    if [[ -z "$NEW_VERSION" ]]; then
        print_error "Version number is required."
        exit 1
    fi
fi

print_info "New version: $NEW_VERSION"
echo ""

# 5. GET HASH
# ------------------------------------------------
print_info "Fetching SHA256 hash..."
HASH=$(nix-prefetch-url "$NEW_URL")

if [[ -z "$HASH" ]]; then
    print_error "Failed to get hash for $NEW_URL"
    exit 1
fi

print_success "SHA256 hash: $HASH"
echo ""

# 6. UPDATE FLAKE.NIX
# ------------------------------------------------
print_info "Updating flake.nix..."

# Update version
sed -i "s|version = \"[^\"]*\";|version = \"$NEW_VERSION\";|" flake.nix
print_success "Updated version"

# Update URL
sed -i "s|$CURRENT_URL|$NEW_URL|g" flake.nix
print_success "Updated URL"

# Update hash
sed -i "s|sha256 = \"$CURRENT_HASH\";|sha256 = \"$HASH\";|" flake.nix
print_success "Updated hash"

# 7. TEST BUILD
# ------------------------------------------------
print_info "Testing build..."
if nix build .#cursor; then
    print_success "Build successful!"
    
    if [[ -x "./result/bin/cursor" ]]; then
        BUILT_VERSION=$(./result/bin/cursor --version 2>/dev/null || echo "unknown")
        print_info "Built version: $BUILT_VERSION"
        
        if [[ "$BUILT_VERSION" == "$NEW_VERSION" ]]; then
            print_success "Version verification passed!"
        else
            print_warning "Version mismatch: expected $NEW_VERSION, got $BUILT_VERSION"
        fi
        
        # Check that icon and desktop entry were installed
        if [[ -f "./result/share/pixmaps/cursor.png" ]]; then
            print_success "Icon successfully extracted and installed!"
        else
            print_warning "Icon not found - might not display properly in desktop"
        fi
        
        if [[ -f "./result/share/applications/cursor.desktop" ]]; then
            print_success "Desktop entry created!"
        else
            print_warning "Desktop entry not found"
        fi
    fi
else
    print_error "Build failed!"
    print_info "Reverting changes to flake.nix..."
    # Simple git revert
    git checkout -- flake.nix
    print_success "flake.nix reverted."
    exit 1
fi

echo ""
print_info "Package updated successfully!"
print_info "To use in your system: rebuild your main NixOS configuration"
print_success "Update complete!"