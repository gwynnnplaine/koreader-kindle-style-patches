-- Tests for getMinutes function from 2-kindle-time-left patch

local function getMinutes(time_string)
    if not time_string or time_string == "" then
        return 0
    end

    local hours, minutes = time_string:match("(%d+):(%d+)")
    if hours and minutes then
        return tonumber(hours) * 60 + tonumber(minutes)
    end

    hours = time_string:match("(%d+)h")
    minutes = time_string:match("(%d+)m")

    if hours or minutes then
        return (hours and tonumber(hours) * 60 or 0) + (minutes and tonumber(minutes) or 0)
    end

    return 0
end

describe("getMinutes()", function()
    it("should return 0 for nil input", function()
        assert.are.equal(0, getMinutes(nil))
    end)

    it("should return 0 for empty string", function()
        assert.are.equal(0, getMinutes(""))
    end)

    it("should parse HH:MM format correctly", function()
        assert.are.equal(105, getMinutes("01:45"))
        assert.are.equal(0, getMinutes("00:00"))
        assert.are.equal(90, getMinutes("01:30"))
        assert.are.equal(1439, getMinutes("23:59"))
    end)

    it("should parse Xh Ym format correctly", function()
        assert.are.equal(70, getMinutes("1h 10m"))
        assert.are.equal(60, getMinutes("1h"))
        assert.are.equal(10, getMinutes("10m"))
        assert.are.equal(0, getMinutes("0h 0m"))
    end)

    it("should return 0 for invalid format", function()
        assert.are.equal(0, getMinutes("invalid"))
        assert.are.equal(0, getMinutes("abc"))
        assert.are.equal(0, getMinutes("--:--"))
    end)
end)
