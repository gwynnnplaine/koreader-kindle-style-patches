local CONSTANTS = {
	MINUTES_IN_HOUR = 60,
	NO_MINUTES = 0,
	ONE_MINUTE = 1,
}

local TEXT = {
	ONE_MINUTE_TEXT = "1 min",
	MINUTES_TEXT = " mins",
	ONE_HOUR_TEXT = " hr",
	HOURS_TEXT = " hrs",
}

-- No-break space and hair space, written as bytes so every Lua version reads them.
local NO_BREAK_SPACE = "\194\160"
local HAIR_SPACE = "\226\128\138"

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

-- Kindle wording: "1 min", "25 mins", "1 hr", "4 hrs 40 mins".
local function formatMinutes(minutes)
	if minutes <= CONSTANTS.ONE_MINUTE then
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

-- (target, max_count, measureWith) -> how many padding characters bring the
-- measured width closest to target without going over it.
local function pickPadding(target, max_count, measureWith)
	local best, best_gap = 0, math.huge
	for count = 0, max_count do
		local gap = target - measureWith(count)
		if gap >= 0 and gap < best_gap then
			best, best_gap = count, gap
		end
		if gap == 0 then
			break
		end
	end
	return best
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
	normalizeLeftMode = normalizeLeftMode,
	getNextLeftMode = getNextLeftMode,
	pickPadding = pickPadding,
	NO_BREAK_SPACE = NO_BREAK_SPACE,
	HAIR_SPACE = HAIR_SPACE,
}
return helpers
