# Ani-CLI and MyAnimeList (MAL) Sync

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ani-cli](https://img.shields.io/badge/ani--cli-v5.2+-green.svg)](https://github.com/pystardust/ani-cli)
[![mpv](https://img.shields.io/badge/player-mpv-orange.svg)](https://mpv.io/)
[![MyAnimeList](https://img.shields.io/badge/sync-MyAnimeList-2e51a2.svg)](https://myanimelist.net/)

> **Seamless, automatic progress tracking for [ani-cli](https://github.com/pystardust/ani-cli) directly to your [MyAnimeList](https://myanimelist.net/) profile.**

---

## 📌 Overview

**ani-cli** is a popular CLI tool to browse and stream anime, using **mpv** as its video player. However, popular syncing extensions like [MALSync](https://github.com/MALSync/MALSync) only work in web browsers, and media trackers like Taiga or Shoko either run only on Windows or expect local video files on disk.

This project bridges **ani-cli**, **mpv**, and **MyAnimeList** via **Trackma** and a custom **mpv Lua event hook**:

1. You start an anime with `ani-track` (or your dock icon).
2. The wrapper syncs your MAL list in the background.
3. When `mpv` starts streaming, the Lua script tracks playback.
4. When you reach **90% completion**, it fuzzy-matches the title and updates your MAL episode progress.
5. In-player OSD notifications confirm when tracking starts and when MAL is successfully updated.

---

## ✨ Features

- 🎯 **90% Completion Trigger**: Only updates when you actually finish watching the episode (customizable).
- 🔤 **Fuzzy Title Matching (English → Romaji)**: Matches English stream titles (e.g., *"Bleach: Thousand-Year Blood War - The Calamity"*) with official MyAnimeList Romaji entries (*"Bleach: Sennen Kessen-hen - Kashin-tan"*).
- 📺 **In-Player OSD Alerts**: Shows real-time status banners directly on top of mpv video:
  - `📺 Tracking: <Anime Name> Ep <N> — MAL updates at 90% completion`
  - `✅ MAL updated: <Anime Name> Ep <N>`
- ⏱️ **Graceful Shutdown Catch**: If you exit mpv after watching over 50%, it automatically commits the update on quit.
- 🚀 **Transparent Wrapper**: `ani-track` accepts all native `ani-cli` arguments (e.g. `ani-track -c`, `ani-track -q 1080 "one piece"`).
- 🖥️ **Desktop & Dock Integration**: Includes `.desktop` launcher and runner script for quick GUI launching.

---

## 🏗️ Architecture

```text
[ Dock / Terminal ]
        │
        ▼
   ani-track (wrapper) ──► Pre-syncs MAL data via Trackma
        │
        ▼
     ani-cli ────────────► Streams episode via mpv with --force-media-title
                             │
                             ▼
                    ~/.config/mpv/scripts/trackma_hook.lua
                             │
                             ├─► Observes playback percent-pos (90%)
                             ├─► Calls Trackma `update file:"<title> <ep>"`
                             ├─► Displays mpv OSD notifications
                             │
                             ▼
                    MyAnimeList (API via OAuth PKCE)
```

---

## 📋 Prerequisites

Ensure you have the following installed on your Linux system:

- **mpv**
  ```bash
  sudo apt install mpv
  ```
- **ani-cli** (v5.0 or later)
  ```bash
  sudo curl -sL "https://raw.githubusercontent.com/pystardust/ani-cli/master/ani-cli" -o /usr/local/bin/ani-cli
  sudo chmod +x /usr/local/bin/ani-cli
  ```
- **python3** and **pipx**
  ```bash
  sudo apt install python3 pipx
  pipx ensurepath
  ```
- **Trackma**
  ```bash
  pipx install trackma
  ```

---

## 🚀 Quick Installation

Clone this repository and run the installer:

```bash
git clone https://github.com/iamitgandhi/Ani-Cli-and-MyAnimeList-Sync.git
cd Ani-Cli-and-MyAnimeList-Sync
chmod +x install.sh uninstall.sh bin/ani-track desktop/run-ani-cli
./install.sh
```

### Authenticate Trackma with MyAnimeList

If this is your first time using Trackma with MAL, run the included OAuth PKCE setup helper:

```bash
python3 scripts/setup_trackma_mal.py
```

1. It will automatically open your web browser to the official MyAnimeList authorization page.
2. Log in and click **Allow**.
3. Copy the URL/authorization code from the redirect page and paste it into the terminal.
4. Enter your MAL username. Your OAuth token is securely generated and saved.

---

## 🎮 Usage

### In Terminal
Replace `ani-cli` with `ani-track`:

```bash
# Search and play an anime:
ani-track "bleach"

# Continue watching from history:
ani-track -c

# Pass any regular ani-cli flags:
ani-track -q 1080 "spy x family"
```

### Desktop / Dock Shortcut
To add a launcher to your desktop environment (GNOME, KDE, Wayland, etc.):

```bash
# Copy launcher script
sudo cp desktop/run-ani-cli /usr/local/bin/run-ani-cli
sudo chmod +x /usr/local/bin/run-ani-cli

# Copy desktop file
cp desktop/ani-cli.desktop ~/.local/share/applications/
update-desktop-database ~/.local/share/applications/
```

---

## ⚙️ Configuration

The mpv hook is located at:
```bash
~/.config/mpv/scripts/trackma_hook.lua
```

You can customize behavior by modifying the variables at the top of the file:

```lua
local UPDATE_AT_PERCENT = 90             -- Percentage to trigger MAL update (default: 90)
local SHUTDOWN_THRESHOLD_PERCENT = 50    -- Save progress on close if watched at least 50%
```

---

## ❓ FAQ & Troubleshooting

### Why did direct title matching fail previously?
Streaming scrapers use English titles (e.g. *"Bleach: Thousand-Year Blood War"*), whereas MyAnimeList indexes official titles in Romaji (*"Bleach: Sennen Kessen-hen"*). By invoking Trackma's `update file:"<title>"` command, Trackma runs its internal **AIE / fuzzy-matching engine** to accurately resolve and map title discrepancies.

### Does updating ani-cli break this sync?
**No.** `ani-track` is a decoupled wrapper that calls whatever `ani-cli` binary is installed on your system. You can update `ani-cli` anytime without affecting this sync configuration.

### How do I uninstall?
Run the uninstaller script from the repository:
```bash
./uninstall.sh
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
