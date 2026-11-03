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
	local function add(word, priority, exact, key)
		tick()
		key = key or self.Normalize(word)
		if key == prefix or (not exact and key:sub(1, bytes) ~= prefix) or seen[key] then return end
		seen[key] = true
		best[#best + 1] = {word=word, key=key, priority=priority, rank=self.common[key] or 99999}
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
	local results = {}
	for _, item in ipairs(best) do results[#results + 1] = item.word end
	return results
end

function E:CompletionToken(text, cursor)
	for _, token in ipairs(self:Tokens(text)) do
		-- Complete only at a word's end, never replace an untyped suffix.
		if token.last == cursor and U.Length(token.word) >= 3 and U.IsWord(token.word) then return token end
	end
end
