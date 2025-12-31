#!/bin/bash

# Local lazygit installer for bash_functions repo
# Installs lazygit binary to the local bin/ directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/bin"
LAZYGIT_VERSION="0.57.0"  # Update this to the latest version as needed

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Local lazygit installer${NC}"
echo "Installing to: $BIN_DIR"
echo ""

# Create bin directory if it doesn't exist
mkdir -p "$BIN_DIR"

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux*)
        OS_TYPE="Linux"
        ;;
    Darwin*)
        OS_TYPE="Darwin"
        ;;
    CYGWIN*|MINGW*|MSYS*)
        OS_TYPE="Windows"
        ;;
    *)
        echo -e "${RED}❌ Unsupported operating system: $OS${NC}"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64)
        ARCH_TYPE="x86_64"
        ;;
    arm64|aarch64)
        ARCH_TYPE="arm64"
        ;;
    i386|i686)
        ARCH_TYPE="32-bit"
        ;;
    *)
        echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
        exit 1
        ;;
esac

echo -e "Detected: ${YELLOW}$OS_TYPE $ARCH_TYPE${NC}"

# Construct download URL based on OS and architecture
if [ "$OS_TYPE" = "Windows" ]; then
    if [ "$ARCH_TYPE" = "x86_64" ]; then
        DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Windows_x86_64.zip"
        ARCHIVE="lazygit.zip"
    else
        echo -e "${RED}❌ Windows ARM is not officially supported by lazygit${NC}"
        exit 1
    fi
elif [ "$OS_TYPE" = "Linux" ]; then
    if [ "$ARCH_TYPE" = "x86_64" ]; then
        DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        ARCHIVE="lazygit.tar.gz"
    elif [ "$ARCH_TYPE" = "arm64" ]; then
        DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_arm64.tar.gz"
        ARCHIVE="lazygit.tar.gz"
    else
        DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_32-bit.tar.gz"
        ARCHIVE="lazygit.tar.gz"
    fi
elif [ "$OS_TYPE" = "Darwin" ]; then
    if [ "$ARCH_TYPE" = "x86_64" ]; then
        DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Darwin_x86_64.tar.gz"
        ARCHIVE="lazygit.tar.gz"
    elif [ "$ARCH_TYPE" = "arm64" ]; then
        DOWNLOAD_URL="https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Darwin_arm64.tar.gz"
        ARCHIVE="lazygit.tar.gz"
    fi
fi

TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit 1

echo ""
echo -e "${YELLOW}📥 Downloading lazygit v${LAZYGIT_VERSION}...${NC}"
echo "URL: $DOWNLOAD_URL"

if command -v curl &> /dev/null; then
    curl -L -o "$ARCHIVE" "$DOWNLOAD_URL"
elif command -v wget &> /dev/null; then
    wget -O "$ARCHIVE" "$DOWNLOAD_URL"
else
    echo -e "${RED}❌ Neither curl nor wget is available. Please install one of them.${NC}"
    exit 1
fi

if [ ! -f "$ARCHIVE" ]; then
    echo -e "${RED}❌ Download failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Download complete${NC}"
echo ""
echo -e "${YELLOW}📦 Extracting...${NC}"

# Extract based on archive type
if [[ "$ARCHIVE" == *.zip ]]; then
    if command -v unzip &> /dev/null; then
        unzip -q "$ARCHIVE"
    else
        echo -e "${RED}❌ unzip command not found. Please install unzip.${NC}"
        exit 1
    fi
elif [[ "$ARCHIVE" == *.tar.gz ]]; then
    tar -xzf "$ARCHIVE"
fi

# Find and move the lazygit executable
if [ -f "lazygit.exe" ]; then
    mv lazygit.exe "$BIN_DIR/"
    EXECUTABLE="$BIN_DIR/lazygit.exe"
elif [ -f "lazygit" ]; then
    mv lazygit "$BIN_DIR/"
    chmod +x "$BIN_DIR/lazygit"
    EXECUTABLE="$BIN_DIR/lazygit"
else
    echo -e "${RED}❌ Could not find lazygit executable after extraction${NC}"
    ls -la
    exit 1
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✅ Extraction complete${NC}"
echo ""
echo -e "${GREEN}🎉 lazygit v${LAZYGIT_VERSION} installed successfully!${NC}"
echo ""
echo "Installed at: $EXECUTABLE"
echo ""
echo -e "${YELLOW}To use lazygit, either:${NC}"
echo "1. Run it directly: $EXECUTABLE"
echo "2. Add an alias to your shell config:"
echo "   alias lazygit='$EXECUTABLE'"
echo "3. Source fn_git.sh which includes the 'lg' alias"
echo ""
echo -e "${GREEN}Quick test:${NC}"
"$EXECUTABLE" --version
