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
local userpatch = require("userpatch")

local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")

-- Reusable pluralization function
local function formatTime(minutes)
    if minutes <= 0 then
        return "Less than a minute"
    elseif minutes == 1 then
        return "1 minute"
    else
        return minutes .. " minutes"
    end
end

-- Override chapter_time_to_read
local orig_chapter_time = footerTextGeneratorMap.chapter_time_to_read

footerTextGeneratorMap.chapter_time_to_read = function(footer)
    local left = footer.ui.toc:getChapterPagesLeft(footer.pageno, footer.toc_level)
    
    -- Check if we're on the last page of the chapter
    if left == 0 then
        return "Chapter completed"
    end
    
    local time_string = footer:getDataFromStatistics("", left)
    
    if time_string and time_string ~= "" then
        local minutes = time_string:match("(%d+)m")
        minutes = minutes and tonumber(minutes) or 0

        local result = formatTime(minutes)
        return "Time left in chapter:   " .. result -- configurable, add spaces as desired
    end
    
    return orig_chapter_time(footer)
end

-- Add left/right margins to status bar
local orig_genAllFooterText = ReaderFooter.genAllFooterText

function ReaderFooter:genAllFooterText(...)
    local text, is_filler_inside = orig_genAllFooterText(self, ...)
    
    -- Add space padding to left and right (adjust spacing as needed) – configurable
    return "  " .. text .. "  ", is_filler_inside
end
