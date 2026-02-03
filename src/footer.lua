local ReaderFooter = require("apps/reader/modules/readerfooter")
local userpatch = require("userpatch")
local helpers = require("helpers").helpers

local CONFIG = require("config").CONFIG

local orig_genFooterText = ReaderFooter.genAllFooterText
local footerTextGeneratorMap = userpatch.getUpValue(ReaderFooter.applyFooterMode, "footerTextGeneratorMap")
local original_chapter_time_to_read = footerTextGeneratorMap.chapter_time_to_read

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
	local result = string.format("%-" .. CONFIG.LABEL_MIN_WIDTH .. "s %s", CONFIG.LABEL_TEXT, time)
	return result
end

function footerTextGeneratorMap.chapter_time_to_read(footer)
	local fallback = original_chapter_time_to_read(footer)

	if not canCalculateCustomTime(footer) then
		return fallback
	end

	local pagesLeft = getPagesLeftInChapter(footer)
	if not pagesLeft then
		return fallback
	end

	if pagesLeft == 0 then
		return CONFIG.CHAPTER_COMPLETED_TEXT
	end

	local readingTime = calculateReadingTime(footer, pagesLeft)
	if not readingTime then
		return fallback
	end

	local result = formatChapterTimeDisplay(readingTime)
	return result
end

-- Override genAllFooterText for margins
function ReaderFooter:genAllFooterText(...)
	local text, is_filler_inside = orig_genFooterText(self, ...)
	local left_margin = string.rep(" ", CONFIG.FOOTER_LEFT_MARGIN)
	local right_margin = string.rep(" ", CONFIG.FOOTER_RIGHT_MARGIN)
	return left_margin .. text .. right_margin, is_filler_inside
end
