local _, ns = ...
local AC = {}
ns.Autocorrect = AC
local Engine, UI, U = ns.Engine, ns.UI, ns.Unicode

-- Autocorrect. Every source can be switched off separately (all on by default):
--   * the player's own replacements,
--   * the curated English TypoHints list (teh -> the, recieve -> receive),
--   * fast-typing slips: swapped letters, a missing letter, or one or two
--     letters typed with a neighbouring key (see AC:Guess).
-- A word is corrected when it is finished with a space or punctuation, and a
-- Backspace straight after a correction restores what was typed and ignores
-- that word for the rest of the session.

local boundaries = { [" "] = true, ["."] = true, [","] = true, ["!"] = true,
	["?"] = true, [";"] = true, [":"] = true, [")"] = true }

-- Per-box state. Weak keys: never store our own fields on Blizzard's boxes.
local undo = setmetatable({}, { __mode = "k" })

-- Letters tried when inserting or replacing a character. Accented letters
-- matter mostly as competitors, so a French or German word is not overruled.
local alphabet = U.Characters("abcdefghijklmnopqrstuvwxyzàâäáãåçéèêëíìîïñóòôöõúùûüýÿßœæ")

local function suggestible(word)
	local db, E = ns.db, Engine
	if E.words and E.words[word] == true then return true end
	if db.personalWords[word] then return true end
	if db.wowVocabulary and (E.wow[word] or (E.wowAccepted and E.wowAccepted[word]))
		and not (E.wowNoSuggest and E.wowNoSuggest[word]) then return true end
	return false
end

local function neighbours(typed, intended)
	local keyboard = Engine.Keyboard or {}
	return (keyboard[intended] and keyboard[intended]:find(typed, 1, true))
		or (keyboard[typed] and keyboard[typed]:find(intended, 1, true)) or false
end

local function only(set)
	local found
	for word in pairs(set) do
		if found then return nil end
		found = word
	end
	return found
end

-- Guess the intended word for a fast-typing slip, or nil when unsure.
-- Every single edit that gives a known word is sorted by kind:
--   1 swapped neighbouring letters          (tetsing -> testing)
--   2 one missing letter or a doubled one    (forver -> forever, untill -> until)
--   3 one letter from a neighbouring key, or
--     an extra letter from a neighbouring key (hwlp -> help)
--   - any other single edit: too random to act on, and ignored.
-- If exactly one kind found words and it found exactly one, that word wins.
-- Otherwise a word is chosen only if it is the single common chat word among
-- all candidates (forver: forever beats forger). The winner's rule must be
-- enabled. Two neighbouring-key letters are tried only for words of six or
-- more letters, and only when no single edit gives any known word.
-- Measured on the English dictionary: no wrong fixes for slips in common chat
-- words; about 0.5% wrong for slips in rare words.
function AC:Guess(word)
	local db = ns.db
	local chars = U.Characters(word)
	local n = #chars
	if n < 4 or n > 20 or word:find("['%-]") then return nil end
	local tiers, any = { {}, {}, {} }, false
	local function try(set, candidate)
		if suggestible(candidate) then set[candidate] = true; any = true end
	end
	for i = 1, n - 1 do
		if chars[i] ~= chars[i + 1] then
			chars[i], chars[i + 1] = chars[i + 1], chars[i]
			try(tiers[1], table.concat(chars))
			chars[i], chars[i + 1] = chars[i + 1], chars[i]
		end
	end
	for i = 0, n do
		local before, after = table.concat(chars, "", 1, i), table.concat(chars, "", i + 1, n)
		for _, char in ipairs(alphabet) do try(tiers[2], before .. char .. after) end
	end
	local unlikely = {}
	for i = 1, n do
		local typed = chars[i]
		for _, char in ipairs(alphabet) do
			if char ~= typed then
				chars[i] = char
				try(neighbours(typed, char) and tiers[3] or unlikely, table.concat(chars))
			end
		end
		chars[i] = typed
		local candidate = table.concat(chars, "", 1, i - 1) .. table.concat(chars, "", i + 1, n)
		local left, right = chars[i - 1], chars[i + 1]
		local doubled = typed == left or typed == right
		local near = (left and neighbours(typed, left)) or (right and neighbours(typed, right))
		try(doubled and tiers[2] or (near and tiers[3]) or unlikely, candidate)
	end
	local enabled = { db.autocorrectSwaps, db.autocorrectMissing, db.autocorrectKeys }
	local filled = (next(tiers[1]) and 1 or 0) + (next(tiers[2]) and 1 or 0) + (next(tiers[3]) and 1 or 0)
	if filled == 1 then
		for tier = 1, 3 do
			if next(tiers[tier]) then
				if not enabled[tier] then return nil end
				local single = only(tiers[tier])
				if single then return single end
			end
		end
	end
	if filled >= 1 then
		-- Several plausible words: choose one only if it is the single common
		-- chat word among them, and it came from an enabled rule.
		local pick, pickTier
		for tier = 1, 3 do
			for candidate in pairs(tiers[tier]) do
				if Engine.common[candidate] or (db.wowVocabulary and Engine.wow[candidate]) then
					if pick and pick ~= candidate then return nil end
					pick, pickTier = candidate, tier
				end
			end
		end
		if pick and enabled[pickTier] then return pick end
		return nil
	end
	if any or not db.autocorrectKeys or n < 6 then return nil end
	-- Two letters from neighbouring keys, only for longer words.
	local keyboard, found = Engine.Keyboard or {}, {}
	for i = 1, n - 1 do
		local a = chars[i]
		for near in (keyboard[a] or ""):gmatch(".") do
			chars[i] = near
			for j = i + 1, n do
				local b = chars[j]
				for other in (keyboard[b] or ""):gmatch(".") do
					chars[j] = other
					local candidate = table.concat(chars)
					if suggestible(candidate) then
						found[candidate] = true
						if not only(found) then return nil end
					end
				end
				chars[j] = b
			end
		end
		chars[i] = a
	end
	return only(found)
end
local lengths = setmetatable({}, { __mode = "k" })

-- Changes are never written from inside OnTextChanged: replacing the text of
-- the box during its own change event can leave the caret hidden. The hook
-- only decides; the change is applied on the next frame by AC:Update, and
-- only if the player has not edited the text before it in the meantime.
local pending = setmetatable({}, { __mode = "k" })

local function fits(box, text)
	local maxBytes = box.GetMaxBytes and box:GetMaxBytes() or 0
	local maxLetters = box.GetMaxLetters and box:GetMaxLetters() or 0
	if maxBytes > 0 and #text > maxBytes then return false end
	if maxLetters > 0 and (strlenutf8 and strlenutf8(text) or U.Length(text)) > maxLetters then return false end
	return true
end

local function write(box, text, cursor)
	lengths[box] = #text
	box:SetText(text); box:SetCursorPosition(cursor)
end

function AC:Forget(box)
	if box then undo[box], lengths[box], pending[box] = nil, nil, nil; UI:ClearCorrections(box) end
end

-- The correction for tokens[index], or nil whenever there is any doubt.
function AC:Correction(text, tokens, index)
	local db = ns.db
	local token = tokens[index]
	local word = Engine.Normalize(token.word)
	if U.Length(word) < 2 or ns.Chat:IsIgnored(word) then return nil end
	-- Only plain lowercase or Sentence-case words; mixed case is usually a name.
	if token.word ~= word and token.word ~= U.Title(word) then return nil end
	if db.rememberNames ~= false and ns.Session and ns.MatchWowVocabulary
		and ns.MatchWowVocabulary(ns.Session, text, tokens)[index] then return nil end
	if db.autocorrectReplacements and db.replacements[word] then
		return db.replacements[word], word
	end
	if db.personalWords[word] or Engine:Contains(word, db.wowVocabulary) then return nil end
	if db.wowVocabulary and ns.MatchWowVocabulary
		and ns.MatchWowVocabulary(Engine, text, tokens)[index] then return nil end
	local hint = db.autocorrect and Engine.english and ns.TypoHints and ns.TypoHints[word]
	if hint then
		for piece in hint:gmatch("%S+") do
			if not Engine:Contains(piece, db.wowVocabulary) then hint = nil; break end
		end
		if hint then return hint, word end
	end
	if db.autocorrectSwaps or db.autocorrectMissing or db.autocorrectKeys then
		local guess = self:Guess(word)
		if guess then return guess, word end
	end
	return nil
end

function AC:Active()
	local db = ns.db
	return db.autocorrect or db.autocorrectReplacements or db.autocorrectSwaps
		or db.autocorrectMissing or db.autocorrectKeys
end

-- (pending is declared near the top so AC:Forget can reach it.)

-- Called from the OnTextChanged hook after highlights were cleared.
function AC:OnTextChanged(box, userInput)
	local text, cursor = UI:RawText(box)
	local previous = lengths[box]
	lengths[box] = #text
	if not userInput then return end
	local record = undo[box]
	undo[box] = nil
	local db = ns.db
	if not db.enabled or not self:Active()
		or not ns.Chat:ChannelEnabled(box) or ns.Compat:ChatLocked() then pending[box] = nil; return end

	-- Backspace directly after a correction: put the typed word back.
	if record and text == record.backspaced and cursor == record.cursor - 1 then
		pending[box] = { undo = true, expected = text, cursor = cursor, record = record }
		ns.WakeChat()
		return
	end

	-- Only react to text that just grew by a word-finishing character.
	if not previous or #text <= previous or cursor < 2 then return end
	if not boundaries[text:sub(cursor, cursor)] then return end
	local tokens = Engine:Tokens(text)
	local index
	for i = #tokens, 1, -1 do
		if tokens[i].last == cursor - 1 then index = i; break end
		if tokens[i].last < cursor - 1 then break end
	end
	if not index then return end
	local replacement, word = self:Correction(text, tokens, index)
	if not replacement then return end
	local value, nextCursor = Engine.Replace(text, tokens[index], replacement, cursor)
	if not value then return end
	pending[box] = { expected = text, cursor = cursor, value = value, nextCursor = nextCursor,
		word = word, first = tokens[index].first }
	ns.WakeChat()
end

function AC:HasWork()
	return next(pending) ~= nil
end

local function place(box, text, cursor)
	write(box, text, cursor)
	if box.HasFocus and not box:HasFocus() then box:SetFocus() end
end

-- Apply decisions from the previous frame. If the player kept typing after
-- the boundary character, the change still applies and the new text after it
-- is kept; any edit before that point cancels the correction.
function AC:Update()
	for box, job in pairs(pending) do
		pending[box] = nil
		local text, cursor = UI:RawText(box)
		local expected = job.expected
		local extended = #text >= #expected and text:sub(1, #expected) == expected and cursor >= job.cursor
		if box:IsShown() and ns.db.enabled and not ns.Compat:ChatLocked() and extended then
			local tail, typed = text:sub(#expected + 1), cursor - job.cursor
			if job.undo then
				local record = job.record
				local restored = record.restored .. tail
				ns.Chat:Ignore(record.word)
				if fits(box, restored) then place(box, restored, record.restoredCursor + typed) end
				UI:TrackCorrections(box)
			else
				local value = job.value .. tail
				if fits(box, value) then
					undo[box] = typed == 0 and {
						word = job.word,
						cursor = job.nextCursor,
						backspaced = job.value:sub(1, job.nextCursor - 1) .. job.value:sub(job.nextCursor + 1),
						restored = expected:sub(1, job.cursor - 1) .. expected:sub(job.cursor + 1),
						restoredCursor = job.cursor - 1,
					} or nil
					place(box, value, job.nextCursor + typed)
					-- The replacement ends just before the boundary character the player typed.
					UI:TrackCorrections(box)
					UI:AddCorrection(box, job.first, job.nextCursor - 1)
				end
			end
		end
	end
end
