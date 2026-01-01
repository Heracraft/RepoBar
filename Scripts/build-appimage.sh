#!/bin/bash
# Build AppImage package for Linux
# This script creates a universal Linux package that can run on most distributions
#
# Prerequisites:
# - appimagetool must be installed
# - Swift toolchain must be available
# - repobar-linux must build successfully
#
# Usage:
#   ./Scripts/build-appimage.sh
#
# Output:
#   RepoBar-x86_64.AppImage (in current directory)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/appimage"
APP_DIR="$BUILD_DIR/RepoBar.AppDir"

echo "🚀 Building RepoBar AppImage..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR"

# Step 1: Build repobar-linux in release mode
echo "📦 Building repobar-linux..."
cd "$PROJECT_ROOT"
swift build --product repobar-linux --configuration release

# Step 2: Create AppImage directory structure
echo "📁 Creating AppImage directory structure..."
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

# Step 3: Copy executable
echo "📋 Copying executable..."
cp ".build/release/repobar-linux" "$APP_DIR/usr/bin/repobar"
chmod +x "$APP_DIR/usr/bin/repobar"

# Step 4: Bundle Swift runtime libraries
# TODO: Copy Swift runtime libraries to usr/lib
# This ensures the app works on systems without Swift installed
echo "⚠️  TODO: Bundle Swift runtime libraries"
# swift_lib_path=$(swift -print-target-info | grep -o '"runtimeLibraryPaths":\[[^]]*\]' | grep -o '\/[^"]*')
# cp -r "$swift_lib_path"/*.so "$APP_DIR/usr/lib/"

# Step 5: Create .desktop file
echo "📝 Creating .desktop file..."
cat > "$APP_DIR/repobar.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=RepoBar
GenericName=GitHub Repository Monitor
Comment=Monitor GitHub repositories from your system tray
Exec=repobar
Icon=repobar
Terminal=false
Categories=Development;RevisionControl;
Keywords=github;git;repository;development;
StartupNotify=false
X-DBUS-StartupType=None
EOF

# Also copy to standard location
cp "$APP_DIR/repobar.desktop" "$APP_DIR/usr/share/applications/"

# Step 6: Copy icon
# TODO: Create actual app icon
echo "🎨 Creating placeholder icon..."
# For now, create a placeholder
# In the future, convert Icon.icns or create a PNG icon
echo "⚠️  TODO: Add actual RepoBar icon (256x256 PNG)"
# cp "$PROJECT_ROOT/resources/repobar.png" "$APP_DIR/usr/share/icons/hicolor/256x256/apps/"
# cp "$PROJECT_ROOT/resources/repobar.png" "$APP_DIR/repobar.png"

# Step 7: Create AppRun script
echo "🔧 Creating AppRun launcher..."
cat > "$APP_DIR/AppRun" << 'EOF'
#!/bin/bash
# AppImage launcher script
SELF=$(readlink -f "$0")
HERE=${SELF%/*}
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/repobar" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# Step 8: Download appimagetool if not available
APPIMAGETOOL="$BUILD_DIR/appimagetool-x86_64.AppImage"
if [ ! -f "$APPIMAGETOOL" ]; then
    echo "⬇️  Downloading appimagetool..."
    curl -L "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage" \
        -o "$APPIMAGETOOL"
    chmod +x "$APPIMAGETOOL"
fi

# Step 9: Build AppImage
echo "🔨 Building AppImage..."
cd "$BUILD_DIR"
ARCH=x86_64 "$APPIMAGETOOL" RepoBar.AppDir "RepoBar-x86_64.AppImage"

# Step 10: Move to project root
mv "RepoBar-x86_64.AppImage" "$PROJECT_ROOT/"

echo "✅ AppImage created: RepoBar-x86_64.AppImage"
echo ""
echo "To test:"
echo "  ./RepoBar-x86_64.AppImage"
echo ""
echo "To install:"
echo "  mv RepoBar-x86_64.AppImage ~/.local/bin/"
echo "  chmod +x ~/.local/bin/RepoBar-x86_64.AppImage"

# Cleanup
# rm -rf "$BUILD_DIR"
