-- 2-kindle-time-left.lua
-- Combined Kindle-style footer and centered clock header for KOReader
-- Auto-generated from src/ directory - DO NOT EDIT DIRECTLY


-- ============ FOOTER SECTION ============


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

local FOOTER_CONFIG = {
	CHAPTER_COMPLETED_TEXT = "Chapter completed",
	LABEL_TEXT = "Time left in chapter:",
	LABEL_MIN_WIDTH = 5, -- Minimum character width for label (for alignment)
	FOOTER_LEFT_MARGIN = 1, -- Character spaces on left
	FOOTER_RIGHT_MARGIN = 2, -- Character spaces on right
}

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
	local result = string.format("%-" .. FOOTER_CONFIG.LABEL_MIN_WIDTH .. "s %s", FOOTER_CONFIG.LABEL_TEXT, time)
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
		return FOOTER_CONFIG.CHAPTER_COMPLETED_TEXT
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
	local left_margin = string.rep(" ", FOOTER_CONFIG.FOOTER_LEFT_MARGIN)
	local right_margin = string.rep(" ", FOOTER_CONFIG.FOOTER_RIGHT_MARGIN)
	return left_margin .. text .. right_margin, is_filler_inside
end

-- === main.lua ===

local UIManager = require("ui/uimanager")
local ReaderFooter = require("apps/reader/modules/readerfooter")

local orig_init = ReaderFooter.init

function ReaderFooter:init(...)
	orig_init(self, ...)

	UIManager:tickAfterNext(function()
		local kindle_ui_applied = G_reader_settings:readSetting("kindle_ui_applied", false)

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

			G_reader_settings:saveSetting("kindle_ui_applied", true)
			if G_reader_settings.flush then
				G_reader_settings:flush()
			end
		end
	end)
end

-- ============ HEADER SECTION ============


-- === header.lua ===

-- Modify these values to customize the header appearance
local HEADER_CONFIG = {
    -- Spacing
    top_padding = 12,          -- Top margin in pixels
    -- Font
    font_face = "ffont",       -- Font name
    font_size = 16,            -- Font size in pixels
    font_bold = true,         --  Use bold font?
    font_color = nil,          -- Font color (nil = COLOR_BLACK)
    -- Margins
    use_book_margins = true,   -- Use same margins as book for header
    margin = nil,              -- Fallback margin if book margins disabled (nil = Size.padding.large)
    max_width_pct = 100,       -- Maximum width % before truncating (default: 100)
    -- Behavior
    show_for_pdf = false,      -- Show header for PDF/CBZ files?
}

-- ==========================================
-- Implementation - No need to modify below
-- ==========================================
local Blitbuffer = require("ffi/blitbuffer")
local TextWidget = require("ui/widget/textwidget")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local BD = require("ui/bidi")
local Size = require("ui/size")
local Geom = require("ui/geometry")
local Font = require("ui/font")
local datetime = require("datetime")
local Device = require("device")
local Screen = Device.screen
local ReaderView = require("apps/reader/modules/readerview")

local orig_paintTo = ReaderView.paintTo

function ReaderView:paintTo(bb, x, y)
    orig_paintTo(self, bb, x, y)

	if self.render_mode ~= nil and not HEADER_CONFIG.show_for_pdf then
		return
	end

	-- Get configuration values with defaults
	local font_color = HEADER_CONFIG.font_color or Blitbuffer.COLOR_BLACK
	local fallback_margin = HEADER_CONFIG.margin or Size.padding.large

	-- Calculate margins
	local screen_width = Screen:getWidth()
	local left_margin = fallback_margin
	local right_margin = fallback_margin

	if HEADER_CONFIG.use_book_margins and self.document and self.document.getPageMargins then
		local doc_margins = self.document:getPageMargins()
		left_margin = doc_margins.left or fallback_margin
		right_margin = doc_margins.right or fallback_margin
	end

	local margins = left_margin + right_margin
	local avail_width = screen_width - margins

	local time = datetime.secondsToHour(os.time(), G_reader_settings:isTrue("twelve_hour_clock"))

	local function getFittedText(text, max_width_pct)
		if text == nil or text == "" then
			return ""
		end
		local text_widget = TextWidget:new{
			text = text:gsub(" ", "\u{00A0}"), -- no-break-space
			max_width = avail_width * max_width_pct * (1/100),
			face = Font:getFace(HEADER_CONFIG.font_face, HEADER_CONFIG.font_size),
			bold = HEADER_CONFIG.font_bold,
			padding = 0,
		}
		local fitted_text, add_ellipsis = text_widget:getFittedText()
		text_widget:free()
		if add_ellipsis then
			fitted_text = fitted_text .. "…"
		end
		return BD.auto(fitted_text)
	end

	local header_content = getFittedText(time, HEADER_CONFIG.max_width_pct)

	local header_text = TextWidget:new{
		text = header_content,
		face = Font:getFace(HEADER_CONFIG.font_face, HEADER_CONFIG.font_size),
		bold = HEADER_CONFIG.font_bold,
		fgcolor = font_color,
		padding = 0,
	}

	local header_height = header_text:getSize().h + HEADER_CONFIG.top_padding

	local header = CenterContainer:new{
		dimen = Geom:new{ w = screen_width, h = header_height },
		VerticalGroup:new{
			VerticalSpan:new{ width = HEADER_CONFIG.top_padding },
			HorizontalGroup:new{
				HorizontalSpan:new{ width = left_margin },
				header_text,
				HorizontalSpan:new{ width = right_margin },
			},
		},
	}

	header:paintTo(bb, x, y)
end
