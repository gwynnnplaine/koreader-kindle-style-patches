-- Runs the real src/main.lua against a fake KOReader.

local REGULAR_FACE = "./fonts/noto/NotoSans-Regular.ttf"
local BOLD_FACE = "./fonts/noto/NotoSans-Bold.ttf"

local function buildKOReader(footer_settings, first_run)
	local scheduled = {}
	local saved = { kindle_ui_applied = not first_run }
	local flushes = 0
	local repaints = 0

	local UIManager = {
		tickAfterNext = function(_, callback)
			scheduled[#scheduled + 1] = callback
		end,
	}

	local FontChooser = {
		isFontRegistered = function(file)
			return file == REGULAR_FACE or file == BOLD_FACE
		end,
	}

	local ReaderFooter = {}
	function ReaderFooter:init() end

	_G.G_reader_settings = {
		readSetting = function(_, key, default)
			if saved[key] == nil then
				return default
			end
			return saved[key]
		end,
		saveSetting = function(_, key, value)
			saved[key] = value
		end,
		flush = function()
			flushes = flushes + 1
		end,
	}

	package.loaded["ui/uimanager"] = UIManager
	package.loaded["ui/widget/fontchooser"] = FontChooser
	package.loaded["ui/widget/textwidget"] = {}
	package.loaded["ui/font"] = {}
	package.loaded["apps/reader/modules/readerfooter"] = ReaderFooter
	package.loaded["apps/reader/modules/readerui"] = {}
	package.loaded["userpatch"] = {}
	package.loaded["helpers"] = { helpers = dofile("src/helpers.lua") }

	dofile("src/main.lua")

	local footer = {
		settings = footer_settings,
		mode = 1,
		mode_index = { [0] = "off", "chapter_time_to_read", "dynamic_filler", "percentage" },
		mode_list = {},
		rendered_face = footer_settings.text_font_face,
		rendered_bold = footer_settings.text_font_bold,
		set_mode_index = function() end,
		set_has_no_mode = function() end,
		updateFooterTextGenerator = function() end,
		applyFooterMode = function() end,
		resetLayout = function() end,
	}
	function footer:updateFooterFont()
		self.rendered_face = self.settings.text_font_face
		self.rendered_bold = self.settings.text_font_bold
	end
	function footer:refreshFooter()
		repaints = repaints + 1
	end

	ReaderFooter.init(footer)
	for _, callback in ipairs(scheduled) do
		callback()
	end

	return footer, saved, function() return repaints end, function() return flushes end
end

local function kindleSettings(overrides)
	local settings = {
		text_font_face = REGULAR_FACE,
		text_font_bold = true,
		text_font_size = 14,
		order = { [0] = "off", "chapter_time_to_read", "dynamic_filler", "percentage" },
	}
	for key, value in pairs(overrides or {}) do
		settings[key] = value
	end
	return settings
end

describe("ReaderFooter:init() font repair", function()
	it("installs the real bold file on first run", function()
		local footer, _, repaints = buildKOReader(kindleSettings({ text_font_bold = false }), true)

		assert.are.equal(BOLD_FACE, footer.settings.text_font_face)
		assert.are.equal(false, footer.settings.text_font_bold)
		assert.are.equal(BOLD_FACE, footer.rendered_face)
		assert.are.equal(1, repaints())
	end)

	it("renders the real bold file, not a synthesized bold, after the swap", function()
		local footer, saved, repaints = buildKOReader(kindleSettings())

		assert.are.equal(BOLD_FACE, footer.settings.text_font_face)
		assert.are.equal(false, footer.settings.text_font_bold)
		assert.are.equal(BOLD_FACE, footer.rendered_face)
		assert.are.equal(false, footer.rendered_bold)
		assert.are.equal(1, repaints())
		assert.are.equal(BOLD_FACE, saved.footer.text_font_face)
	end)

	it("is idempotent: a second run neither swaps nor repaints", function()
		local footer, _, repaints = buildKOReader(kindleSettings({
			text_font_face = BOLD_FACE,
			text_font_bold = false,
		}))

		assert.are.equal(BOLD_FACE, footer.settings.text_font_face)
		assert.are.equal(false, footer.settings.text_font_bold)
		assert.are.equal(0, repaints())
	end)

	it("leaves a user who turned bold off alone", function()
		local footer, _, repaints = buildKOReader(kindleSettings({ text_font_bold = false }))

		assert.are.equal(REGULAR_FACE, footer.settings.text_font_face)
		assert.are.equal(false, footer.settings.text_font_bold)
		assert.are.equal(0, repaints())
	end)

	it("leaves a bold font with no registered bold sibling alone", function()
		local footer, _, repaints = buildKOReader(kindleSettings({
			text_font_face = "/mnt/us/fonts/Unpaired-Regular.ttf",
		}))

		assert.are.equal("/mnt/us/fonts/Unpaired-Regular.ttf", footer.settings.text_font_face)
		assert.are.equal(true, footer.settings.text_font_bold)
		assert.are.equal(0, repaints())
	end)
end)
