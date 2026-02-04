-- Modify these values to customize the header appearance
local HEADER_CONFIG = {
    -- Spacing
    top_padding = 12,          -- Top margin in pixels
    -- Font
    font_face = "ffont",       -- Font name
    font_size = 16,            -- Font size in pixels
    font_bold = true,         --  Use bold font?
    font_color = nil,          -- Font color (nil = COLOR_BLACK)
    -- Margins
    use_book_margins = true,   -- Use same margins as book for header
    margin = nil,              -- Fallback margin if book margins disabled (nil = Size.padding.large)
    max_width_pct = 100,       -- Maximum width % before truncating (default: 100)
    -- Behavior
    show_for_pdf = false,      -- Show header for PDF/CBZ files?
}

-- ==========================================
-- Implementation - No need to modify below
-- ==========================================
local Blitbuffer = require("ffi/blitbuffer")
local TextWidget = require("ui/widget/textwidget")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local BD = require("ui/bidi")
local Size = require("ui/size")
local Geom = require("ui/geometry")
local Font = require("ui/font")
local datetime = require("datetime")
local Device = require("device")
local Screen = Device.screen
local ReaderView = require("apps/reader/modules/readerview")

local orig_paintTo = ReaderView.paintTo

function ReaderView:paintTo(bb, x, y)
    orig_paintTo(self, bb, x, y)

	if self.render_mode ~= nil and not HEADER_CONFIG.show_for_pdf then
		return
	end

	-- Get configuration values with defaults
	local font_color = HEADER_CONFIG.font_color or Blitbuffer.COLOR_BLACK
	local fallback_margin = HEADER_CONFIG.margin or Size.padding.large

	-- Calculate margins
	local screen_width = Screen:getWidth()
	local left_margin = fallback_margin
	local right_margin = fallback_margin

	if HEADER_CONFIG.use_book_margins and self.document and self.document.getPageMargins then
		local doc_margins = self.document:getPageMargins()
		left_margin = doc_margins.left or fallback_margin
		right_margin = doc_margins.right or fallback_margin
	end

	local margins = left_margin + right_margin
	local avail_width = screen_width - margins

	local time = datetime.secondsToHour(os.time(), G_reader_settings:isTrue("twelve_hour_clock"))

	local function getFittedText(text, max_width_pct)
		if text == nil or text == "" then
			return ""
		end
		local text_widget = TextWidget:new{
			text = text:gsub(" ", "\u{00A0}"), -- no-break-space
			max_width = avail_width * max_width_pct * (1/100),
			face = Font:getFace(HEADER_CONFIG.font_face, HEADER_CONFIG.font_size),
			bold = HEADER_CONFIG.font_bold,
			padding = 0,
		}
		local fitted_text, add_ellipsis = text_widget:getFittedText()
		text_widget:free()
		if add_ellipsis then
			fitted_text = fitted_text .. "…"
		end
		return BD.auto(fitted_text)
	end

	local header_content = getFittedText(time, HEADER_CONFIG.max_width_pct)

	local header_text = TextWidget:new{
		text = header_content,
		face = Font:getFace(HEADER_CONFIG.font_face, HEADER_CONFIG.font_size),
		bold = HEADER_CONFIG.font_bold,
		fgcolor = font_color,
		padding = 0,
	}

	local header_height = header_text:getSize().h + HEADER_CONFIG.top_padding

	local header = CenterContainer:new{
		dimen = Geom:new{ w = screen_width, h = header_height },
		VerticalGroup:new{
			VerticalSpan:new{ width = HEADER_CONFIG.top_padding },
			HorizontalGroup:new{
				HorizontalSpan:new{ width = left_margin },
				header_text,
				HorizontalSpan:new{ width = right_margin },
			},
		},
	}

	header:paintTo(bb, x, y)
end
