#!/bin/bash
# Build .deb package for Debian/Ubuntu/KDE Neon
# This script creates a Debian package for installation via dpkg or apt
#
# Prerequisites:
# - dpkg-deb must be installed
# - Swift toolchain must be available
# - repobar-linux must build successfully
#
# Usage:
#   ./Scripts/build-deb.sh [version]
#
# Arguments:
#   version - Package version (default: read from version.env)
#
# Output:
#   repobar_<version>_amd64.deb

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/deb"

# Get version from argument or version.env
if [ -n "${1:-}" ]; then
    VERSION="$1"
elif [ -f "$PROJECT_ROOT/version.env" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/version.env"
    VERSION="${VERSION:-0.1.0}"
else
    VERSION="0.1.0"
fi

PACKAGE_NAME="repobar_${VERSION}_amd64"
PACKAGE_DIR="$BUILD_DIR/$PACKAGE_NAME"

echo "🚀 Building RepoBar .deb package version $VERSION..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Step 1: Build repobar-linux in release mode
echo "📦 Building repobar-linux..."
cd "$PROJECT_ROOT"
swift build --product repobar-linux --configuration release

# Step 2: Create package directory structure
echo "📁 Creating package structure..."
mkdir -p "$PACKAGE_DIR/DEBIAN"
mkdir -p "$PACKAGE_DIR/usr/bin"
mkdir -p "$PACKAGE_DIR/usr/share/applications"
mkdir -p "$PACKAGE_DIR/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PACKAGE_DIR/usr/share/doc/repobar"

# Step 3: Copy executable
echo "📋 Copying executable..."
cp ".build/release/repobar-linux" "$PACKAGE_DIR/usr/bin/repobar"
chmod 755 "$PACKAGE_DIR/usr/bin/repobar"

# Step 4: Create control file
echo "📝 Creating control file..."
cat > "$PACKAGE_DIR/DEBIAN/control" << EOF
Package: repobar
Version: $VERSION
Architecture: amd64
Maintainer: RepoBar Team <contact@steipete.com>
Depends: libc6, libdbus-1-3
Recommends: libsecret-1-0 | kwalletmanager
Section: devel
Priority: optional
Homepage: https://github.com/steipete/RepoBar
Description: GitHub repository monitor for Linux
 RepoBar provides system tray integration for monitoring
 GitHub repositories on KDE Plasma and other Linux desktops.
 .
 Features:
  - System tray integration via StatusNotifierItem
  - Monitor CI/CD status, releases, and activity
  - OAuth authentication with GitHub
  - Secure token storage via KWallet or libsecret
  - Local Git repository integration
EOF

# Step 5: Create postinst script
echo "🔧 Creating postinst script..."
cat > "$PACKAGE_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e

# Update desktop database
if command -v update-desktop-database > /dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi

# Update icon cache
if command -v gtk-update-icon-cache > /dev/null 2>&1; then
    gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi

exit 0
EOF
chmod 755 "$PACKAGE_DIR/DEBIAN/postinst"

# Step 6: Create prerm script
echo "🔧 Creating prerm script..."
cat > "$PACKAGE_DIR/DEBIAN/prerm" << 'EOF'
#!/bin/bash
set -e

# Stop running instances
if command -v pkill > /dev/null 2>&1; then
    pkill -f repobar || true
fi

exit 0
EOF
chmod 755 "$PACKAGE_DIR/DEBIAN/prerm"

# Step 7: Create postrm script
echo "🔧 Creating postrm script..."
cat > "$PACKAGE_DIR/DEBIAN/postrm" << 'EOF'
#!/bin/bash
set -e

if [ "$1" = "purge" ]; then
    # Remove configuration files on purge
    rm -rf /etc/repobar || true
    # Note: User data in ~/.config/repobar is NOT removed
fi

# Update desktop database
if command -v update-desktop-database > /dev/null 2>&1; then
    update-desktop-database -q /usr/share/applications || true
fi

exit 0
EOF
chmod 755 "$PACKAGE_DIR/DEBIAN/postrm"

# Step 8: Create .desktop file
echo "📝 Creating .desktop file..."
cat > "$PACKAGE_DIR/usr/share/applications/repobar.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=RepoBar
GenericName=GitHub Repository Monitor
Comment=Monitor GitHub repositories from your system tray
Exec=/usr/bin/repobar
Icon=repobar
Terminal=false
Categories=Development;RevisionControl;
Keywords=github;git;repository;development;
StartupNotify=false
X-DBUS-StartupType=None
EOF

# Step 9: Copy icon
# TODO: Create actual app icon
echo "🎨 Creating placeholder icon..."
echo "⚠️  TODO: Add actual RepoBar icon (256x256 PNG)"
# cp "$PROJECT_ROOT/resources/repobar.png" "$PACKAGE_DIR/usr/share/icons/hicolor/256x256/apps/"

# Step 10: Copy documentation
echo "📚 Copying documentation..."
if [ -f "$PROJECT_ROOT/README.md" ]; then
    cp "$PROJECT_ROOT/README.md" "$PACKAGE_DIR/usr/share/doc/repobar/"
fi
if [ -f "$PROJECT_ROOT/CHANGELOG.md" ]; then
    cp "$PROJECT_ROOT/CHANGELOG.md" "$PACKAGE_DIR/usr/share/doc/repobar/"
fi
cat > "$PACKAGE_DIR/usr/share/doc/repobar/copyright" << 'EOF'
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: RepoBar
Source: https://github.com/steipete/RepoBar

Files: *
Copyright: 2024-2026 Peter Steinberger and contributors
License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
EOF

# Step 11: Set proper permissions
find "$PACKAGE_DIR" -type d -exec chmod 755 {} \;
find "$PACKAGE_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$PACKAGE_DIR/usr/bin/repobar"
chmod 755 "$PACKAGE_DIR/DEBIAN/postinst"
chmod 755 "$PACKAGE_DIR/DEBIAN/prerm"
chmod 755 "$PACKAGE_DIR/DEBIAN/postrm"

# Step 12: Build .deb package
echo "🔨 Building .deb package..."
cd "$BUILD_DIR"
dpkg-deb --build "$PACKAGE_NAME"

# Step 13: Move to project root
mv "${PACKAGE_NAME}.deb" "$PROJECT_ROOT/"

echo "✅ .deb package created: ${PACKAGE_NAME}.deb"
echo ""
echo "To test installation:"
echo "  sudo dpkg -i ${PACKAGE_NAME}.deb"
echo ""
echo "To remove:"
echo "  sudo dpkg -r repobar"
echo ""
echo "To purge (including config):"
echo "  sudo dpkg -P repobar"
echo ""
echo "To inspect package:"
echo "  dpkg -c ${PACKAGE_NAME}.deb"
echo "  dpkg -I ${PACKAGE_NAME}.deb"

# Cleanup
# rm -rf "$BUILD_DIR"
