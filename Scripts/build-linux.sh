#!/usr/bin/env bash
# Scripts/build-linux.sh
# Build script for RepoBar on Linux
#
# This script attempts to build RepoBar on Linux and provides helpful
# error messages and diagnostics when things fail.

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if we're on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    error "This script is for Linux builds only"
    exit 1
fi

info "RepoBar Linux Build Script"
echo ""

# Check Swift version
info "Checking Swift version..."
if ! command -v swift &> /dev/null; then
    error "Swift is not installed"
    echo "  Please install Swift 6.2 or later from https://swift.org"
    exit 1
fi

SWIFT_VERSION=$(swift --version | head -n1)
info "Found: $SWIFT_VERSION"

if [[ ! "$SWIFT_VERSION" =~ "Swift version 6.2" ]] && [[ ! "$SWIFT_VERSION" =~ "Swift version 6.3" ]]; then
    warning "Swift 6.2+ is recommended. You have: $SWIFT_VERSION"
    echo "  Some features may not work correctly"
fi
echo ""

# Check for required dependencies
info "Checking system dependencies..."

MISSING_DEPS=()

if ! pkg-config --exists dbus-1 2>/dev/null; then
    MISSING_DEPS+=("libdbus-1-dev")
fi

if ! pkg-config --exists ncurses 2>/dev/null; then
    MISSING_DEPS+=("libncurses-dev")
fi

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    warning "Missing recommended dependencies:"
    for dep in "${MISSING_DEPS[@]}"; do
        echo "  - $dep"
    done
    echo ""
    echo "Install with:"
    echo "  sudo apt install ${MISSING_DEPS[*]}  # Debian/Ubuntu"
    echo "  or"
    echo "  sudo dnf install ${MISSING_DEPS[*]//lib/}  # Fedora"
    echo ""
fi

# Explain current limitations
info "Current Linux port status:"
echo ""
warning "⚠️  LINUX PORT IS WORK IN PROGRESS ⚠️"
echo ""
echo "Known issues:"
echo "  1. apollo-ios dependency doesn't support Linux (missing FoundationNetworking imports)"
echo "  2. RepoBarCore cannot build due to apollo-ios issue"
echo "  3. Main app uses macOS-only frameworks (AppKit, MenuBarExtra)"
echo ""
echo "What this means:"
echo "  - Full build will fail"
echo "  - We're documenting the port process"
echo "  - See docs/building-linux.md for details"
echo ""

# Ask if user wants to continue
read -p "Continue with build attempt anyway? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Build cancelled"
    exit 0
fi

# Try to build RepoBarCore
info "Attempting to build RepoBarCore..."
echo ""

BUILD_OUTPUT=$(mktemp)
if swift build --target RepoBarCore 2>&1 | tee "$BUILD_OUTPUT"; then
    success "RepoBarCore built successfully!"
    echo ""
    info "This is unexpected - apollo-ios must have been fixed!"
    info "Please report this success to the project maintainers"
else
    BUILD_EXIT_CODE=$?
    error "RepoBarCore build failed (exit code: $BUILD_EXIT_CODE)"
    echo ""
    
    # Check for known errors
    if grep -q "FoundationNetworking" "$BUILD_OUTPUT"; then
        warning "Found FoundationNetworking errors (expected)"
        echo ""
        echo "This is a known issue with apollo-ios on Linux."
        echo ""
        echo "To fix this:"
        echo "  1. Fork apollo-ios"
        echo "  2. Add 'import FoundationNetworking' to affected files"
        echo "  3. Update Package.swift to use your fork"
        echo ""
        echo "Or wait for upstream apollo-ios to add Linux support."
        echo ""
        echo "See docs/building-linux.md for more details."
    fi
    
    if grep -q "cannot find type 'URLRequest'" "$BUILD_OUTPUT"; then
        warning "Found URLRequest errors (expected)"
        echo ""
        echo "These types require 'import FoundationNetworking' on Linux."
        echo "See apollo-ios issue tracker for updates."
    fi
fi

rm -f "$BUILD_OUTPUT"
echo ""

# Summary
info "Build Summary"
echo ""
echo "Platform: $(uname -s) $(uname -m)"
echo "Swift: $SWIFT_VERSION"
echo "Distribution: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
echo ""

info "Next Steps"
echo ""
echo "1. Read docs/building-linux.md for current status"
echo "2. Read docs/linux-port.md for implementation plan"
echo "3. Help fix apollo-ios for Linux support"
echo "4. Contribute to platform abstraction layer"
echo ""

info "Resources"
echo ""
echo "  - Linux port doc: docs/linux-port.md"
echo "  - Build guide: docs/building-linux.md"
echo "  - apollo-ios: https://github.com/apollographql/apollo-ios"
echo ""
