local ReaderFooter = require("apps/reader/modules/readerfooter")
local FooterTextWidget = require("ui/widget/textwidget")
local Screen = require("device").screen
local userpatch = require("userpatch")
local helpers = require("helpers").helpers

local FOOTER_CONFIG = {
	CHAPTER_COMPLETED_TEXT = "Chapter completed",
	CHAPTER_SUFFIX = "left in chapter",
	BOOK_SUFFIX = "left in book",
	PAGE_TEXT = "Page %s", -- use "Page %s of %s" to also show the total
	FOOTER_LEFT_MARGIN = 1, -- Character spaces on left
	FOOTER_RIGHT_MARGIN = 2, -- Character spaces on right
	TAP_TO_CYCLE = true, -- Tap the status bar to switch page / chapter time / book time / blank
}

local LEFT_MODE_SETTING = "kindle_ui_left_mode"

local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")
local original_chapter_time_to_read = footerTextGeneratorMap.chapter_time_to_read
local original_percentage = footerTextGeneratorMap.percentage
local orig_TapFooter = ReaderFooter.TapFooter

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

	-- Text that is not a reading time is left to KOReader's own item.
	local minutes = helpers.parseMinutes(timeString)
	if not minutes then
		return nil
	end

	local formattedTime = helpers.formatTime(minutes)

	return formattedTime
end

local function getLeftMode()
	if not FOOTER_CONFIG.TAP_TO_CYCLE then
		return helpers.normalizeLeftMode(nil)
	end
	return helpers.normalizeLeftMode(G_reader_settings:readSetting(LEFT_MODE_SETTING))
end

local function getPageText(footer)
	local ok, text = pcall(function()
		if footer.ui.pagemap and footer.ui.pagemap:wantsPageLabels() then
			return FOOTER_CONFIG.PAGE_TEXT:format(
				tostring(footer.ui.pagemap:getCurrentPageLabel(true)),
				tostring(footer.ui.pagemap:getLastPageLabel(true))
			)
		end
		if footer.ui.document:hasHiddenFlows() then
			local flow = footer.ui.document:getPageFlow(footer.pageno)
			return FOOTER_CONFIG.PAGE_TEXT:format(
				tostring(footer.ui.document:getPageNumberInFlow(footer.pageno)),
				tostring(footer.ui.document:getTotalPagesInFlow(flow))
			)
		end
		return FOOTER_CONFIG.PAGE_TEXT:format(tostring(footer.pageno), tostring(footer.pages))
	end)
	if ok and text then
		return text
	end
	return nil
end

local function getChapterText(footer)
	local fallback = original_chapter_time_to_read(footer)

	if not canCalculateCustomTime(footer) then
		return fallback
	end

	local pagesLeft = getPagesLeftInChapter(footer)
	if not pagesLeft then
		return fallback
	end

	if pagesLeft == 0 then
		return FOOTER_CONFIG.CHAPTER_COMPLETED_TEXT
	end

	local readingTime = calculateReadingTime(footer, pagesLeft)
	if not readingTime then
		return fallback
	end

	return readingTime .. " " .. FOOTER_CONFIG.CHAPTER_SUFFIX
end

local function getBookText(footer)
	if not canCalculateCustomTime(footer) then
		return nil
	end

	local ok, pagesLeft = pcall(function()
		return footer.ui.document:getTotalPagesLeft(footer.pageno)
	end)
	if not ok or not pagesLeft or pagesLeft <= 0 then
		return nil
	end

	local readingTime = calculateReadingTime(footer, pagesLeft)
	if not readingTime then
		return nil
	end

	return readingTime .. " " .. FOOTER_CONFIG.BOOK_SUFFIX
end

-- Left item: page, time left in chapter, time left in book, or nothing.
-- Side margins are part of the items themselves (as no-break spaces), so
-- KOReader measures and draws exactly the same text and never cuts off the
-- percentage, which happened when they were added after genAllFooterText.
local function getLeftText(footer)
	local mode = getLeftMode()

	-- "none": the whole bar is blank, like the Kindle's empty state.
	if mode == "none" then
		return ""
	end

	local text
	if mode == "page" then
		text = getPageText(footer)
	elseif mode == "book" then
		text = getBookText(footer)
	end

	if not text then
		text = getChapterText(footer)
	end
	if not text or text == "" then
		return text
	end

	return helpers.NO_BREAK_SPACE:rep(FOOTER_CONFIG.FOOTER_LEFT_MARGIN) .. helpers.keepSpaces(text)
end

function footerTextGeneratorMap.percentage(footer)
	if getLeftMode() == "none" then
		return ""
	end

	local text = original_percentage(footer)
	if not text or text == "" then
		return text
	end
	return text .. helpers.NO_BREAK_SPACE:rep(FOOTER_CONFIG.FOOTER_RIGHT_MARGIN)
end

-- Keep the percentage at exactly the same spot whatever is shown on the left.
-- KOReader fills the gap between left and right with whole spaces, so the
-- right-hand item shifted by up to one space width depending on how wide the
-- left text was. The left text is padded with hair spaces to close that gap.
local function measureText(footer, text)
	local widget = FooterTextWidget:new{
		text = text,
		face = footer.footer_text_face,
		bold = footer.settings.text_font_bold,
	}
	local width = widget:getSize().w
	widget:free()
	return width
end

-- Invisible spaces of different widths: mixing them lets the padding fill
-- the gap to the exact pixel.
local PAD_CHARS = {
	helpers.HAIR_SPACE,
	"\226\128\137", -- thin space
	"\226\128\134", -- six-per-em space
	"\226\128\136", -- punctuation space
}
local MAX_ATTEMPTS = 6
local MAX_CACHED_LINES = 64

-- Widths only change with the font, so everything is measured once per face.
local face_caches = setmetatable({}, { __mode = "k" })

local function getFaceCache(footer)
	local face = footer.footer_text_face
	local key = footer.settings.text_font_bold and "bold" or "regular"
	face_caches[face] = face_caches[face] or {}
	local cache = face_caches[face][key]
	if not cache or cache.count >= MAX_CACHED_LINES then
		cache = {
			count = 0,
			padding = {},
			pads = cache and cache.pads,
			space_width = cache and cache.space_width,
		}
		face_caches[face][key] = cache
	end
	if not cache.pads then
		cache.pads = {}
		for _, char in ipairs(PAD_CHARS) do
			local width = math.floor(measureText(footer, char:rep(20)) / 20 + 0.5)
			if width > 0 then
				table.insert(cache.pads, { char = char, width = width })
			end
		end
		cache.space_width = math.floor(measureText(footer, string.rep(" ", 20)) / 20 + 0.5)
	end
	return cache
end

local measuring = false
local candidate_padding = ""

local function measureLine(footer, padding)
	candidate_padding = padding
	return measureText(footer, (footer:genAllFooterText()))
end

-- Build the line without padding (KOReader adds its filler), plan padding
-- for the gap that is left, then measure the padded line and correct the
-- plan until the line ends exactly at the bar's end. Never wider than the bar.
-- A gap the padding can't fill exactly (e.g. 1px when the narrowest space is
-- 2px) is filled as gap + one space instead: KOReader's filler then drops a
-- space, and the line still ends at the same pixel.
local function findPadding(footer, target, cache)
	local plain_width = measureLine(footer, "")
	local best, best_width = "", plain_width
	if plain_width >= target then
		return best
	end

	local want = target - plain_width
	for _ = 1, MAX_ATTEMPTS do
		local padding, exact = helpers.planPadding(want, cache.pads)
		if not exact and cache.space_width > 0 then
			want = want + cache.space_width
			padding = helpers.planPadding(want, cache.pads)
		end
		if padding == "" then
			break
		end
		local width = measureLine(footer, padding)
		if width <= target and width > best_width then
			best, best_width = padding, width
		end
		if width == target then
			break
		end
		want = want + (target - width)
		if want <= 0 then
			break
		end
	end
	return best
end

local function getPaddedLeftText(footer, text)
	local target = helpers.getFillerTarget(
		footer.settings,
		footer._saved_screen_width,
		footer.horizontal_margin,
		Screen:scaleBySize(footer.settings.progress_margin_width or 0)
	)
	if not target then
		return text
	end

	local cache = getFaceCache(footer)
	if #cache.pads == 0 then
		return text
	end

	measuring = true
	candidate_padding = ""
	local ok, line = pcall(footer.genAllFooterText, footer)
	local key = ok and line and (target .. "|" .. line)
	local padding = key and cache.padding[key]
	if key and not padding then
		ok, padding = pcall(findPadding, footer, target, cache)
		if ok then
			cache.padding[key] = padding
			cache.count = cache.count + 1
		end
	end
	measuring = false

	if not ok or not padding then
		return text
	end
	return text .. padding
end

function footerTextGeneratorMap.chapter_time_to_read(footer)
	local text = getLeftText(footer)
	if not text or text == "" then
		return text
	end
	if measuring then
		return text .. candidate_padding
	end
	if not footer.footer_text_face or not footer._saved_screen_width or not footer.horizontal_margin then
		return text
	end

	local ok, padded = pcall(getPaddedLeftText, footer, text)
	if not ok then
		return text
	end
	return padded
end

-- A tap on the status bar cycles the left item, like the Kindle's own reader.
-- KOReader keeps handling the tap when cycling is turned off, the status bar
-- is locked or hidden, or the page slider is open.
local function isFooterHidden(footer)
	return footer.mode_list and footer.mode == footer.mode_list.off
end

function ReaderFooter:TapFooter(ges)
	if not FOOTER_CONFIG.TAP_TO_CYCLE
		or self.view.flipping_visible
		or self.settings.lock_tap
		or isFooterHidden(self) then
		return orig_TapFooter(self, ges)
	end

	G_reader_settings:saveSetting(LEFT_MODE_SETTING, helpers.getNextLeftMode(getLeftMode()))
	self:onUpdateFooter(true)
	return true
end
