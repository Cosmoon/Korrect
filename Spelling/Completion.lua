local _, ns = ...
local E, U = ns.Engine, ns.Unicode

-- Reuse sorted length buckets: no second copy of the language dictionaries.
local function better(a, b)
	if a.priority ~= b.priority then return a.priority < b.priority end
	if a.rank ~= b.rank then return a.rank < b.rank end
	if #a.key ~= #b.key then return #a.key < #b.key end
	return a.key < b.key
end

function E:Complete(prefix, options, yieldWork)
	prefix = self.Normalize(prefix)
	local prefixLength = U.Length(prefix)
	if prefixLength < 3 or not U.IsWord(prefix) then return {} end
	local best, seen, visited = {}, {}, 0
	local bytes = #prefix
	local function tick()
		visited = visited + 1
		if yieldWork and visited % 100 == 0 then yieldWork() end
	end
	-- key is the already-normalized form when the caller has one.
	local function add(word, priority, exact, key, everyday)
		tick()
		key = key or self.Normalize(word)
		if key == prefix or (not exact and key:sub(1, bytes) ~= prefix) or seen[key] then return end
		seen[key] = true
		local rank = self.common[key]
		-- Dictionary words: a common word with one typo beats a rare exact
		-- match (helo -> hello before helot). Names, personal words and WoW
		-- terms (priority 1-3) always stay on top.
		-- Contractions (don't, you're) count as everyday words even when the
		-- frequency list lacks them.
		if priority >= 4 and not rank and not everyday then priority = priority + 3 end
		best[#best + 1] = {word=word, key=key, priority=priority, rank=rank or 99999}
		table.sort(best, better)
		best[4] = nil
	end
	local replacement = options.replacements and options.replacements[prefix]
	if replacement then add(replacement, 0, true) end
	-- These tables are keyed by normalized text, so filter by prefix before any work.
	if ns.Session and options.rememberNames ~= false then
		for key, word in pairs(ns.Session.terms) do
			tick()
			if key:sub(1, bytes) == prefix then add(word, 1, false, key) end
		end
	end
	for key in pairs(self.personal) do
		tick()
		if key:sub(1, bytes) == prefix then add(key, 2, false, key) end
	end
	if options.wowVocabulary then
		for key, word in pairs(self.wowTerms or {}) do
			tick()
			if key:sub(1, bytes) == prefix then add(word, 3, false, key) end
		end
	end
	for size, bucket in pairs(self.byLength) do
		if size > prefixLength then
			local low, high = 1, #bucket + 1
			while low < high do
				local mid = math.floor((low + high) / 2)
				if bucket[mid] < prefix then low = mid + 1 else high = mid end
			end
			while bucket[low] and bucket[low]:sub(1, bytes) == prefix do
				local word = bucket[low]
				if self.words[word] then add(word, 4, false, word) end
				low = low + 1
			end
		end
	end
	-- One typo in what was typed so far ("tets" -> test, testing). Tried when
	-- exact matches leave places free or are all rare words, and only from 4
	-- letters on, so short prefixes are not flooded with guesses.
	local commonFound = false
	for _, item in ipairs(best) do if item.rank < 99999 or item.priority < 4 then commonFound = true end end
	if (#best < 3 or not commonFound) and prefixLength >= 4 and rawget(self, "searchSorted") then
		self:FuzzyComplete(prefix, add, yieldWork)
	end
	local results = {}
	for _, item in ipairs(best) do results[#results + 1] = E.ApostropheCase(item.word) end
	return results
end

-- Words in the language dictionaries that start with candidate (exact).
local function eachPrefixed(self, candidate, visit)
	local bytes, size0 = #candidate, U.Length(candidate)
	for size, bucket in pairs(self.byLength) do
		if size >= size0 then
			local low, high = 1, #bucket + 1
			while low < high do
				local mid = math.floor((low + high) / 2)
				if bucket[mid] < candidate then low = mid + 1 else high = mid end
			end
			local found = 0
			while bucket[low] and bucket[low]:sub(1, bytes) == candidate and found < 200 do
				local word = bucket[low]
				if self.words[word] then visit(word); found = found + 1 end
				low = low + 1
			end
		end
	end
end

-- Single edits of the typed prefix, most likely typing slips first:
--   5 swapped neighbouring letters    tets  -> test
--   6 a letter from a neighbouring key  tewt -> test
--   6 a missing letter                  tst.. -> test
--   5 a missing apostrophe             dont  -> don't
--   7 one extra letter                  tesst -> test
-- The last typed letter is never deleted and nothing is inserted after it:
-- those edits would just complete a shorter or longer prefix.
local alphabet = {}
-- The apostrophe counts as a missing letter too: dont -> don't.
for c in ("abcdefghijklmnopqrstuvwxyz'"):gmatch(".") do alphabet[#alphabet + 1] = c end

-- Real contractions, not possessives (don't, you're, it's, but not tet's).
local shortS = { ["it's"] = true, ["that's"] = true, ["what's"] = true, ["let's"] = true,
	["he's"] = true, ["she's"] = true, ["there's"] = true, ["here's"] = true, ["who's"] = true,
	["where's"] = true, ["how's"] = true, ["when's"] = true, ["why's"] = true }
local function contraction(word)
	return word:find("n't$") or word:find("'re$") or word:find("'ve$") or word:find("'ll$")
		or word:find("'m$") or word:find("'d$") or shortS[word] or false
end

function E:FuzzyComplete(prefix, add, yieldWork)
	local chars = U.Characters(prefix)
	local n = #chars
	local keyboard = self.Keyboard or {}
	local tried = { [prefix] = true }
	local count = 0
	local function try(candidate, priority)
		if tried[candidate] then return end
		tried[candidate] = true
		local apostrophe = candidate:find("'", 1, true) and not prefix:find("'", 1, true)
		eachPrefixed(self, candidate, function(word)
			add(word, priority, true, word, apostrophe and contraction(word))
		end)
		count = count + 1
		if yieldWork and count % 8 == 0 then yieldWork() end
	end
	local function join(list) return table.concat(list) end
	for i = 1, n - 1 do
		if chars[i] ~= chars[i + 1] then
			chars[i], chars[i + 1] = chars[i + 1], chars[i]
			try(join(chars), 5)
			chars[i], chars[i + 1] = chars[i + 1], chars[i]
		end
	end
	for i = 1, n do
		local typed = chars[i]
		for near in (keyboard[typed] or ""):gmatch(".") do
			chars[i] = near
			try(join(chars), 6)
		end
		chars[i] = typed
	end
	-- Insert before any typed letter (never after the last one).
	for i = 1, n do
		local before, after = table.concat(chars, "", 1, i - 1), table.concat(chars, "", i, n)
		for _, c in ipairs(alphabet) do
			if not (c == "'" and i == 1) then try(before .. c .. after, c == "'" and 5 or 6) end
		end
	end
	for i = 1, n - 1 do
		try(table.concat(chars, "", 1, i - 1) .. table.concat(chars, "", i + 1, n), 7)
	end
end

function E:CompletionToken(text, cursor)
	for _, token in ipairs(self:Tokens(text)) do
		-- Complete only at a word's end, never replace an untyped suffix.
		if token.last == cursor and U.Length(token.word) >= 3 and U.IsWord(token.word) then return token end
	end
end
