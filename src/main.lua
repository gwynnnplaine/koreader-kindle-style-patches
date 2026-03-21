local UIManager = require("ui/uimanager")
local ReaderFooter = require("apps/reader/modules/readerfooter")

local orig_init = ReaderFooter.init

local function rebuildFooterModeState(footer)
	footer:set_mode_index()
	footer.mode_list = {}
	for i = 0, #footer.mode_index do
		footer.mode_list[footer.mode_index[i]] = i
	end
	footer:set_has_no_mode()
end

local function getFirstEnabledMode(footer)
	for i, mode_name in ipairs(footer.mode_index) do
		if footer.settings[mode_name] and mode_name ~= "dynamic_filler" then
			return i
		end
	end
	return footer.mode_list.page_progress or footer.mode_list.off or 0
end

local function recoverInvalidMode(footer)
	local mode = footer.mode
	if mode == nil or footer.mode_index[mode] == nil then
		return getFirstEnabledMode(footer)
	end

	if not footer.settings.all_at_once and footer.settings.disable_progress_bar then
		local mode_name = footer.mode_index[mode]
		if not mode_name or not footer.settings[mode_name] or mode_name == "dynamic_filler" then
			return getFirstEnabledMode(footer)
		end
	end

	return nil
end

function ReaderFooter:init(...)
	orig_init(self, ...)

	UIManager:tickAfterNext(function()
		local kindle_ui_applied = G_reader_settings:readSetting("kindle_ui_applied", false)
		local should_refresh_layout = false
		local should_flush = false

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

			-- Keep KOReader's expected 0-based order format (off at index 0).
			self.settings.order = {
				[0] = "off",
				"chapter_time_to_read",
				"dynamic_filler",
				"percentage",
			}
			self.settings.items_separator = "none"
			self.settings.item_prefix = "compact_items"
			self.settings.align = "left"
			self.settings.container_height = 20
			self.settings.container_bottom_padding = 5

			G_reader_settings:saveSetting("kindle_ui_applied", true)
			G_reader_settings:saveSetting("footer", self.settings)
			should_refresh_layout = true
			should_flush = true
		end

		-- Migration for older patch versions that saved a 1-based order table.
		if self.settings.order
			and self.settings.order[0] == nil
			and self.settings.order[1] == "chapter_time_to_read"
			and self.settings.order[2] == "dynamic_filler"
			and self.settings.order[3] == "percentage" then
			self.settings.order[0] = "off"
			G_reader_settings:saveSetting("footer", self.settings)
			should_refresh_layout = true
			should_flush = true
		end

		if should_refresh_layout then
			rebuildFooterModeState(self)
		end

		local recovered_mode = recoverInvalidMode(self)
		if recovered_mode ~= nil and recovered_mode ~= self.mode then
			self.mode = recovered_mode
			G_reader_settings:saveSetting("reader_footer_mode", self.mode)
			should_refresh_layout = true
			should_flush = true
		end

		if should_refresh_layout then
			self:updateFooterTextGenerator()
			self:applyFooterMode()
			self:resetLayout()
		end

		if should_flush and G_reader_settings.flush then
			G_reader_settings:flush()
		end
	end)
end
