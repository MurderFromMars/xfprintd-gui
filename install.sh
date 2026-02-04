#!/bin/bash
# XFPrintD GUI - Jailbroken Edition
# Part of the CyberXero Toolkit
# This script will:
# 1. Install all required dependencies for Arch-based systems
# 2. Patch out the XeroLinux-only check
# 3. Build the application
# 4. Install it to your system

set -e  # Exit on error

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
    clear
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
    echo "║                ${MAGENTA} JAILBROKEN EDITION ${CYAN}               ║"
    echo "║                                                                    ║"
    echo "║              ${GREEN}Part of the CyberXero Toolkit${CYAN}          ║"
    echo "║                                                                    ║"
    echo "║                                                                    ║"
    echo "║                                                                    ║"
    echo "╚════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${BOLD}${MAGENTA}What this installer does:${NC}"
    echo -e "  ${GREEN}✓${NC} Installs all required dependencies"
    echo -e "  ${GREEN}✓${NC} Patches out XeroLinux-only restrictions"
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

# Patch out XeroLinux check
echo -e "${MAGENTA}${BOLD}🔓 Jailbreaking Application...${NC}"
print_info "Removing XeroLinux-only distribution restrictions..."

UTIL_FILE="gui/src/core/util.rs"

if [ ! -f "$UTIL_FILE" ]; then
    print_error "Cannot find $UTIL_FILE"
    print_error "Make sure you're running this script from the xfprintd-gui-main directory"
    exit 1
fi

# Backup original file
cp "$UTIL_FILE" "${UTIL_FILE}.backup"

# Replace the is_supported_distribution function to always return true
cat > "$UTIL_FILE" << 'EOF'
/// Format finger name for display (replace dashes, capitalize).
pub fn display_finger_name(name: &str) -> String {
    if name.is_empty() {
        return String::new();
    }
    let mut s = name.replace('-', " ");
    let mut chars = s.chars();
    if let Some(first) = chars.next() {
        let upper = first.to_ascii_uppercase().to_string();
        s.replace_range(0..first.len_utf8(), &upper);
    }
    s
}

/// Create short finger name by removing common words.
pub fn create_short_finger_name(display_name: &str) -> String {
    let mut short_name = display_name
        .replace(" finger", "")
        .replace("Left ", "")
        .replace("Right ", "");

    if let Some(first_char) = short_name.chars().next() {
        short_name =
            first_char.to_uppercase().collect::<String>() + &short_name[first_char.len_utf8()..];
    }

    short_name
}

/// Check if current distribution is supported (PATCHED - works on all Arch-based systems).
pub fn is_supported_distribution() -> bool {
    true  // Patched to work on all Arch-based distributions
}

/// Get distribution name from os-release files.
pub fn get_distribution_name() -> Option<String> {
    use std::fs;

    // Try /etc/os-release first (most common)
    if let Ok(content) = fs::read_to_string("/etc/os-release") {
        if let Some(name) = parse_os_release_name(&content) {
            return Some(name);
        }
    }

    // Fallback to /usr/lib/os-release
    if let Ok(content) = fs::read_to_string("/usr/lib/os-release") {
        if let Some(name) = parse_os_release_name(&content) {
            return Some(name);
        }
    }

    // Fallback to /etc/lsb-release
    if let Ok(content) = fs::read_to_string("/etc/lsb-release") {
        for line in content.lines() {
            if line.starts_with("DISTRIB_ID=") {
                let name = line
                    .trim_start_matches("DISTRIB_ID=")
                    .trim_matches('"')
                    .to_string();
                if !name.is_empty() {
                    return Some(name);
                }
            }
        }
    }

    None
}

/// Parse NAME field from os-release content.
fn parse_os_release_name(content: &str) -> Option<String> {
    for line in content.lines() {
        if line.starts_with("NAME=") {
            let name = line
                .trim_start_matches("NAME=")
                .trim_matches('"')
                .to_string();
            if !name.is_empty() {
                return Some(name);
            }
        }
    }
    None
}
EOF

echo -e "${GREEN}${BOLD}✓ Jailbreak successful!${NC} Application now works on all Arch-based systems"
print_success "Patched $UTIL_FILE"
echo ""

# Build the application
print_info "Building XFPrintD GUI application..."

# Clean previous builds
if [ -d "target" ]; then
    print_info "Cleaning previous build artifacts..."
    cargo clean
fi

# Build in release mode
print_info "Compiling (this may take a few minutes)..."
cargo build --release

if [ ! -f "target/release/xfprintd-gui" ] || [ ! -f "target/release/xfprintd-gui-helper" ]; then
    print_error "Build failed - binaries not found"
    exit 1
fi

print_success "Build completed successfully!"
echo ""

# Install the application
print_info "Installing XFPrintD GUI to system..."

# Create installation directory
sudo mkdir -p /opt/xfprintd-gui

# Install binaries
print_info "Installing binaries..."
sudo install -Dm755 target/release/xfprintd-gui /opt/xfprintd-gui/xfprintd-gui
sudo install -Dm755 target/release/xfprintd-gui-helper /opt/xfprintd-gui/xfprintd-gui-helper

# Install patches directory
print_info "Installing PAM patches..."
sudo cp -r helper_tool/patches /opt/xfprintd-gui/

# Create symlink in /usr/bin
print_info "Creating system symlink..."
sudo ln -sf /opt/xfprintd-gui/xfprintd-gui /usr/bin/xfprintd-gui

# Install desktop file
print_info "Installing desktop entry..."
sudo mkdir -p /usr/share/applications
sudo install -Dm644 packaging/xfprintd-gui.desktop /usr/share/applications/xfprintd-gui.desktop

# Install icon
print_info "Installing application icon..."
sudo mkdir -p /usr/share/icons/hicolor/scalable/apps
if [ -f "gui/resources/icons/scalable/apps/fingerprint.svg" ]; then
    sudo install -Dm644 gui/resources/icons/scalable/apps/fingerprint.svg \
        /usr/share/icons/hicolor/scalable/apps/xfprintd-gui.svg
fi

# Update icon cache
print_info "Updating icon cache..."
sudo gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor 2>/dev/null || true

print_success "Installation completed!"
echo ""

# Enable and start fprintd service
print_info "Setting up fprintd service..."
sudo systemctl enable fprintd.service 2>/dev/null || true
sudo systemctl start fprintd.service 2>/dev/null || true
print_success "fprintd service enabled and started"
echo ""

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║         ✓  Installation Completed Successfully!          ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${BOLD}${MAGENTA}🔓 XFPrintD GUI - Jailbroken Edition${NC}"
echo -e "${CYAN}   Part of the CyberXero Toolkit${NC}"
echo ""
echo -e "${BOLD}How to launch:${NC}"
echo -e "  ${GREEN}1.${NC} Application Menu: Search for ${BOLD}'Fingerprint'${NC}"
echo -e "  ${GREEN}2.${NC} Terminal: ${BOLD}xfprintd-gui${NC}"
echo ""
echo -e "${YELLOW}${BOLD}📌 Important Notes:${NC}"
echo -e "  ${CYAN}•${NC} Make sure your fingerprint reader is connected"
echo -e "  ${CYAN}•${NC} Log out and back in if the app doesn't appear in your menu"
echo -e "  ${CYAN}•${NC} The app now works on ${GREEN}ANY${NC} Arch-based distribution!"
echo ""
echo -e "${BOLD}Enjoy your liberated fingerprint authentication! 🎉${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
