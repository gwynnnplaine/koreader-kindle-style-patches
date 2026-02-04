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
