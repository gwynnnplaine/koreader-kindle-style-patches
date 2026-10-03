local ReaderFooter = require("apps/reader/modules/readerfooter")
local userpatch = require("userpatch")
local helpers = require("helpers").helpers

local FOOTER_CONFIG = {
	CHAPTER_COMPLETED_TEXT = "Chapter completed",
	LABEL_TEXT = "Time left in chapter:",
	LABEL_MIN_WIDTH = 5, -- Minimum character width for label (for alignment)
	FOOTER_LEFT_MARGIN = 1, -- Character spaces on left
	FOOTER_RIGHT_MARGIN = 2, -- Character spaces on right
}

local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")
local original_chapter_time_to_read = footerTextGeneratorMap.chapter_time_to_read
local original_percentage = footerTextGeneratorMap.percentage

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

	if not timeString then
		return nil
	end

	local minutes = helpers.getMinutes(timeString)

	local formattedTime = helpers.formatTime(minutes)

	return formattedTime
end

local function formatChapterTimeDisplay(time)
	local result = string.format("%-" .. FOOTER_CONFIG.LABEL_MIN_WIDTH .. "s %s", FOOTER_CONFIG.LABEL_TEXT, time)
	return result
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

	local result = formatChapterTimeDisplay(readingTime)
	return result
end

-- Side margins are part of the items themselves (as no-break spaces), so
-- KOReader measures and draws exactly the same text. Adding them after
-- genAllFooterText made the line wider than the bar, and KOReader then cut
-- the percentage down to "…".
local function addMargins(text, left, right)
	if not text or text == "" then
		return text
	end
	return helpers.NO_BREAK_SPACE:rep(left) .. helpers.keepSpaces(text) .. helpers.NO_BREAK_SPACE:rep(right)
end

function footerTextGeneratorMap.chapter_time_to_read(footer)
	return addMargins(getChapterText(footer), FOOTER_CONFIG.FOOTER_LEFT_MARGIN, 0)
end

function footerTextGeneratorMap.percentage(footer)
	return addMargins(original_percentage(footer), 0, FOOTER_CONFIG.FOOTER_RIGHT_MARGIN)
end
