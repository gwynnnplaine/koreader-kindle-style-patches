local helpers = dofile("src/helpers.lua")
local keepSpaces = helpers.keepSpaces
local NBSP = "\194\160"

describe("keepSpaces()", function()
	it("turns every normal space into a no-break space", function()
		assert.are.equal("25" .. NBSP .. "mins" .. NBSP .. "left", keepSpaces("25 mins left"))
	end)

	it("leaves text without spaces alone", function()
		assert.are.equal("42%", keepSpaces("42%"))
		assert.are.equal("", keepSpaces(""))
	end)

	it("returns only the text, not the gsub count", function()
		assert.are.equal(1, select("#", keepSpaces("a b")))
	end)
end)
