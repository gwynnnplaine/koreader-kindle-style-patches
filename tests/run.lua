-- Minimal busted-compatible runner: lua tests/run.lua

local failures, total = 0, 0
local current_describe = ""

local function fail(message)
	failures = failures + 1
	io.write(string.format("  FAIL %s: %s\n", current_describe, message))
end

local function equal(expected, actual)
	total = total + 1
	if expected ~= actual then
		fail(string.format("expected %s, got %s", tostring(expected), tostring(actual)))
	end
end

local function is_nil(actual)
	total = total + 1
	if actual ~= nil then
		fail(string.format("expected nil, got %s", tostring(actual)))
	end
end

_G.assert = setmetatable({
	are = { equal = equal },
	is_nil = is_nil,
}, { __call = function(_, ...) return assert(...) end })

function _G.describe(name, body)
	local outer = current_describe
	current_describe = outer == "" and name or (outer .. " / " .. name)
	body()
	current_describe = outer
end

function _G.it(name, body)
	local outer = current_describe
	current_describe = outer .. " " .. name
	local ok, err = pcall(body)
	if not ok then
		fail(tostring(err))
	end
	current_describe = outer
end

local specs = {}
local listing = io.popen("ls tests/*_spec.lua")
for line in listing:lines() do
	specs[#specs + 1] = line
end
listing:close()

for _, spec in ipairs(specs) do
	io.write(spec .. "\n")
	dofile(spec)
end

io.write(string.format("\n%d assertions, %d failures\n", total, failures))
os.exit(failures == 0 and 0 or 1)
