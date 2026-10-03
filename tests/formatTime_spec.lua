local helpers = dofile("src/helpers.lua")
local formatTime = helpers.formatTime

describe("formatTime()", function()
	it("says when less than a minute is left", function()
		assert.are.equal("less than 1 min", formatTime(0))
		assert.are.equal("less than 1 min", formatTime(-5))
	end)

	it("uses the singular for one minute", function()
		assert.are.equal("1 min", formatTime(1))
	end)

	it("uses Kindle wording below an hour", function()
		assert.are.equal("5 mins", formatTime(5))
		assert.are.equal("59 mins", formatTime(59))
	end)

	it("shows whole hours without minutes", function()
		assert.are.equal("1 hr", formatTime(60))
		assert.are.equal("2 hrs", formatTime(120))
	end)

	it("shows hours and minutes together", function()
		assert.are.equal("1 hr 1 min", formatTime(61))
		assert.are.equal("4 hrs 40 mins", formatTime(280))
	end)
end)
