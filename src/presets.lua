-- Preset definitions for footer

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

	-- Default KOReader preset
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
