local helpers = dofile("src/helpers.lua")
local resolveBoldFontFace = helpers.resolveBoldFontFace

local registered = {
	["./fonts/noto/NotoSans-Regular.ttf"] = true,
	["./fonts/noto/NotoSans-Bold.ttf"] = true,
	["./fonts/noto/NotoSerif-Regular.ttf"] = true,
	["./fonts/noto/NotoSerif-Bold.ttf"] = true,
	["/mnt/us/fonts/Lonely-Regular.otf"] = true,
	["/mnt/us/fonts/Paired-Regular.otf"] = true,
	["/mnt/us/fonts/Paired-Bold.otf"] = true,
}
local function isRegistered(file)
	return registered[file] == true
end

describe("resolveBoldFontFace()", function()
	it("returns nil when there is no usable face", function()
		assert.is_nil(resolveBoldFontFace(nil, isRegistered))
		assert.is_nil(resolveBoldFontFace("", isRegistered))
		assert.is_nil(resolveBoldFontFace(14, isRegistered))
	end)

	it("returns nil without a registration predicate", function()
		assert.is_nil(resolveBoldFontFace("./fonts/noto/NotoSans-Regular.ttf", nil))
	end)

	it("returns nil for a face that is not a -Regular file", function()
		assert.is_nil(resolveBoldFontFace("ffont", isRegistered))
		assert.is_nil(resolveBoldFontFace("./fonts/noto/NotoSans-Bold.ttf", isRegistered))
		assert.is_nil(resolveBoldFontFace("./fonts/droid/DroidSansMono.ttf", isRegistered))
	end)

	it("returns nil when the bold sibling is not registered", function()
		assert.is_nil(resolveBoldFontFace("/mnt/us/fonts/Lonely-Regular.otf", isRegistered))
		assert.is_nil(resolveBoldFontFace("./fonts/ghost/Ghost-Regular.ttf", isRegistered))
	end)

	it("resolves the registered bold sibling, keeping directory and extension", function()
		assert.are.equal(
			"./fonts/noto/NotoSans-Bold.ttf",
			resolveBoldFontFace("./fonts/noto/NotoSans-Regular.ttf", isRegistered)
		)
		assert.are.equal(
			"./fonts/noto/NotoSerif-Bold.ttf",
			resolveBoldFontFace("./fonts/noto/NotoSerif-Regular.ttf", isRegistered)
		)
		assert.are.equal(
			"/mnt/us/fonts/Paired-Bold.otf",
			resolveBoldFontFace("/mnt/us/fonts/Paired-Regular.otf", isRegistered)
		)
	end)

	it("only rewrites the trailing -Regular token", function()
		registered["./fonts/Regular-Sans/Regular-Bold.ttf"] = true
		assert.are.equal(
			"./fonts/Regular-Sans/Regular-Bold.ttf",
			resolveBoldFontFace("./fonts/Regular-Sans/Regular-Regular.ttf", isRegistered)
		)
	end)
end)
