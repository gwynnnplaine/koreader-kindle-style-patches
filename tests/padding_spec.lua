local helpers = dofile("src/helpers.lua")
local getPaddingCount = helpers.getPaddingCount
local getFillerTarget = helpers.getFillerTarget

describe("getPaddingCount()", function()
	it("fills the gap left at the end of the line", function()
		-- 9px left over, 2px hair spaces: 4 of them fit.
		assert.are.equal(4, getPaddingCount(580, 571, 2))
		assert.are.equal(3, getPaddingCount(580, 574, 2))
	end)

	it("adds nothing when the line already reaches the bar", function()
		assert.are.equal(0, getPaddingCount(580, 580, 2))
		assert.are.equal(0, getPaddingCount(580, 590, 2))
	end)

	it("adds nothing without a usable hair space width", function()
		assert.are.equal(0, getPaddingCount(580, 500, 0))
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
