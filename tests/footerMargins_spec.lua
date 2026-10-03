-- Runs the real src/footer.lua against a fake KOReader.

local NBSP = "\194\160"

-- Fake font: normal and no-break spaces 10px, anything else 12px.
local function textWidth(text)
	local width = 0
	for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		if char == " " or char == NBSP then
			width = width + 10
		else
			width = width + 12
		end
	end
	return width
end

local function buildKOReader(options)
	options = options or {}
	local generators = {
		chapter_time_to_read = function() return options.fallback or "fallback" end,
		percentage = function() return options.percentage or "42%" end,
	}

	local ReaderFooter = {}
	function ReaderFooter.applyFooterMode() end
	-- Like KOReader: left item, a filler of whole spaces, right item, measured
	-- before anything is added around it.
	function ReaderFooter:genAllFooterText()
		local left = generators.chapter_time_to_read(self)
		local right = generators.percentage(self)
		local bar = self._saved_screen_width - 2 * self.horizontal_margin
		local spaces = math.floor((bar - textWidth(left) - textWidth(right)) / 10)
		return left .. string.rep(" ", math.max(spaces, 0)) .. right, true
	end

	package.loaded["apps/reader/modules/readerfooter"] = ReaderFooter
	package.loaded["userpatch"] = {
		getUpValue = function() return generators end,
	}
	package.loaded["helpers"] = { helpers = dofile("src/helpers.lua") }

	dofile("src/footer.lua")

	local footer = setmetatable({
		pageno = 5,
		_saved_screen_width = 600,
		horizontal_margin = 10,
		ui = {
			statistics = {
				is_doc = options.is_doc ~= false,
				getTimeForPages = function() return "25m" end,
			},
			toc = { getChapterPagesLeft = function() return 25 end },
			document = { getTotalPagesLeft = function() return 280 end },
		},
	}, { __index = ReaderFooter })

	return footer, generators
end

describe("footer chapter time", function()
	it("keeps the gaps between words in compact mode", function()
		local footer, generators = buildKOReader()
		assert.are.equal(NBSP .. "Time" .. NBSP .. "left" .. NBSP .. "in" .. NBSP .. "chapter:" .. NBSP .. "25"
			.. NBSP .. "minutes", generators.chapter_time_to_read(footer))
	end)

	it("keeps the gaps in KOReader's own text too", function()
		local footer, generators = buildKOReader({ is_doc = false, fallback = "⏳ 1:05" })
		assert.are.equal(NBSP .. "⏳" .. NBSP .. "1:05", generators.chapter_time_to_read(footer))
	end)

	it("leaves an empty item empty", function()
		local footer, generators = buildKOReader({ is_doc = false, fallback = "", percentage = "" })
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

	it("no longer wraps the whole line", function()
		local footer = buildKOReader()
		local text = footer:genAllFooterText()
		assert.are.equal(nil, text:find("^ "))
		assert.are.equal(nil, text:find(" $"))
	end)
end)
