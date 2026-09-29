#!/usr/bin/env bash
# ============================================================
#  Installer for Ani-CLI & MyAnimeList (MAL) Auto-Sync
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}    Ani-CLI + MyAnimeList Auto-Sync Installation            ${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

# 1. Dependency Checks
echo -e "${CYAN}[1/5] Checking prerequisites...${NC}"

if ! command -v mpv &>/dev/null; then
    echo -e "${RED}Error: mpv is not installed.${NC} Please install mpv: sudo apt install mpv"
    exit 1
fi
echo -e "${GREEN}✓ mpv found: $(mpv --version | head -n1)${NC}"

if ! command -v ani-cli &>/dev/null; then
    echo -e "${YELLOW}Warning: ani-cli not found in PATH.${NC}"
    echo "Make sure ani-cli is installed before running ani-track."
else
    echo -e "${GREEN}✓ ani-cli found: $(which ani-cli)${NC}"
fi

if ! command -v python3 &>/dev/null; then
    echo -e "${RED}Error: python3 is required.${NC}"
    exit 1
fi

# Check trackma
if ! command -v trackma &>/dev/null; then
    echo -e "${YELLOW}Trackma not detected.${NC} Attempting to install via pipx..."
    if ! command -v pipx &>/dev/null; then
        echo -e "${RED}pipx is not installed.${NC} Please install pipx first: sudo apt install pipx && pipx ensurepath"
        exit 1
    fi
    pipx install trackma
    pipx ensurepath
    export PATH="$HOME/.local/bin:$PATH"
fi
echo -e "${GREEN}✓ trackma found: $(which trackma)${NC}"

# 2. Install mpv Lua Hook
echo -e "${CYAN}[2/5] Installing mpv Lua hook...${NC}"
mkdir -p "$HOME/.config/mpv/scripts"
cp "$SCRIPT_DIR/mpv/scripts/trackma_hook.lua" "$HOME/.config/mpv/scripts/trackma_hook.lua"
echo -e "${GREEN}✓ Installed to ~/.config/mpv/scripts/trackma_hook.lua${NC}"

# 3. Install ani-track wrapper
echo -e "${CYAN}[3/5] Installing ani-track wrapper...${NC}"
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/bin/ani-track" "$HOME/.local/bin/ani-track"
chmod +x "$HOME/.local/bin/ani-track"
echo -e "${GREEN}✓ Installed to ~/.local/bin/ani-track${NC}"

# 4. Configure Trackma default config if missing
echo -e "${CYAN}[4/5] Checking Trackma configuration...${NC}"
mkdir -p "$HOME/.config/trackma"
if [ ! -f "$HOME/.config/trackma/config.json" ]; then
    cp "$SCRIPT_DIR/config/trackma-config.json" "$HOME/.config/trackma/config.json"
    echo -e "${GREEN}✓ Created default config at ~/.config/trackma/config.json${NC}"
else
    echo -e "${GREEN}✓ Existing Trackma config found.${NC}"
fi

# 5. Check MAL Authentication
echo -e "${CYAN}[5/5] Checking Trackma accounts...${NC}"
if ! trackma -a 1 -h &>/dev/null; then
    echo -e "${YELLOW}Trackma account not configured yet.${NC}"
    echo "Run the OAuth setup helper to authenticate with MyAnimeList:"
    echo "  python3 $SCRIPT_DIR/scripts/setup_trackma_mal.py"
else
    echo -e "${GREEN}✓ Trackma account is configured.${NC}"
fi

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}✓ Installation complete!                                    ${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""
echo "To watch anime and auto-update MAL, simply run:"
echo "  ani-track \"anime name\""
echo "or for interactive history:"
echo "  ani-track -c"
echo ""
