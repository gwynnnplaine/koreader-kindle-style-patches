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
