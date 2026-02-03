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

	-- Create presets
	createPresets(footer)

	-- Apply changes
	footer:updateFooterTextGenerator()
	footer:onUpdateFooter(true)
end

-- Apply when UIManager is ready
UIManager:runAfterNextRender(addKindleUIpreset)
