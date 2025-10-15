--[[
    This user patch customizes the KOReader footer to display chapter reading time
    in a style similar to Kindle.

    Specifically, it shows "Time left in chapter: X minute(s)" while reading,
    with proper singular/plural formatting. When the user reaches the last page
    of the chapter, it displays "Chapter completed" instead.

    Additionally, the patch adds a small margin (padding) on both the left and
    right sides of the footer text, improving readability by preventing text
    from running too close to the edges.

    The patch overrides the existing "chapter_time_to_read" footer text generator,
    using KOReader's built-in APIs to retrieve time-left data and chapter position.

    For margin padding, it prepends and appends spaces to the full footer text via
    the genAllFooterText function override, ensuring consistent margins regardless
    of footer content.
  
    Note:
    - Use this patch in combination with KOReader's footer settings including
      'chapter_time_to_read', 'dynamic_filler', and 'percentage' for best results.
    - Adjust margin padding spaces in the genAllFooterText override as desired.

    Related KOReader source code:
    https://github.com/koreader/koreader/blob/master/frontend/apps/reader/modules/readerfooter.lua
--]]

local ReaderFooter = require("apps/reader/modules/readerfooter")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local userpatch = require("userpatch")

-- Store original stuff
local orig_genFooterText = ReaderFooter.genAllFooterText
local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")
local original_footerTextGeneratorMap_chapter_time_to_read = footerTextGeneratorMap.chapter_time_to_read

-- Helper functions
local function getMinutes(time_string)
    if not time_string or time_string == "" then
        return 0
    end
    
    -- Format: "01:45"
    local hours, minutes = time_string:match("(%d+):(%d+)")
    if hours and minutes then
        return tonumber(hours) * 60 + tonumber(minutes)
    end
    
    -- Format: "1h 10m" or "10m" or "1h"
    hours = time_string:match("(%d+)h")
    minutes = time_string:match("(%d+)m")
    
    if hours or minutes then
        return (hours and tonumber(hours) * 60 or 0) + (minutes and tonumber(minutes) or 0)
    end
    
    return 0
end


local function formatTime(minutes)
    if minutes <= 0 then
        return "Less than a minute"
    elseif minutes == 1 then
        return "1 minute"
    else
        return minutes .. " minutes"
    end
end

local function getTimeString(footer, pages_left)
    -- Method 1: Works on Emulator 
    if footer.ui.statistics and footer.ui.statistics.getTimeForPages then
        local ok, time_string = pcall(function()
            return footer.ui.statistics:getTimeForPages(pages_left)
        end)
        if ok and time_string then
            return time_string
        end
    end
    
    -- Method 2: Works on Kindle
    if footer.getDataFromStatistics then
        local ok, time_string = pcall(function()
            return footer:getDataFromStatistics("", pages_left)
        end)
        if ok and time_string and time_string ~= "" then
            return time_string
        end
    end
    
    return nil
end

function  footerTextGeneratorMap.chapter_time_to_read(footer)
    local originalTimeToRead = original_footerTextGeneratorMap_chapter_time_to_read(footer)

    local left = footer.ui.toc:getChapterPagesLeft(footer.pageno) or footer.ui.document:getTotalPagesLeft(footer.pageno)
    if not left then
        UIManager:show(InfoMessage:new{
        text = "Can't determine pages left, using original KOReader function",
        timeout = 15,
    })
        return originalTimeToRead
    end

    if left == 0 then
        return "Chapter completed"
    end



    local leftTime = getTimeString(footer, left)

    if not leftTime then
        UIManager:show(InfoMessage:new{
        text = "Can't determine time for pages left, using original KOReader function",
        timeout = 15,
    })
        return originalTimeToRead
    end

    local time = formatTime(getMinutes(leftTime))

    return "Time left in chapter:   " .. time -- configurable, add spaces as needed
end


function ReaderFooter:genAllFooterText(...)
    local text, is_filler_inside = orig_genFooterText(self, ...)
    -- Configurable – add more space as needed
    return " " .. text .. "  ", is_filler_inside
end

