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

-- === presets.lua ===

local function createPresets(footer)
	local util = require("util")
	local presets = G_reader_settings:readSetting("footer_presets", {})

	-- Kindle UI preset
	local kindle_ui_settings = util.tableDeepCopy(footer.default_settings)
	kindle_ui_settings.all_at_once = true
	kindle_ui_settings.disable_progress_bar = true
	kindle_ui_settings.percentage = true
	kindle_ui_settings.chapter_time_to_read = true
	kindle_ui_settings.dynamic_filler = true
	kindle_ui_settings.page_progress = false
	kindle_ui_settings.pages_left_book = false
	kindle_ui_settings.time = false
	kindle_ui_settings.chapter_progress = false
	kindle_ui_settings.pages_left = false
	kindle_ui_settings.battery = false
	kindle_ui_settings.book_time_to_read = false
	kindle_ui_settings.bookmark_count = false
	kindle_ui_settings.mem_usage = false
	kindle_ui_settings.wifi_status = false
	kindle_ui_settings.page_turning_inverted = false
	kindle_ui_settings.book_author = false
	kindle_ui_settings.book_title = false
	kindle_ui_settings.book_chapter = false
	kindle_ui_settings.custom_text = false
	kindle_ui_settings.order = {"chapter_time_to_read", "dynamic_filler", "percentage"}
	kindle_ui_settings.items_separator = "none"
	kindle_ui_settings.item_prefix = "compact_items"
	kindle_ui_settings.align = "left"
	kindle_ui_settings.container_height = 20
	kindle_ui_settings.container_bottom_padding = 5

	presets["Kindle UI"] = {
		footer = kindle_ui_settings,
		reader_footer_mode = 3,
		reader_footer_custom_text = "KOReader",
		reader_footer_custom_text_repetitions = 1,
	}

	local default_footer = util.tableDeepCopy(footer.default_settings)
	default_footer.all_at_once = false
	default_footer.order = {"page_progress", "time"}

	presets["Default KOReader"] = {
		footer = default_footer,
		reader_footer_mode = footer.mode_list.page_progress,
		reader_footer_custom_text = "KOReader",
		reader_footer_custom_text_repetitions = 1,
	}

	G_reader_settings:saveSetting("footer_presets", presets)
	return presets
end

-- Safety-checked preset creation
local function createPresetsSafely(footer)
	local initialized = G_reader_settings:readSetting("presets_initialized", false)
	if not initialized then
		createPresets(footer)
		G_reader_settings:saveSetting("presets_initialized", true)
	end
	return G_reader_settings:readSetting("footer_presets", {})
end

-- Apply a preset to the footer
local function applyPreset(presetName, footer)
	local presets = G_reader_settings:readSetting("footer_presets", {})
	local preset = presets[presetName]

	if not preset then
		return false
	end

	-- Apply footer settings
	for key, value in pairs(preset.footer) do
		footer.settings[key] = value
	end

	-- Apply other settings
	if preset.reader_footer_mode then
		footer.mode = preset.reader_footer_mode
	end
	if preset.reader_footer_custom_text then
		footer.custom_text = preset.reader_footer_custom_text
	end
	if preset.reader_footer_custom_text_repetitions then
		footer.custom_text_repetitions = preset.reader_footer_custom_text_repetitions
	end

	-- Refresh footer
	footer:updateFooterTextGenerator()
	footer:onUpdateFooter(true)

	return true
end

-- Get currently active preset name
local function getActivePreset()
	return G_reader_settings:readSetting("footer_active_preset", "Kindle UI")
end

-- Set active preset name
local function setActivePreset(presetName)
	G_reader_settings:saveSetting("footer_active_preset", presetName)
end

-- Get all presets
local function getPresets()
	return G_reader_settings:readSetting("footer_presets", {})
end

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
local NotificationWidget = require("ui/widget/notification")

-- Hook into ReaderFooter menu to add Presets submenu
local orig_getMenuItems = ReaderFooter.getMenuItems
function ReaderFooter:getMenuItems()
	local items = orig_getMenuItems(self)
	
	-- Find the status bar settings section or add to end
	local preset_menu = {
		text = "Presets",
		sub_item_table = {
			{
				text = "Kindle UI",
				checked_func = function()
					return getActivePreset() == "Kindle UI"
				end,
				callback = function()
					local footer = require("apps/reader/readerui").instance.footer
					if applyPreset("Kindle UI", footer) then
						setActivePreset("Kindle UI")
						UIManager:show(NotificationWidget:new{
							text = "Preset applied: Kindle UI",
							timeout = 2,
						})
					end
				end,
			},
			{
				text = "Default KOReader",
				checked_func = function()
					return getActivePreset() == "Default KOReader"
				end,
				callback = function()
					local footer = require("apps/reader/readerui").instance.footer
					if applyPreset("Default KOReader", footer) then
						setActivePreset("Default KOReader")
						UIManager:show(NotificationWidget:new{
							text = "Preset applied: Default KOReader",
							timeout = 2,
						})
					end
				end,
			},
		},
	}
	
	table.insert(items, preset_menu)
	return items
end

local function addKindleUIpreset()
	local ui = require("apps/reader/readerui").instance
	if not ui or not ui.footer then
		return
	end

	local footer = ui.footer

	-- Create presets safely (only if not already initialized)
	createPresetsSafely(footer)

	-- Apply the active preset (or default to Kindle UI)
	local activePreset = getActivePreset()
	if not applyPreset(activePreset, footer) then
		-- Fallback to Kindle UI if active preset doesn't exist
		applyPreset("Kindle UI", footer)
		setActivePreset("Kindle UI")
	end
end

-- Apply when UIManager is ready
UIManager:runAfterNextRender(addKindleUIpreset)
