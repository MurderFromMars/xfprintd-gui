#!/bin/bash

set -e  # Exit on error

# Get the directory where this script lives and cd into it
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Set TERM for non-interactive environments
export TERM=${TERM:-xterm}

# Detect if we're in an interactive terminal
if [ -t 1 ]; then
    INTERACTIVE=true
else
    INTERACTIVE=false
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Print header
print_header() {
    # Only clear screen if interactive
    if [ "$INTERACTIVE" = true ]; then
        clear
    fi
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                    ║"
    echo "║        ██╗  ██╗███████╗██████╗ ██████╗ ██╗███╗   ██╗████████╗      ║"
    echo "║        ╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝      ║"
    echo "║         ╚███╔╝ █████╗  ██████╔╝██████╔╝██║██╔██╗ ██║   ██║         ║"
    echo "║         ██╔██╗ ██╔══╝  ██╔═══╝ ██╔══██╗██║██║╚██╗██║   ██║         ║"
    echo "║        ██╔╝ ██╗██║     ██║     ██║  ██║██║██║ ╚████║   ██║         ║"
    echo "║        ╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝         ║"
    echo "║                                                                    ║"
    echo "║                ${MAGENTA}UNIVERSAL EDITION ${CYAN}                 ║"
    echo "║                                                                    ║"
    echo "║              ${GREEN}Part of the CyberXero Toolkit${CYAN}          ║"
    echo "║                                                                    ║"
    echo "║         ${YELLOW}Works on ANY Arch-based distribution!${CYAN}      ║"
    echo "║                                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}${MAGENTA}What this installer does:${NC}"
    echo -e "  ${GREEN}✓${NC} Installs all required dependencies"
    echo -e "  ${GREEN}✓${NC} Compiles the application from source"
    echo -e "  ${GREEN}✓${NC} Installs to your system"
    echo -e "  ${GREEN}✓${NC} Sets up fprintd service"
    echo ""
    echo -e "${YELLOW}${BOLD}Compatible with:${NC} Arch, Manjaro, EndeavourOS, Garuda, and all Arch-based distros"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Do not run this script as root. It will request sudo when needed."
    exit 1
fi

# Show header
print_header

# Verify we're on Arch-based system
print_info "Verifying Arch-based system..."
if [ ! -f /etc/arch-release ] && ! command -v pacman &> /dev/null; then
    print_error "This script is for Arch-based systems only!"
    print_error "Use pacman-based distros like Arch, Manjaro, EndeavourOS, Garuda, etc."
    exit 1
fi
print_success "Arch-based system detected"
echo ""

# Verify we're in the right directory
if [ ! -f "$SCRIPT_DIR/Cargo.toml" ]; then
    print_error "Cargo.toml not found!"
    print_error "Make sure you're running this script from the xfprintd-gui directory"
    exit 1
fi

# Install dependencies
print_info "Installing dependencies via pacman..."
sudo pacman -S --needed --noconfirm \
    rust cargo \
    gtk4 libadwaita \
    glib2 pkgconf \
    polkit fprintd \
    base-devel

print_success "All dependencies installed"
echo ""

# Build the application
print_info "Building XFPrintD GUI application..."

# Clean previous builds if they exist
if [ -d "$SCRIPT_DIR/target" ]; then
    print_info "Cleaning previous build artifacts..."
    cargo clean
fi

# Build in release mode
print_info "Compiling (this may take a few minutes on first build)..."
echo ""
cargo build --release 2>&1 | tee /tmp/cargo_build.log

# Check build exit code
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    print_error "Cargo build failed!"
    print_error "Check /tmp/cargo_build.log for details"
    exit 1
fi

print_success "Cargo build completed!"
echo ""

# Find the actual binary name(s) - handling Cargo workspace
print_info "Locating built binaries..."
MAIN_BINARY=""
HELPER_BINARY=""

# Check if this is a workspace build
if [ -d "$SCRIPT_DIR/target/release" ]; then
    print_info "Scanning target/release directory..."
    
    # Look for the main GUI binary (multiple possible names)
    for possible_name in "xfprintd-gui" "xfprintd_gui" "gui" "xfprint-gui" "xfprint_gui"; do
        if [ -f "$SCRIPT_DIR/target/release/$possible_name" ] && [ -x "$SCRIPT_DIR/target/release/$possible_name" ]; then
            MAIN_BINARY="$SCRIPT_DIR/target/release/$possible_name"
            print_success "Found main binary: $possible_name"
            break
        fi
    done
    
    # Look for the helper binary
    for possible_name in "xfprintd-gui-helper" "xfprintd_gui_helper" "helper_tool" "helper-tool"; do
        if [ -f "$SCRIPT_DIR/target/release/$possible_name" ] && [ -x "$SCRIPT_DIR/target/release/$possible_name" ]; then
            HELPER_BINARY="$SCRIPT_DIR/target/release/$possible_name"
            print_success "Found helper binary: $possible_name"
            break
        fi
    done
fi

# If we still haven't found binaries, list what's actually there
if [ -z "$MAIN_BINARY" ]; then
    print_error "Could not find main binary in target/release/"
    print_error ""
    print_error "Contents of target/release (executable files only):"
    find "$SCRIPT_DIR/target/release" -maxdepth 1 -type f -executable ! -name "*.so" ! -name "*.d" 2>/dev/null | while read file; do
        echo "  - $(basename "$file")"
    done
    print_error ""
    print_error "This is a Cargo workspace. Please check:"
    print_error "  1. The [[bin]] name in gui/Cargo.toml"
    print_error "  2. The [[bin]] name in helper_tool/Cargo.toml"
    exit 1
fi

print_success "Build completed successfully!"
print_success "Main binary: $MAIN_BINARY"
if [ -n "$HELPER_BINARY" ]; then
    print_success "Helper binary: $HELPER_BINARY"
else
    print_warning "Helper binary not built (PAM features will be limited)"
fi
echo ""

# Install the application
print_info "Installing XFPrintD GUI to system..."

# Create installation directory
sudo mkdir -p /opt/xfprintd-gui

# Install main binary
print_info "Installing main binary..."
sudo install -Dm755 "$MAIN_BINARY" /opt/xfprintd-gui/xfprintd-gui

# Install helper binary if it exists
if [ -n "$HELPER_BINARY" ] && [ -f "$HELPER_BINARY" ]; then
    print_info "Installing helper binary..."
    sudo install -Dm755 "$HELPER_BINARY" /opt/xfprintd-gui/xfprintd-gui-helper
    
    # Install patches directory
    if [ -d "$SCRIPT_DIR/helper_tool/patches" ]; then
        print_info "Installing PAM patches..."
        sudo cp -r "$SCRIPT_DIR/helper_tool/patches" /opt/xfprintd-gui/
        sudo chmod -R 755 /opt/xfprintd-gui/patches
    fi
fi

# Create symlink in /usr/bin
print_info "Creating system symlink..."
sudo ln -sf /opt/xfprintd-gui/xfprintd-gui /usr/bin/xfprintd-gui

# Install desktop file
if [ -f "$SCRIPT_DIR/packaging/xfprintd-gui.desktop" ]; then
    print_info "Installing desktop entry..."
    sudo mkdir -p /usr/share/applications
    sudo install -Dm644 "$SCRIPT_DIR/packaging/xfprintd-gui.desktop" /usr/share/applications/xfprintd-gui.desktop
fi

# Install icon
print_info "Installing application icon..."
sudo mkdir -p /usr/share/icons/hicolor/scalable/apps
if [ -f "$SCRIPT_DIR/gui/resources/icons/scalable/apps/fingerprint.svg" ]; then
    sudo install -Dm644 "$SCRIPT_DIR/gui/resources/icons/scalable/apps/fingerprint.svg" \
        /usr/share/icons/hicolor/scalable/apps/xfprintd-gui.svg
fi

# Update desktop database
print_info "Updating desktop database..."
sudo update-desktop-database /usr/share/applications 2>/dev/null || true

# Update icon cache
print_info "Updating icon cache..."
sudo gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true

print_success "Installation completed!"
echo ""

# Enable and start fprintd service
print_info "Setting up fprintd service..."
sudo systemctl enable fprintd.service 2>/dev/null || true
sudo systemctl start fprintd.service 2>/dev/null || true

# Check fprintd status
if systemctl is-active --quiet fprintd; then
    print_success "fprintd service is running"
else
    print_warning "fprintd service failed to start"
    print_info "You may need to start it manually: sudo systemctl start fprintd"
fi
echo ""

# Post-installation checks
print_info "Performing post-installation checks..."

# Check installed files
INSTALL_OK=true
if [ -f "/usr/bin/xfprintd-gui" ]; then
    print_success "Binary installed: /usr/bin/xfprintd-gui"
else
    print_error "Binary not found at /usr/bin/xfprintd-gui"
    INSTALL_OK=false
fi

if [ -f "/opt/xfprintd-gui/xfprintd-gui-helper" ]; then
    print_success "Helper tool installed: /opt/xfprintd-gui/xfprintd-gui-helper"
else
    print_warning "Helper tool not installed (optional)"
fi

if [ -f "/usr/share/applications/xfprintd-gui.desktop" ]; then
    print_success "Desktop entry installed"
else
    print_warning "Desktop entry not found"
fi

echo ""

# Final message
if [ "$INSTALL_OK" = true ]; then
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                                                           ║"
    echo "║         ✓  Installation Completed Successfully!           ║"
    echo "║                                                           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}${MAGENTA}🎉 XFPrintD GUI - Universal Edition${NC}"
    echo -e "${CYAN}   Part of the CyberXero Toolkit${NC}"
    echo ""
    echo -e "${BOLD}How to launch:${NC}"
    echo -e "  ${GREEN}1.${NC} Application Menu: Search for ${BOLD}'Fingerprint'${NC}"
    echo -e "  ${GREEN}2.${NC} Terminal: ${BOLD}xfprintd-gui${NC}"
    echo ""
    echo -e "${YELLOW}${BOLD}📌 Important Notes:${NC}"
    echo -e "  ${CYAN}•${NC} Make sure your fingerprint reader is connected"
    echo -e "  ${CYAN}•${NC} Log out and back in if the app doesn't appear in your menu"
    echo -e "  ${CYAN}•${NC} Works on ${GREEN}ANY${NC} Arch-based distribution!"
    echo ""
    echo -e "${BOLD}Installation locations:${NC}"
    echo -e "  ${CYAN}•${NC} Binary: ${BOLD}/usr/bin/xfprintd-gui${NC}"
    echo -e "  ${CYAN}•${NC} Helper: ${BOLD}/opt/xfprintd-gui/xfprintd-gui-helper${NC}"
    echo -e "  ${CYAN}•${NC} Patches: ${BOLD}/opt/xfprintd-gui/patches/${NC}"
    echo ""
    echo -e "${BOLD}Enjoy your universal fingerprint authentication! 🎉${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
else
    echo -e "${RED}${BOLD}Installation may have issues. Please check the errors above.${NC}"
    exit 1
fi
