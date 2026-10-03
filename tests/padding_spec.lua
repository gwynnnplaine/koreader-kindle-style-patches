local helpers = dofile("src/helpers.lua")
local planPadding = helpers.planPadding
local getFillerTarget = helpers.getFillerTarget

local PADS = {
	{ char = "h", width = 2 },
	{ char = "t", width = 3 },
}

local function width(padding)
	local total = 0
	for char in padding:gmatch(".") do
		total = total + (char == "h" and 2 or 3)
	end
	return total
end

describe("planPadding()", function()
	it("fills every gap exactly when the widths allow it", function()
		for gap = 2, 30 do
			assert.are.equal(gap, width(planPadding(gap, PADS)))
		end
	end)

	it("uses as few characters as possible", function()
		assert.are.equal(3, #planPadding(9, PADS))
		assert.are.equal(4, #planPadding(11, PADS))
	end)

	it("says whether the gap is hit exactly", function()
		local _, exact = planPadding(7, PADS)
		assert.are.equal(true, exact)
		_, exact = planPadding(1, PADS)
		assert.are.equal(false, exact)
	end)

	it("never goes over the gap when it can't be hit exactly", function()
		assert.are.equal("", (planPadding(1, PADS)))
		assert.are.equal("hh", (planPadding(5, { { char = "h", width = 2 } })))
	end)

	it("adds nothing for no gap", function()
		assert.are.equal("", planPadding(0, PADS))
		assert.are.equal("", planPadding(-3, PADS))
		assert.are.equal("", planPadding(nil, PADS))
	end)
end)

describe("getFillerTarget()", function()
	it("uses the status bar margins without a progress bar", function()
		assert.are.equal(580, getFillerTarget({ disable_progress_bar = true, align = "center" }, 600, 10, 25))
	end)

	it("uses the progress bar margins for a centered bar with a progress bar", function()
		assert.are.equal(550, getFillerTarget({ disable_progress_bar = false, align = "center" }, 600, 10, 25))
	end)

	it("uses the status bar margins for a left-aligned bar with a progress bar", function()
		assert.are.equal(580, getFillerTarget({ disable_progress_bar = false, align = "left" }, 600, 10, 25))
	end)

	it("has no target when the progress bar sits alongside the text", function()
		assert.is_nil(getFillerTarget({ disable_progress_bar = false, progress_bar_position = "alongside" }, 600, 10, 25))
	end)
end)
