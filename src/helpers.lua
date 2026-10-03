local CONSTANTS = {
	MINUTES_IN_HOUR = 60,
	NO_MINUTES = 0,
	ONE_MINUTE = 1,
}

local TEXT = {
	LESS_THAN_A_MINUTE_TEXT = "less than 1 min",
	ONE_MINUTE_TEXT = "1 min",
	MINUTES_TEXT = " mins",
	ONE_HOUR_TEXT = " hr",
	HOURS_TEXT = " hrs",
}

-- No-break space, written as bytes so every Lua version reads it.
local NO_BREAK_SPACE = "\194\160"

-- (time_string) -> minutes, or nil when the text is not a reading time.
local function parseMinutes(time_string)
	if type(time_string) ~= "string" or time_string == "" then
		return nil
	end

	-- Format: "01:45" (hours:minutes)
	local hours, minutes = time_string:match("(%d+):(%d+)")
	if hours and minutes then
		return tonumber(hours) * CONSTANTS.MINUTES_IN_HOUR + tonumber(minutes)
	end

	-- Format: "1h 10m" or "10m" or "1h"
	hours = time_string:match("(%d+)h")
	minutes = time_string:match("(%d+)m")

	if hours or minutes then
		-- Convert hours to minutes, or use 0 if no hours found
		local hoursInMinutes = CONSTANTS.NO_MINUTES
		if hours then
			hoursInMinutes = tonumber(hours) * CONSTANTS.MINUTES_IN_HOUR
		end

		-- Get minutes value, or use 0 if no minutes found
		local minutesValue = CONSTANTS.NO_MINUTES
		if minutes then
			minutesValue = tonumber(minutes) or CONSTANTS.NO_MINUTES
		end

		return hoursInMinutes + minutesValue
	end

	return nil
end

local function getMinutes(time_string)
	return parseMinutes(time_string) or CONSTANTS.NO_MINUTES
end

-- Kindle wording: "less than 1 min", "1 min", "25 mins", "1 hr", "4 hrs 40 mins".
local function formatMinutes(minutes)
	if minutes <= CONSTANTS.NO_MINUTES then
		return TEXT.LESS_THAN_A_MINUTE_TEXT
	elseif minutes == CONSTANTS.ONE_MINUTE then
		return TEXT.ONE_MINUTE_TEXT
	end
	return minutes .. TEXT.MINUTES_TEXT
end

local function formatTime(minutes)
	if minutes < CONSTANTS.MINUTES_IN_HOUR then
		return formatMinutes(minutes)
	end

	local hours = math.floor(minutes / CONSTANTS.MINUTES_IN_HOUR)
	local rest = minutes % CONSTANTS.MINUTES_IN_HOUR
	local text = hours .. (hours == 1 and TEXT.ONE_HOUR_TEXT or TEXT.HOURS_TEXT)
	if rest > CONSTANTS.NO_MINUTES then
		text = text .. " " .. formatMinutes(rest)
	end
	return text
end

-- KOReader's "compact" status bar squeezes every normal space into a hair
-- space. No-break spaces are left alone, so the words keep their gaps.
local function keepSpaces(text)
	return (text:gsub(" ", NO_BREAK_SPACE))
end

-- What the bottom-left corner shows; a tap on the status bar moves to the next one.
local LEFT_MODES = { "page", "chapter", "book", "none" }
local DEFAULT_LEFT_MODE = "chapter"

local function normalizeLeftMode(mode)
	for _, name in ipairs(LEFT_MODES) do
		if name == mode then
			return mode
		end
	end
	return DEFAULT_LEFT_MODE
end

local function getNextLeftMode(mode)
	for i, name in ipairs(LEFT_MODES) do
		if name == mode then
			return LEFT_MODES[i % #LEFT_MODES + 1]
		end
	end
	return LEFT_MODES[1]
end

-- (face, isRegistered) -> bold face file, or nil when nothing should change.
local function resolveBoldFontFace(face, isRegistered)
	if type(face) ~= "string" or face == "" then
		return nil
	end
	if type(isRegistered) ~= "function" then
		return nil
	end

	local stem, extension = face:match("^(.*)%-Regular(%.[%a%d]+)$")
	if not stem then
		return nil
	end

	local bold_face = stem .. "-Bold" .. extension
	if not isRegistered(bold_face) then
		return nil
	end

	return bold_face
end

local function getTimeString(footer, pages_left)
	-- Method 1: Works on Emulator
	if footer.ui.statistics and footer.ui.statistics.getTimeForPages then
		local ok, time_string = pcall(function()
			return footer.ui.statistics:getTimeForPages(pages_left)
		end)

		if ok and time_string then
			return time_string
		end
	end

	-- Method 2: Works on Kindle
	if footer.getDataFromStatistics then
		local ok, time_string = pcall(function()
			return footer:getDataFromStatistics("", pages_left)
		end)
		if ok and time_string and time_string ~= "" then
			return time_string
		end
	end

	return nil
end

local helpers = {
	resolveBoldFontFace = resolveBoldFontFace,
	getMinutes = getMinutes,
	parseMinutes = parseMinutes,
	formatTime = formatTime,
	getTimeString = getTimeString,
	keepSpaces = keepSpaces,
	normalizeLeftMode = normalizeLeftMode,
	getNextLeftMode = getNextLeftMode,
	NO_BREAK_SPACE = NO_BREAK_SPACE,
}
return helpers
