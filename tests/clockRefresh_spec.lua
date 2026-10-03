-- Runs the real src/header.lua against a fake KOReader.

local function buildKOReader()
	local state = { scheduled = {}, dirty = {} }

	local function widget(size)
		return {
			getSize = function() return size or { w = 50, h = 20 } end,
			getFittedText = function(self) return self.text, false end,
			free = function() end,
			paintTo = function() end,
		}
	end
	local function widgetClass(size)
		return {
			new = function(_, args)
				local w = widget(size)
				w.text = args and args.text
				return w
			end,
		}
	end

	local ReaderView = { paintTo = function() end }
	local Device = {
		screen_saver_mode = false,
		screen = {
			getWidth = function() return 600 end,
			scaleBySize = function(_, value) return value end,
		},
	}
	local ReaderUI = {}
	ReaderUI.instance = { name = "reader" }
	ReaderUI.instance.dialog = ReaderUI.instance

	package.loaded["ffi/blitbuffer"] = { COLOR_BLACK = 0 }
	package.loaded["ui/widget/textwidget"] = widgetClass({ w = 50, h = 20 })
	package.loaded["ui/widget/container/centercontainer"] = widgetClass()
	package.loaded["ui/widget/verticalgroup"] = widgetClass()
	package.loaded["ui/widget/verticalspan"] = widgetClass()
	package.loaded["ui/widget/horizontalgroup"] = widgetClass()
	package.loaded["ui/widget/horizontalspan"] = widgetClass()
	package.loaded["ui/bidi"] = { auto = function(text) return text end }
	package.loaded["ui/size"] = { padding = { large = 10 } }
	package.loaded["ui/geometry"] = { new = function(_, rect) return rect end }
	package.loaded["ui/font"] = { getFace = function() return {} end }
	package.loaded["datetime"] = { secondsToHour = function() return "12:34" end }
	package.loaded["device"] = Device
	package.loaded["apps/reader/modules/readerview"] = ReaderView
	package.loaded["apps/reader/readerui"] = ReaderUI
	package.loaded["ui/uimanager"] = {
		scheduleIn = function(_, seconds, callback)
			state.scheduled[#state.scheduled + 1] = { seconds = seconds, callback = callback }
		end,
		getTopmostVisibleWidget = function()
			if state.top then
				return state.top
			end
			return ReaderUI.instance
		end,
		setDirty = function(_, target, refresh)
			local mode, region = refresh()
			state.dirty[#state.dirty + 1] = { target = target, mode = mode, region = region }
		end,
	}
	_G.G_reader_settings = { isTrue = function() return false end }

	dofile("src/header.lua")

	local view = setmetatable({}, { __index = ReaderView })

	-- Runs the next scheduled callback, the way UIManager would.
	function state.tick()
		local task = table.remove(state.scheduled, 1)
		task.callback()
	end

	return view, state, Device, ReaderUI
end

describe("header clock refresh", function()
	it("schedules one update shortly after the next minute starts", function()
		local view, state = buildKOReader()
		view:paintTo({}, 0, 0)
		view:paintTo({}, 0, 0)

		assert.are.equal(1, #state.scheduled)
		assert.are.equal(true, state.scheduled[1].seconds >= 1 and state.scheduled[1].seconds <= 61)
	end)

	it("redraws only the header strip with a ui refresh, then reschedules", function()
		local view, state = buildKOReader()
		view:paintTo({}, 0, 0)
		state.tick()

		assert.are.equal(1, #state.dirty)
		assert.are.equal("reader", state.dirty[1].target.name)
		assert.are.equal("ui", state.dirty[1].mode)
		assert.are.equal(0, state.dirty[1].region.y)
		assert.are.equal(600, state.dirty[1].region.w)
		-- text height 20 + top_padding 12 + 4 spare pixels
		assert.are.equal(36, state.dirty[1].region.h)
		assert.are.equal(1, #state.scheduled)
	end)

	it("does not redraw while the device sleeps, but keeps the timer", function()
		local view, state, Device = buildKOReader()
		view:paintTo({}, 0, 0)
		Device.screen_saver_mode = true
		state.tick()

		assert.are.equal(0, #state.dirty)
		assert.are.equal(1, #state.scheduled)
	end)

	it("does not redraw over a menu or dialog, but keeps the timer", function()
		local view, state = buildKOReader()
		view:paintTo({}, 0, 0)
		state.top = { name = "ReaderMenu" }
		state.tick()

		assert.are.equal(0, #state.dirty)
		assert.are.equal(1, #state.scheduled)

		state.top = nil
		state.tick()
		assert.are.equal(1, #state.dirty)
	end)

	it("stops when no book is open and restarts on the next paint", function()
		local view, state, _, ReaderUI = buildKOReader()
		view:paintTo({}, 0, 0)
		ReaderUI.instance = nil
		state.tick()

		assert.are.equal(0, #state.dirty)
		assert.are.equal(0, #state.scheduled)

		ReaderUI.instance = { name = "reader" }
		ReaderUI.instance.dialog = ReaderUI.instance
		view:paintTo({}, 0, 0)
		assert.are.equal(1, #state.scheduled)
	end)
end)
