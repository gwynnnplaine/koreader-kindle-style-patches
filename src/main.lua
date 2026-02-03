-- Main entry point for patch

local function applyCustomStatusBarSettings()
	local ui = require("apps/reader/readerui").instance
	if not ui or not ui.footer then
		return
	end

	local footer = ui.footer

	-- Create presets
	createPresets(footer)

	-- Apply Kindle UI settings directly
	footer.settings.all_at_once = true
	footer.settings.percentage = true
	footer.settings.chapter_time_to_read = true
	footer.settings.dynamic_filler = true

	-- Disable other items
	footer.settings.page_progress = false
	footer.settings.pages_left_book = false
	footer.settings.time = false
	footer.settings.chapter_progress = false
	footer.settings.pages_left = false
	footer.settings.battery = false
	footer.settings.book_time_to_read = false
	footer.settings.bookmark_count = false
	footer.settings.mem_usage = false
	footer.settings.wifi_status = false
	footer.settings.page_turning_inverted = false
	footer.settings.book_author = false
	footer.settings.book_title = false
	footer.settings.book_chapter = false
	footer.settings.custom_text = false

	-- Set order and styling
	footer.settings.order = {"chapter_time_to_read", "dynamic_filler", "percentage"}
	footer.settings.items_separator = "none"
	footer.settings.item_prefix = "compact_items"
	footer.settings.align = "left"
	footer.settings.container_height = 20
	footer.settings.container_bottom_padding = 5

	-- Apply changes
	footer:updateFooterTextGenerator()
	footer:onUpdateFooter(true)
end

-- Apply when UIManager is ready
UIManager:runAfterNextRender(applyCustomStatusBarSettings)
