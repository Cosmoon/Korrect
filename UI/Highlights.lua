local _, ns = ...
local UI = ns.UI

-- Native edit-box colors. No overlay measuring, resizing, or update polling.
UI.markers = {}

function UI:RawText(box)
	local marker = self.markers[box]
	return ns.Engine.StripHighlights(box:GetText(), marker and marker.prefixes, box:GetCursorPosition())
end

function UI:IsFormatting(box)
	local marker = self.markers[box]
	-- The game can deliver OnTextChanged after SetText has returned. A
	-- call-stack guard alone then treats our own colors as new user input,
	-- strips them, and schedules another highlight indefinitely.
	return marker and (marker.updating or box:GetText() == marker.expectedText)
end

local function setDisplay(box, marker, text, cursor)
	if box:GetText() == text then return end
	marker.expectedText = text
	marker.updating = true
	box:SetText(text)
	box:SetCursorPosition(cursor)
	marker.updating = false
end

-- Retail overlay marks -------------------------------------------------------
-- During chat lockdown Blizzard blocks a message once an addon has written to
-- the input, so Retail never calls SetText for marks. Underlines are drawn on
-- a separate frame anchored over the input's text area instead. Nothing is
-- stored on, parented to or written to Blizzard's edit box.
local overlays = setmetatable({}, { __mode = "k" })
local measure

local function setMeasureFont(box)
	if not measure then
		measure = UIParent:CreateFontString(nil, "BACKGROUND")
		measure:Hide()
	end
	local font, size, flags = box:GetFont()
	if font and not (issecretvalue and issecretvalue(font)) then
		measure:SetFont(font, size, flags or "")
	else
		measure:SetFontObject(box:GetFontObject() or ChatFontNormal)
	end
	return size or 14
end

local function textWidth(text)
	measure:SetText(text)
	return measure.GetUnboundedStringWidth and measure:GetUnboundedStringWidth() or measure:GetStringWidth()
end

-- A single-line edit box scrolls just enough to keep the caret visible.
-- Mirror that so marks line up with the visible part of long messages;
-- anything outside the text area is clipped by the overlay frame.
local function scrollOffset(overlay, cursorX, total, visible)
	local offset = overlay.offset or 0
	if total <= visible then
		offset = 0
	else
		if cursorX - offset > visible then offset = cursorX - visible end
		if cursorX < offset then offset = cursorX end
		if offset > total - visible then offset = total - visible end
		if offset < 0 then offset = 0 end
	end
	overlay.offset = offset
	return offset
end

function UI:HideOverlay(box)
	for editBox, overlay in pairs(overlays) do
		if not box or box == editBox then overlay:Hide() end
	end
end

local function drawOverlay(box, marker, color)
	local overlay = overlays[box]
	if not overlay then
		overlay = CreateFrame("Frame", nil, UIParent)
		if overlay.SetClipsChildren then overlay:SetClipsChildren(true) end
		overlay:EnableMouse(false)
		overlay.lines = {}
		overlays[box] = overlay
	end
	local left, right, top, bottom = box:GetTextInsets()
	left, right, top, bottom = left or 0, right or 0, top or 0, bottom or 0
	overlay:ClearAllPoints()
	overlay:SetPoint("TOPLEFT", box, "TOPLEFT", left, -top)
	overlay:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -right, bottom)
	overlay:SetFrameStrata(box:GetFrameStrata())
	overlay:SetFrameLevel(box:GetFrameLevel() + 3)

	local size = setMeasureFont(box)
	local raw, cursor = UI:RawText(box)
	local visible = math.max(0, (box:GetWidth() or 0) - left - right)
	local offset = scrollOffset(overlay, textWidth(raw:sub(1, cursor)), textWidth(raw), visible)
	local height = (box:GetHeight() or size) - top - bottom
	-- Chat text is vertically centered; sit the line just under the baseline.
	local y = math.max(0, (height - size) / 2 - 1)
	local count = 0
	for _, issue in ipairs(marker.issues) do
		local x1 = textWidth(raw:sub(1, issue.first - 1)) - offset
		local x2 = textWidth(raw:sub(1, issue.last)) - offset
		if x2 > 0 and x1 < visible then
			count = count + 1
			local line = overlay.lines[count]
			if not line then
				line = overlay:CreateTexture(nil, "OVERLAY")
				overlay.lines[count] = line
			end
			line:ClearAllPoints()
			line:SetPoint("BOTTOMLEFT", overlay, "BOTTOMLEFT", x1, y)
			line:SetSize(math.max(1, x2 - x1), 2)
			line:SetColorTexture(color[1], color[2], color[3], 0.95)
			line:Show()
		end
	end
	for i = count + 1, #overlay.lines do overlay.lines[i]:Hide() end
	overlay:SetShown(count > 0 and box:IsShown())
end

local function overlayWanted(box, marker)
	return ns.Compat.overlayMarks and marker and #marker.issues > 0 and box:IsShown()
		and ns.db.showHighlights and ns.db.enabled and ns.Compat:WantsMarks(box)
end

-- Redraw after the caret moves (scrolling) or the input is resized.
function UI:RefreshOverlay(box)
	local marker = self.markers[box]
	if not overlays[box] and not overlayWanted(box, marker) then return end
	if overlayWanted(box, marker) and marker.text == (self:RawText(box)) then
		drawOverlay(box, marker, marker.color or ns.db.highlightColor)
	else
		self:HideOverlay(box)
	end
end

function UI:ClearMarks(box)
	self:HideOverlay(box)
	for editBox, marker in pairs(self.markers) do
		if not box or box == editBox then
			local raw, cursor = self:RawText(editBox)
			setDisplay(editBox, marker, raw, cursor)
			marker.issues, marker.ranges = {}, {}
		end
	end
end

-- Compare against the edit box's actual text color, including custom channel colors.
-- Keep the saved preference unchanged; only the displayed highlight can differ.
local alternatives = { {0.2, 0.85, 1}, {1, 0.25, 0.8}, {1, 1, 0.2}, {0.4, 1, 0.3} }
local function highlightColor(box)
	local chosen = ns.db.highlightColor
	if not box.GetTextColor then return chosen end
	local r, g, b = box:GetTextColor()
	if issecretvalue and (issecretvalue(r) or issecretvalue(g) or issecretvalue(b)) then return chosen end
	if type(r) ~= "number" or type(g) ~= "number" or type(b) ~= "number" then return chosen end
	local function distance(color)
		return 0.299 * (color[1] - r)^2 + 0.587 * (color[2] - g)^2 + 0.114 * (color[3] - b)^2
	end
	-- A weighted RGB distance below 0.2 is treated as visually too similar.
	if distance(chosen) >= 0.04 then return chosen end
	local best, bestDistance = chosen, 0
	for _, color in ipairs(alternatives) do
		local value = distance(color)
		if value > bestDistance then best, bestDistance = color, value end
	end
	return best
end

function UI:ShowMarks(box, issues)
	local marker = self.markers[box]
	if not marker then
		marker = { prefixes = {}, issues = {}, ranges = {} }
		self.markers[box] = marker
	end
	local raw, cursor = self:RawText(box)
	marker.text, marker.issues, marker.ranges = raw, issues, issues
	local color = highlightColor(box)
	-- The private alpha value distinguishes these tags from ordinary |cff
	-- item-link colors. Visually it is effectively opaque.
	local prefix = string.format("|cfe%02x%02x%02x", math.floor(color[1]*255+0.5),
		math.floor(color[2]*255+0.5), math.floor(color[3]*255+0.5))
	marker.prefixes[prefix] = true
	local result, from, decoratedCursor, extra = {}, 1, cursor, 0
	local maxBytes = box.GetMaxBytes and box:GetMaxBytes() or 0
	for _, issue in ipairs(issues) do
		result[#result+1] = raw:sub(from, issue.first-1)
		local highlighted = ns.db.showHighlights and ns.db.enabled and ns.Compat:CanHighlight(box)
			and (maxBytes == 0 or #raw + extra + 12 <= maxBytes)
		if highlighted then
			result[#result+1] = prefix .. issue.word .. "|r"
			extra = extra + 12
			if cursor >= issue.first-1 then decoratedCursor = decoratedCursor + 10 end
			if cursor >= issue.last then decoratedCursor = decoratedCursor + 2 end
		else result[#result+1] = issue.word end
		from = issue.last+1
	end
	result[#result+1] = raw:sub(from)
	local decorated = table.concat(result)
	setDisplay(box, marker, decorated, decoratedCursor)
	-- A client may enforce an additional visible/invisible character limit.
	-- Restore the entire original input if display formatting was truncated.
	if box:GetText() ~= decorated then setDisplay(box, marker, raw, cursor) end
	marker.color = color
	if overlayWanted(box, marker) then drawOverlay(box, marker, color) else self:HideOverlay(box) end
end

function UI:IssueAtMouse(box)
	local marker = self.markers[box]
	if not marker then return end
	local raw, cursor = self:RawText(box)
	if marker.text ~= raw then return end
	for _, issue in ipairs(marker.issues) do
		if cursor >= issue.first-1 and cursor <= issue.last then return issue end
	end
end
