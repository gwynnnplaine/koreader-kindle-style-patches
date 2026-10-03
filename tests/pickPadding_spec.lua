local helpers = dofile("src/helpers.lua")
local pickPadding = helpers.pickPadding

describe("pickPadding()", function()
	it("picks the count that lands exactly on the target", function()
		-- 100 + 3 * count: three padding characters reach 109 exactly.
		assert.are.equal(3, pickPadding(109, 10, function(count) return 100 + 3 * count end))
	end)

	it("stops measuring once the target is hit", function()
		local calls = 0
		pickPadding(106, 10, function(count)
			calls = calls + 1
			return 100 + 3 * count
		end)
		assert.are.equal(3, calls)
	end)

	it("never goes over the target", function()
		assert.are.equal(3, pickPadding(110, 10, function(count) return 100 + 3 * count end))
	end)

	it("handles a line that wraps back after a whole extra space", function()
		-- The filler loses a whole space (10) once the padding reaches 5.
		local function width(count)
			local filler = count >= 5 and 40 or 50
			return 520 + 2 * count + filler
		end
		assert.are.equal(4, pickPadding(580, 6, width))
	end)

	it("returns 0 when every candidate is too wide", function()
		assert.are.equal(0, pickPadding(50, 5, function() return 100 end))
	end)
end)
