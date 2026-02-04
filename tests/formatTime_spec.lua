-- Tests for formatTime function from 2-mimic-kindle-ui-patch patch

local function formatTime(minutes)
	if minutes <= 0 then
		return "Less than a minute"
	elseif minutes == 1 then
		return "1 minute"
	else
		return minutes .. " minutes"
	end
end

describe("formatTime()", function()
	it("should handle zero or negative minutes", function()
		assert.are.equal("Less than a minute", formatTime(0))
		assert.are.equal("Less than a minute", formatTime(-5))
	end)

	it("should handle singular minute", function()
		assert.are.equal("1 minute", formatTime(1))
	end)

	it("should handle plural minutes", function()
		assert.are.equal("5 minutes", formatTime(5))
		assert.are.equal("60 minutes", formatTime(60))
		assert.are.equal("120 minutes", formatTime(120))
	end)
end)
