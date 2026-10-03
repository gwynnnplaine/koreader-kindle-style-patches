-- Runs the real src/footer.lua against a fake KOReader.

local NBSP = "\194\160"
local HAIR = "\226\128\138"

-- Fake font: normal and no-break spaces 10px, hair spaces 2px, anything else 12px.
local function textWidth(text)
	local width = 0
	for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		if char == " " or char == NBSP then
			width = width + 10
		elseif char == HAIR then
			width = width + 2
		else
			width = width + 12
		end
	end
	return width
end

local function buildKOReader(options)
	options = options or {}
	local saved = { kindle_ui_applied = true, kindle_ui_left_mode = options.left_mode }
	local generators = {
		chapter_time_to_read = function() return "fallback" end,
		percentage = function() return "42%" end,
	}
	local original_taps = 0
	local measurements = 0

	local ReaderFooter = {}
	function ReaderFooter.applyFooterMode() end
	function ReaderFooter:TapFooter()
		original_taps = original_taps + 1
		return "original"
	end
	-- Like KOReader: left item, a filler of whole spaces, right item, measured
	-- before anything is added around it.
	function ReaderFooter:genAllFooterText()
		local left = generators.chapter_time_to_read(self)
		local right = generators.percentage(self)
		local bar = self._saved_screen_width - 2 * self.horizontal_margin
		local spaces = math.floor((bar - textWidth(left) - textWidth(right)) / 10)
		return left .. string.rep(" ", math.max(spaces, 0)) .. right, true
	end

	local TextWidget = {}
	function TextWidget:new(args)
		measurements = measurements + 1
		return {
			getSize = function() return { w = textWidth(args.text) } end,
			free = function() end,
		}
	end

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
	}

	package.loaded["apps/reader/modules/readerfooter"] = ReaderFooter
	package.loaded["ui/widget/textwidget"] = TextWidget
	package.loaded["device"] = { screen = { scaleBySize = function(_, value) return value end } }
	package.loaded["userpatch"] = {
		getUpValue = function() return generators end,
	}
	package.loaded["helpers"] = { helpers = dofile("src/helpers.lua") }

	local source = io.open("src/footer.lua"):read("*a")
	if options.tap_to_cycle == false then
		source = source:gsub("TAP_TO_CYCLE = true", "TAP_TO_CYCLE = false")
	end
	local chunk = loadstring(source)
	chunk()

	local time_for_pages = options.time_for_pages or function(pages) return pages .. "m" end
	local footer = setmetatable({
		pageno = 5,
		pages = 300,
		settings = { lock_tap = options.lock_tap, disable_progress_bar = true },
		mode = options.hidden and 0 or 1,
		mode_list = { off = 0 },
		view = { flipping_visible = false },
		footer_text_face = options.measured ~= false and {} or nil,
		_saved_screen_width = 600,
		horizontal_margin = 10,
		updates = 0,
		ui = {
			statistics = {
				is_doc = true,
				getTimeForPages = function(_, pages) return time_for_pages(pages) end,
			},
			toc = { getChapterPagesLeft = function() return options.chapter_pages_left or 25 end },
			document = {
				getTotalPagesLeft = function() return 280 end,
				hasHiddenFlows = function() return false end,
			},
		},
	}, { __index = ReaderFooter })
	function footer:onUpdateFooter()
		self.updates = self.updates + 1
	end

	return footer, generators, saved, function() return original_taps end, function() return measurements end
end

local function stripPadding(text)
	return (text:gsub(HAIR, ""))
end

describe("footer left item", function()
	it("keeps the gaps between words in compact mode", function()
		local footer, generators = buildKOReader({ measured = false })
		assert.are.equal(NBSP .. "25" .. NBSP .. "mins" .. NBSP .. "left" .. NBSP .. "in" .. NBSP .. "chapter",
			generators.chapter_time_to_read(footer))
	end)

	it("shows the chapter time by default", function()
		local footer, generators = buildKOReader()
		assert.are.equal(NBSP .. "25" .. NBSP .. "mins" .. NBSP .. "left" .. NBSP .. "in" .. NBSP .. "chapter",
			stripPadding(generators.chapter_time_to_read(footer)))
	end)

	it("shows the page number", function()
		local footer, generators = buildKOReader({ left_mode = "page", measured = false })
		assert.are.equal(NBSP .. "Page" .. NBSP .. "5", generators.chapter_time_to_read(footer))
	end)

	it("shows the time left in the book in hours and minutes", function()
		local footer, generators = buildKOReader({ left_mode = "book", measured = false })
		assert.are.equal(NBSP .. "4" .. NBSP .. "hrs" .. NBSP .. "40" .. NBSP .. "mins" .. NBSP .. "left"
			.. NBSP .. "in" .. NBSP .. "book", generators.chapter_time_to_read(footer))
	end)

	it("falls back to the chapter time when the book time is unknown", function()
		local footer, generators = buildKOReader({
			left_mode = "book",
			measured = false,
			time_for_pages = function(pages)
				if pages == 280 then
					error("no statistics yet")
				end
				return pages .. "m"
			end,
		})
		footer.getDataFromStatistics = nil
		assert.are.equal(NBSP .. "25" .. NBSP .. "mins" .. NBSP .. "left" .. NBSP .. "in" .. NBSP .. "chapter",
			generators.chapter_time_to_read(footer))
	end)

	it("leaves text that is not a reading time to KOReader", function()
		local footer, generators = buildKOReader({
			measured = false,
			time_for_pages = function() return "N/A" end,
		})
		assert.are.equal(NBSP .. "fallback", generators.chapter_time_to_read(footer))
	end)

	it("says the chapter is completed", function()
		local footer, generators = buildKOReader({ chapter_pages_left = 0, measured = false })
		assert.are.equal(NBSP .. "Chapter" .. NBSP .. "completed", generators.chapter_time_to_read(footer))
	end)

	it("blanks the whole bar in the empty mode", function()
		local footer, generators = buildKOReader({ left_mode = "none" })
		assert.are.equal("", generators.chapter_time_to_read(footer))
		assert.are.equal("", generators.percentage(footer))
	end)
end)

describe("footer margins", function()
	it("are inside the items, so the measured line fits the bar", function()
		local footer, generators = buildKOReader()
		assert.are.equal("42%" .. NBSP .. NBSP, generators.percentage(footer))

		local text = footer:genAllFooterText()
		assert.are.equal(true, textWidth(text) <= 580)
		assert.are.equal(NBSP, text:sub(1, 2))
		assert.are.equal("42%" .. NBSP .. NBSP, text:sub(-7))
	end)
end)

describe("footer percentage position", function()
	it("ends at the same pixel whatever the left item shows", function()
		for _, mode in ipairs({ "page", "chapter", "book" }) do
			for _, minutes in ipairs({ 1, 7, 25, 61, 280 }) do
				local footer = buildKOReader({
					left_mode = mode,
					time_for_pages = function() return minutes .. "m" end,
				})
				assert.are.equal(580, textWidth((footer:genAllFooterText())))
			end
		end
	end)

	it("measures each distinct line only once", function()
		local footer, generators, _, _, measurements = buildKOReader()
		generators.chapter_time_to_read(footer)
		local after_first = measurements()
		generators.chapter_time_to_read(footer)
		generators.chapter_time_to_read(footer)
		assert.are.equal(after_first, measurements())
	end)

	it("falls back to no padding before the footer is laid out", function()
		local footer, generators = buildKOReader({ measured = false })
		assert.are.equal(nil, generators.chapter_time_to_read(footer):find(HAIR, 1, true))
	end)
end)

describe("ReaderFooter:TapFooter()", function()
	it("cycles the left item and repaints", function()
		local footer, _, saved = buildKOReader()
		local seen = {}
		for _ = 1, 4 do
			assert.are.equal(true, footer:TapFooter({}))
			seen[#seen + 1] = saved.kindle_ui_left_mode
		end
		assert.are.equal("book,none,page,chapter", table.concat(seen, ","))
		assert.are.equal(4, footer.updates)
	end)

	it("leaves a locked status bar to KOReader", function()
		local footer, _, saved, original_taps = buildKOReader({ lock_tap = true })
		assert.are.equal("original", footer:TapFooter({}))
		assert.are.equal(1, original_taps())
		assert.is_nil(saved.kindle_ui_left_mode)
	end)

	it("lets KOReader bring back a hidden status bar", function()
		local footer, _, saved, original_taps = buildKOReader({ hidden = true })
		assert.are.equal("original", footer:TapFooter({}))
		assert.are.equal(1, original_taps())
		assert.is_nil(saved.kindle_ui_left_mode)
	end)

	it("can be turned off in FOOTER_CONFIG", function()
		local footer, generators, saved, original_taps = buildKOReader({
			tap_to_cycle = false,
			left_mode = "book",
			measured = false,
		})
		assert.are.equal("original", footer:TapFooter({}))
		assert.are.equal(1, original_taps())
		assert.are.equal("book", saved.kindle_ui_left_mode)
		-- the saved mode is ignored: the chapter time is always shown
		assert.are.equal(NBSP .. "25" .. NBSP .. "mins" .. NBSP .. "left" .. NBSP .. "in" .. NBSP .. "chapter",
			generators.chapter_time_to_read(footer))
	end)

	it("leaves taps while flipping to KOReader", function()
		local footer, _, _, original_taps = buildKOReader()
		footer.view.flipping_visible = true
		assert.are.equal("original", footer:TapFooter({}))
		assert.are.equal(1, original_taps())
	end)
end)
