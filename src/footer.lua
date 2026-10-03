local ReaderFooter = require("apps/reader/modules/readerfooter")
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

function footerTextGeneratorMap.chapter_time_to_read(footer)
	return getLeftText(footer)
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
