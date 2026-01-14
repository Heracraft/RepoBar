#!/bin/bash
# Build .rpm package for Fedora/openSUSE
# This script creates an RPM package for installation via rpm or dnf/zypper
#
# Prerequisites:
# - rpmbuild must be installed
# - Swift toolchain must be available
# - repobar-linux must build successfully
#
# Usage:
#   ./Scripts/build-rpm.sh [version]
#
# Arguments:
#   version - Package version (default: read from version.env)
#
# Output:
#   repobar-<version>-1.x86_64.rpm

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/.build/rpm"

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

echo "🚀 Building RepoBar .rpm package version $VERSION..."

# Clean previous build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Step 1: Build repobar-linux in release mode
echo "📦 Building repobar-linux..."
cd "$PROJECT_ROOT"
swift build --product repobar-linux --configuration release

# Step 2: Create source tarball
echo "📦 Creating source tarball..."
TARBALL_NAME="repobar-${VERSION}.tar.gz"
mkdir -p "$BUILD_DIR/SOURCES/repobar-${VERSION}"
cp ".build/release/repobar-linux" "$BUILD_DIR/SOURCES/repobar-${VERSION}/"

# Copy desktop file and documentation
mkdir -p "$BUILD_DIR/SOURCES/repobar-${VERSION}/share"
cat > "$BUILD_DIR/SOURCES/repobar-${VERSION}/share/repobar.desktop" << 'EOF'
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

# Copy docs
[ -f "$PROJECT_ROOT/README.md" ] && cp "$PROJECT_ROOT/README.md" "$BUILD_DIR/SOURCES/repobar-${VERSION}/share/" || true
[ -f "$PROJECT_ROOT/CHANGELOG.md" ] && cp "$PROJECT_ROOT/CHANGELOG.md" "$BUILD_DIR/SOURCES/repobar-${VERSION}/share/" || true

cd "$BUILD_DIR/SOURCES"
tar czf "$TARBALL_NAME" "repobar-${VERSION}"
rm -rf "repobar-${VERSION}"

# Step 3: Create .spec file
echo "📝 Creating .spec file..."
cat > "$BUILD_DIR/SPECS/repobar.spec" << EOF
Name:           repobar
Version:        ${VERSION}
Release:        1%{?dist}
Summary:        GitHub repository monitor for Linux
License:        MIT
URL:            https://github.com/steipete/RepoBar
Source0:        %{name}-%{version}.tar.gz

BuildArch:      x86_64
Requires:       dbus-libs
Recommends:     libsecret

%description
RepoBar provides system tray integration for monitoring
GitHub repositories on KDE Plasma and other Linux desktops.

Features:
- System tray integration via StatusNotifierItem
- Monitor CI/CD status, releases, and activity
- OAuth authentication with GitHub
- Secure token storage via KWallet or libsecret
- Local Git repository integration

%prep
%setup -q

%build
# Binary is pre-built by Swift, no compilation needed

%install
rm -rf %{buildroot}

# Install executable
mkdir -p %{buildroot}%{_bindir}
install -m 755 repobar-linux %{buildroot}%{_bindir}/repobar

# Install desktop file
mkdir -p %{buildroot}%{_datadir}/applications
install -m 644 share/repobar.desktop %{buildroot}%{_datadir}/applications/

# Install icon (TODO: add actual icon)
# mkdir -p %{buildroot}%{_datadir}/icons/hicolor/256x256/apps
# install -m 644 share/repobar.png %{buildroot}%{_datadir}/icons/hicolor/256x256/apps/

# Install documentation
mkdir -p %{buildroot}%{_docdir}/%{name}
[ -f share/README.md ] && install -m 644 share/README.md %{buildroot}%{_docdir}/%{name}/ || true
[ -f share/CHANGELOG.md ] && install -m 644 share/CHANGELOG.md %{buildroot}%{_docdir}/%{name}/ || true

%files
%{_bindir}/repobar
%{_datadir}/applications/repobar.desktop
%doc %{_docdir}/%{name}/README.md
%doc %{_docdir}/%{name}/CHANGELOG.md
# %{_datadir}/icons/hicolor/256x256/apps/repobar.png

%post
# Update desktop database
if [ -x %{_bindir}/update-desktop-database ]; then
    %{_bindir}/update-desktop-database -q %{_datadir}/applications || true
fi

# Update icon cache
if [ -x %{_bindir}/gtk-update-icon-cache ]; then
    %{_bindir}/gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor || true
fi

%preun
# Stop running instances
pkill -f repobar || true

%postun
if [ \$1 -eq 0 ]; then
    # Update desktop database on uninstall
    if [ -x %{_bindir}/update-desktop-database ]; then
        %{_bindir}/update-desktop-database -q %{_datadir}/applications || true
    fi
fi

%changelog
* $(date '+%a %b %d %Y') RepoBar Team <contact@steipete.com> - ${VERSION}-1
- Version ${VERSION}
- Linux port with Platform abstraction layer
- System tray integration via StatusNotifierItem (coming soon)
- Secure storage via KWallet or libsecret (coming soon)

* Wed Jan 01 2026 RepoBar Team <contact@steipete.com> - 0.1.0-1
- Initial Linux release
- Platform abstraction layer complete
- Foundation ready for D-Bus integration
EOF

# Step 4: Build RPM
echo "🔨 Building RPM package..."
cd "$BUILD_DIR"
rpmbuild --define "_topdir $BUILD_DIR" -ba SPECS/repobar.spec

# Step 5: Move to project root
RPM_FILE=$(find "$BUILD_DIR/RPMS" -name "repobar-*.rpm" -type f)
if [ -n "$RPM_FILE" ]; then
    cp "$RPM_FILE" "$PROJECT_ROOT/"
    RPM_BASENAME=$(basename "$RPM_FILE")
    echo "✅ RPM package created: $RPM_BASENAME"
else
    echo "❌ Error: RPM file not found"
    exit 1
fi

echo ""
echo "To test installation (Fedora/RHEL):"
echo "  sudo dnf install ./$RPM_BASENAME"
echo ""
echo "To test installation (openSUSE):"
echo "  sudo zypper install ./$RPM_BASENAME"
echo ""
echo "To remove:"
echo "  sudo dnf remove repobar  # or: sudo zypper remove repobar"
echo ""
echo "To inspect package:"
echo "  rpm -qilp $RPM_BASENAME"

# Cleanup
# rm -rf "$BUILD_DIR"
