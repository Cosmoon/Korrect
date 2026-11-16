local _, ns = ...
local A, UI, E = {}, ns.UI, ns.Engine
ns.Autofill = A

-- Why the last completion attempt stopped, for /korrect debug.
A.status = "idle"

-- First list after a short pause; once the list is open it follows the word
-- as you keep typing and closes only when nothing matches any more.
local FIRST_DELAY, LIVE_DELAY = 0.3, 0.05

function A:Cancel(reason)
	if reason then self.status = reason end
	self.pending, self.job, self.box, self.token, self.snapshot, self.cursor = nil, nil, nil, nil, nil, nil
	if UI.completion then UI.completion:Hide() end
end

function A:Schedule(box)
	local live = self.box == box and UI.completion and UI.completion:IsShown()
	if not ns.db.autofill or not ns.db.enabled or not box:IsShown() or not ns.Chat:ChannelEnabled(box)
		or ns.Compat:ChatLocked() then
		self:Cancel(ns.Compat:ChatLocked() and "chat locked" or "off for this channel")
		return
	end
	if not live then self:Cancel() end
	self.job, self.token = nil, nil
	self.box = box
	self.status = live and "updating the open list" or "waiting for a pause"
	self.snapshot, self.cursor = UI:RawText(box)
	self.pending = GetTime() + (live and LIVE_DELAY or FIRST_DELAY)
	ns.WakeChat()
end

function A:Current()
	if not self.box or not self.box:IsShown() or not ns.db.enabled or not ns.db.autofill
		or not ns.Chat:ChannelEnabled(self.box) then return false end
	local text, cursor = UI:RawText(self.box)
	if text ~= self.snapshot then return false end
	-- Some clients report the caret a moment after OnTextChanged. While waiting
	-- for the pause only the text must match; the caret is read when it ends.
	return self.pending ~= nil or cursor == self.cursor
end

function A:Update()
	if not self.box then return end
	if not self:Current() then self:Cancel("text changed"); return end
	if self.pending and GetTime() >= self.pending then
		self.pending = nil
		self.snapshot, self.cursor = UI:RawText(self.box)
		self.token = E:CompletionToken(self.snapshot, self.cursor)
		if not self.token then self:Cancel("caret not at the end of a word of 3+ letters"); return end
		self.status = "searching"
		self.job = coroutine.create(function()
			return E:Complete(self.token.word, ns.db, function() coroutine.yield() end)
		end)
	end
	if self.job then
		local start = debugprofilestop and debugprofilestop() or 0
		for i=1,20 do
			local ok, results = coroutine.resume(self.job)
			if not ok then self:Cancel(); geterrorhandler()(results); return end
			if coroutine.status(self.job) == "dead" then
				self.job = nil
				if #results > 0 then
					self.status = "shown " .. #results .. " for '" .. self.token.word .. "'"
					UI:ShowCompletions(self.box, results)
				else self:Cancel("no words start with '" .. self.token.word .. "'") end
				return
			end
			if not debugprofilestop or debugprofilestop()-start >= 2 then break end
		end
	end
end

function A:Apply(word)
	if not self:Current() or ns.Compat:ChatLocked() then self:Cancel(); return end
	local box = self.box
	-- The list can be a few milliseconds behind the text while it follows your
	-- typing, so complete the word that is in the box right now.
	local current, caret = UI:RawText(box)
	local token = E:CompletionToken(current, caret)
	if not token then self:Cancel(); return end
	local text, cursor = E.Replace(current, token, word, caret)
	local maxBytes = box.GetMaxBytes and box:GetMaxBytes() or 0
	local maxLetters = box.GetMaxLetters and box:GetMaxLetters() or 0
	if not text or (maxBytes > 0 and #text > maxBytes)
		or (maxLetters > 0 and (strlenutf8 and strlenutf8(text) or ns.Unicode.Length(text)) > maxLetters) then
		ns.PrintMessage("That completion would exceed the chat length limit."); return
	end
	self:Cancel()
	UI:ClearMarks(box)
	box:SetText(text); box:SetCursorPosition(cursor); box:SetFocus()
	self:Cancel() -- Do not reopen suggestions just because a choice was applied.
end
