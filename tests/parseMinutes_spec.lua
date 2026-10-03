local helpers = dofile("src/helpers.lua")
local parseMinutes = helpers.parseMinutes

describe("parseMinutes()", function()
	it("reads KOReader's classic and modern durations", function()
		assert.are.equal(105, parseMinutes("01:45"))
		assert.are.equal(70, parseMinutes("1h 10m"))
		assert.are.equal(10, parseMinutes("10m"))
		assert.are.equal(60, parseMinutes("1h"))
		assert.are.equal(0, parseMinutes("0:00"))
	end)

	it("returns nil for text that is not a reading time", function()
		assert.is_nil(parseMinutes(nil))
		assert.is_nil(parseMinutes(""))
		assert.is_nil(parseMinutes("N/A"))
		assert.is_nil(parseMinutes(42))
	end)

	it("keeps getMinutes() returning 0 for those", function()
		assert.are.equal(0, helpers.getMinutes("N/A"))
		assert.are.equal(0, helpers.getMinutes(nil))
	end)
end)
