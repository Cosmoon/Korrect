local _, ns = ...
local A, UI, E = {}, ns.UI, ns.Engine
ns.Autofill = A

function A:Cancel()
	self.pending, self.job, self.box, self.token, self.snapshot, self.cursor = nil, nil, nil, nil, nil, nil
	if UI.completion then UI.completion:Hide() end
end

function A:Schedule(box)
	self:Cancel()
	if not ns.db.autofill or not ns.db.enabled or not box:IsShown() or not ns.Chat:ChannelEnabled(box) then return end
	self.box = box
	self.snapshot, self.cursor = UI:RawText(box)
	self.pending = GetTime() + 0.3
	ns.WakeChat()
end

function A:Current()
	if not self.box or not self.box:IsShown() or not ns.db.enabled or not ns.db.autofill
		or not ns.Chat:ChannelEnabled(self.box) then return false end
	local text, cursor = UI:RawText(self.box)
	return text == self.snapshot and cursor == self.cursor
end

function A:Update()
	if not self.box then return end
	if not self:Current() then self:Cancel(); return end
	if self.pending and GetTime() >= self.pending then
		self.pending = nil
		self.token = E:CompletionToken(self.snapshot, self.cursor)
		if not self.token then self:Cancel(); return end
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
				if #results > 0 then UI:ShowCompletions(self.box, results) else self:Cancel() end
				return
			end
			if not debugprofilestop or debugprofilestop()-start >= 2 then break end
		end
	end
end

function A:Apply(word)
	if not self:Current() or not self.token then self:Cancel(); return end
	local box = self.box
	local text, cursor = E.Replace(self.snapshot, self.token, word, self.cursor)
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
