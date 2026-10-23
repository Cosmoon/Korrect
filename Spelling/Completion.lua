local _, ns = ...
local E, U = ns.Engine, ns.Unicode

-- Reuse sorted length buckets: no second copy of the language dictionaries.
function E:Complete(prefix, options, yieldWork)
	prefix = self.Normalize(prefix)
	if U.Length(prefix) < 3 or not U.IsWord(prefix) then return {} end
	local best, seen, visited = {}, {}, 0
	local function add(word, priority, exact)
		visited = visited + 1
		if yieldWork and visited % 100 == 0 then yieldWork() end
		local key = self.Normalize(word)
		if key == prefix or (not exact and key:sub(1, #prefix) ~= prefix) or seen[key] then return end
		seen[key] = true
		best[#best + 1] = {word=word, key=key, priority=priority, rank=self.common[key] or 99999}
		table.sort(best, function(a, b)
			if a.priority ~= b.priority then return a.priority < b.priority end
			if a.rank ~= b.rank then return a.rank < b.rank end
			if #a.key ~= #b.key then return #a.key < #b.key end
			return a.key < b.key
		end)
		best[4] = nil
	end
	local replacement = options.replacements and options.replacements[prefix]
	if replacement then add(replacement, 0, true) end
	if ns.Session and options.rememberNames ~= false then
		for _, word in pairs(ns.Session.terms) do add(word, 1) end
	end
	for word in pairs(self.personal) do add(word, 2) end
	if options.wowVocabulary then
		for _, word in pairs(self.wowTerms or {}) do add(word, 3) end
	end
	for _, bucket in pairs(self.byLength) do
		local low, high = 1, #bucket + 1
		while low < high do
			local mid = math.floor((low + high) / 2)
			if bucket[mid] < prefix then low = mid + 1 else high = mid end
		end
		while bucket[low] and bucket[low]:sub(1, #prefix) == prefix do
			local word = bucket[low]
			if self.words[word] then add(word, 4) end
			low = low + 1
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
