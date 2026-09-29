-- ============================================================
--  trackma_hook.lua - Auto-update MAL via Trackma from mpv
-- ============================================================
--
--  When ani-cli plays an anime via mpv with --force-media-title,
--  this script:
--    1. Reads the media title (e.g. "Bleach: Thousand-Year Blood War Episode 8")
--    2. Monitors playback progress
--    3. At 90% completion → calls trackma to update MAL
--
--  Uses Trackma's "update file:" command for fuzzy title matching
--  so English titles from ani-cli match Romaji titles on MAL.
--
--  Location: ~/.config/mpv/scripts/trackma_hook.lua
-- ============================================================

local mp = require("mp")

local UPDATE_AT_PERCENT = 90
local SHUTDOWN_THRESHOLD_PERCENT = 50
local updated = false
local tracking = false
local media_title_raw = nil

-- Check if title looks like an ani-cli formatted anime title
local function is_anime_title(media_title)
    if not media_title or media_title == "" then
        return false
    end
    return media_title:match("[Ee]pisode%s+%d+$") ~= nil
end

local function update_mal()
    if updated or not media_title_raw then return end
    updated = true

    mp.msg.info(("[trackma_hook] Updating MAL: %s"):format(media_title_raw))
    mp.osd_message(("🔄 Updating MAL: %s"):format(media_title_raw), 3)

    -- Use "update file:" which triggers fuzzy title matching in trackma
    -- This maps English titles (ani-cli) to Romaji titles (MAL) correctly
    local home = os.getenv("HOME") or ""
    local trackma_bin = home .. "/.local/bin/trackma"
    local escaped_title = media_title_raw:gsub("'", "'\\''")
    local cmd = string.format(
        "printf 'update file:\"%s\"\\nsend\\n' | PATH=\"%s/.local/bin:$PATH\" %s -a 1 2>&1",
        escaped_title, home, trackma_bin
    )

    mp.command_native_async({
        name = "subprocess",
        args = {"bash", "-c", cmd},
        capture_stdout = true,
        capture_stderr = true,
    }, function(success, result)
        local output = (result and result.stdout) or ""
        if success and output:find("Updating show") then
            local show = output:match("Updating show (.+) to episode")
            local ep = output:match("to episode (%d+)")
            mp.msg.info("[trackma_hook] MAL updated successfully!")
            mp.osd_message(("✅ MAL updated: %s Ep %s"):format(show or "?", ep or "?"), 4)
        else
            mp.msg.warn("[trackma_hook] MAL update response: " .. output)
            if output:find("Show not found") then
                mp.osd_message("⚠️ MAL: Show not found in your list", 4)
            else
                mp.osd_message("⚠️ MAL update check logs", 4)
            end
        end
    end)
end

-- Fires on every percent-pos change
local function on_percent_change(_, pct)
    if updated or not tracking or not pct then return end
    if pct >= UPDATE_AT_PERCENT then
        update_mal()
    end
end

local function on_file_loaded()
    updated = false
    tracking = false
    media_title_raw = nil

    local title = mp.get_property("media-title")

    if is_anime_title(title) then
        media_title_raw = title
        tracking = true

        local anime, ep = title:match("^(.+)%s+[Ee]pisode%s+(%d+)$")
        mp.msg.info(("[trackma_hook] Detected: %s Episode %s"):format(anime or "?", ep or "?"))
        mp.osd_message(("📺 Tracking: %s Ep %s\nMAL updates at %d%% completion"):format(
            anime or title, ep or "?", UPDATE_AT_PERCENT), 5)
        mp.observe_property("percent-pos", "number", on_percent_change)
    else
        mp.msg.info("[trackma_hook] No anime title pattern found, skipping tracking")
    end
end

-- Also update on shutdown if they watched at least 50%
local function on_shutdown()
    if updated or not tracking then return end
    local pct = mp.get_property_number("percent-pos", 0)
    if pct >= SHUTDOWN_THRESHOLD_PERCENT and media_title_raw then
        local home = os.getenv("HOME") or ""
        local trackma_bin = home .. "/.local/bin/trackma"
        local escaped_title = media_title_raw:gsub("'", "'\\''")
        local cmd = string.format(
            "printf 'update file:\"%s\"\\nsend\\n' | PATH=\"%s/.local/bin:$PATH\" %s -a 1 2>&1",
            escaped_title, home, trackma_bin
        )
        os.execute(cmd)
        mp.msg.info(("[trackma_hook] Shutdown update at %.0f%%: %s"):format(pct, media_title_raw))
    end
end

mp.register_event("file-loaded", on_file_loaded)
mp.register_event("shutdown", on_shutdown)
