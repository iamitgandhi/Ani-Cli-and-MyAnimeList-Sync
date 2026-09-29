#!/usr/bin/env bash
# ============================================================
#  Uninstaller for Ani-CLI & MyAnimeList Auto-Sync
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Uninstalling Ani-CLI + MAL Sync components...${NC}"

if [ -f "$HOME/.config/mpv/scripts/trackma_hook.lua" ]; then
    rm -f "$HOME/.config/mpv/scripts/trackma_hook.lua"
    echo -e "${GREEN}✓ Removed ~/.config/mpv/scripts/trackma_hook.lua${NC}"
fi

if [ -f "$HOME/.local/bin/ani-track" ]; then
    rm -f "$HOME/.local/bin/ani-track"
    echo -e "${GREEN}✓ Removed ~/.local/bin/ani-track${NC}"
fi

echo -e "${GREEN}Ani-track components successfully uninstalled.${NC}"
echo "Note: Trackma accounts and config in ~/.config/trackma were preserved."
