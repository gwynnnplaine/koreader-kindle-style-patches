-- 2-kindle-time-left.lua
-- Kindle-style footer patch for KOReader
-- Auto-generated from src/ directory - DO NOT EDIT DIRECTLY
-- Edit files in src/ and run ./build.sh instead


-- === config.lua ===

local CONFIG = {
	CHAPTER_COMPLETED_TEXT = "Chapter completed",
	LABEL_TEXT = "Time left in chapter:",
	LABEL_MIN_WIDTH = 5, -- Minimum character width for label (for alignment)
	FOOTER_LEFT_MARGIN = 1, -- Character spaces on left
	FOOTER_RIGHT_MARGIN = 2, -- Character spaces on right
}


-- === helpers.lua ===

local CONSTANTS = {
	MINUTES_IN_HOUR = 60,
	NO_MINUTES = 0,
	ONE_MINUTE = 1,
}

local TEXT = {
   	LESS_THAN_A_MINUTE_TEXT = "less than a minute",
	ONE_MINUTE_TEXT = "1 minute",
	MINUTES_TEXT = " minutes",
}

local function getMinutes(time_string)
	if not time_string or time_string == "" then
		return CONSTANTS.NO_MINUTES
	end

	-- Format: "01:45" (hours:minutes)
	local hours, minutes = time_string:match("(%d+):(%d+)")
	if hours and minutes then
		return tonumber(hours) * CONSTANTS.MINUTES_IN_HOUR + tonumber(minutes)
	end

	-- Format: "1h 10m" or "10m" or "1h"
	hours = time_string:match("(%d+)h")
	minutes = time_string:match("(%d+)m")

	if hours or minutes then
		-- Convert hours to minutes, or use 0 if no hours found
		local hoursInMinutes = CONSTANTS.NO_MINUTES
		if hours then
			hoursInMinutes = tonumber(hours) * CONSTANTS.MINUTES_IN_HOUR
		end

		-- Get minutes value, or use 0 if no minutes found
		local minutesValue = CONSTANTS.NO_MINUTES
		if minutes then
			minutesValue = tonumber(minutes) or CONSTANTS.NO_MINUTES
		end

		return hoursInMinutes + minutesValue
	end

	return CONSTANTS.NO_MINUTES
end

local function formatTime(minutes)
	if minutes <= CONSTANTS.NO_MINUTES then
		return TEXT.LESS_THAN_A_MINUTE_TEXT
	elseif minutes == CONSTANTS.ONE_MINUTE then
		return TEXT.ONE_MINUTE_TEXT
	else
		return minutes .. TEXT.MINUTES_TEXT
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

local helpers = {
	getMinutes = getMinutes,
	formatTime = formatTime,
	getTimeString = getTimeString,
}

-- === footer.lua ===

local ReaderFooter = require("apps/reader/modules/readerfooter")
local userpatch = require("userpatch")


local orig_genFooterText = ReaderFooter.genAllFooterText
local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")
local original_chapter_time_to_read = footerTextGeneratorMap.chapter_time_to_read

local function canCalculateCustomTime(footer)
	local result = footer.ui.statistics and footer.ui.statistics.is_doc
	return result
end

local function getPagesLeftInChapter(footer)
	local result = footer.ui.toc:getChapterPagesLeft(footer.pageno)
		or footer.ui.document:getTotalPagesLeft(footer.pageno)
	return result
end

local function calculateReadingTime(footer, pages_left)
	local timeString = helpers.getTimeString(footer, pages_left)

	if not timeString then
		return nil
	end

	local minutes = helpers.getMinutes(timeString)

	local formattedTime = helpers.formatTime(minutes)

	return formattedTime
end

local function formatChapterTimeDisplay(time)
	local result = string.format("%-" .. CONFIG.LABEL_MIN_WIDTH .. "s %s", CONFIG.LABEL_TEXT, time)
	return result
end

function footerTextGeneratorMap.chapter_time_to_read(footer)
	local fallback = original_chapter_time_to_read(footer)

	if not canCalculateCustomTime(footer) then
		return fallback
	end

	local pagesLeft = getPagesLeftInChapter(footer)
	if not pagesLeft then
		return fallback
	end

	if pagesLeft == 0 then
		return CONFIG.CHAPTER_COMPLETED_TEXT
	end

	local readingTime = calculateReadingTime(footer, pagesLeft)
	if not readingTime then
		return fallback
	end

	local result = formatChapterTimeDisplay(readingTime)
	return result
end

-- Override genAllFooterText for margins
function ReaderFooter:genAllFooterText(...)
	local text, is_filler_inside = orig_genFooterText(self, ...)
	local left_margin = string.rep(" ", CONFIG.FOOTER_LEFT_MARGIN)
	local right_margin = string.rep(" ", CONFIG.FOOTER_RIGHT_MARGIN)
	return left_margin .. text .. right_margin, is_filler_inside
end

-- === main.lua ===

local UIManager = require("ui/uimanager")
local ReaderFooter = require("apps/reader/modules/readerfooter")

local orig_init = ReaderFooter.init

function ReaderFooter:init(...)
	orig_init(self, ...)

	-- Delay settings application until after KOReader loads saved settings
	UIManager:tickAfterNext(function()
		-- Check if we've already applied our settings
		local kindle_ui_applied = G_reader_settings:readSetting("kindle_ui_applied_test", false)

		if not kindle_ui_applied then
			-- Apply Kindle UI settings (first run only)
			self.settings.all_at_once = true
			self.settings.disable_progress_bar = true
			self.settings.percentage = true
			self.settings.chapter_time_to_read = true
			self.settings.dynamic_filler = true

			self.settings.page_progress = false
			self.settings.pages_left_book = false
			self.settings.time = false
			self.settings.chapter_progress = false
			self.settings.pages_left = false
			self.settings.battery = false
			self.settings.book_time_to_read = false
			self.settings.bookmark_count = false
			self.settings.mem_usage = false
			self.settings.wifi_status = false
			self.settings.page_turning_inverted = false
			self.settings.book_author = false
			self.settings.book_title = false
			self.settings.book_chapter = false
			self.settings.custom_text = false

			self.settings.order = {"chapter_time_to_read", "dynamic_filler", "percentage"}
			self.settings.items_separator = "none"
			self.settings.item_prefix = "compact_items"
			self.settings.align = "left"
			self.settings.container_height = 20
			self.settings.container_bottom_padding = 5

			self.mode_index = {}
			for i, name in ipairs(self.settings.order) do
				self.mode_index[i] = name
			end

			self:updateFooterTextGenerator()
			self:applyFooterMode()
			self:resetLayout()

			G_reader_settings:saveSetting("kindle_ui_applied_test", true)
			if G_reader_settings.flush then
				G_reader_settings:flush()
			end
		end
	end)
end
