local CONSTANTS = {
	MINUTES_IN_HOUR = 60,
	NO_MINUTES = 0,
	ONE_MINUTE = 1,
}

local TEXT = {
   	LESS_THAN_A_MINUTE_TEXT = "less than a minute",
	ONE_MINUTE_TEXT = "1 minute",
	MINUTES_TEXT = " minutes",
}

local function getMinutes(time_string)
	if not time_string or time_string == "" then
		return CONSTANTS.NO_MINUTES
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

	return CONSTANTS.NO_MINUTES
end

-- No-break space, written as bytes so every Lua version reads it.
local NO_BREAK_SPACE = "\194\160"

-- KOReader's "compact" status bar squeezes every normal space into a hair
-- space. No-break spaces are left alone, so the words keep their gaps.
local function keepSpaces(text)
	return (text:gsub(" ", NO_BREAK_SPACE))
end

local function formatTime(minutes)
	if minutes <= CONSTANTS.NO_MINUTES then
		return TEXT.LESS_THAN_A_MINUTE_TEXT
	elseif minutes == CONSTANTS.ONE_MINUTE then
		return TEXT.ONE_MINUTE_TEXT
	else
		return minutes .. TEXT.MINUTES_TEXT
	end
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
	formatTime = formatTime,
	getTimeString = getTimeString,
	keepSpaces = keepSpaces,
	NO_BREAK_SPACE = NO_BREAK_SPACE,
}
return helpers
