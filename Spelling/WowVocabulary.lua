local _, ns = ...
local U = ns.Unicode
local function normalize(text)
	return (U.Lower(text):gsub("%s+", " "))
end

function ns.BuildWowVocabulary(engine, languages)
	engine.wowAccepted, engine.wowPhrases, engine.wowNoSuggest = {}, {}, {}
	engine.wowTerms = {}
	local selected = { enUS = true }
	for locale in pairs(languages) do
		selected[locale == "nlBE" and "nlNL" or locale == "enGB" and "enUS" or locale] = true
	end
	local seen = {}
	for locale in pairs(selected) do
		for category, chunk in pairs((ns.WowVocabulary or {})[locale] or {}) do
			for term in chunk:gmatch("[^\r\n]+") do
				local word = normalize(term)
				engine.wowTerms[word] = engine.wowTerms[word] or term
				-- Imported terms are acceptance-only. Jargon also suppresses legacy
				-- suggestions, so abbreviations are never offered as corrections.
				if category == "Jargon" or U.IsUpper(term) then engine.wowNoSuggest[word] = true end
				if not seen[word] then
					seen[word] = true
					if U.IsWord(word) then
						engine.wowAccepted[word] = true
					else
						local tokens = engine:Tokens(word)
						if #tokens > 0 then
							local key = normalize(tokens[1].word)
							local bucket = engine.wowPhrases[key] or {}
							engine.wowPhrases[key] = bucket
							bucket[#bucket + 1] = { text = word, count = #tokens,
								prefix = tokens[1].first - 1, suffix = #word - tokens[#tokens].last }
						end
					end
				end
			end
		end
	end
	for _, bucket in pairs(engine.wowPhrases) do
		table.sort(bucket, function(a, b) return #a.text > #b.text end)
	end
end

local function boundary(char)
	return not char or (not U.IsLetter(char) and not U.IsMark(char) and not char:match("%d"))
end

function ns.MatchWowVocabulary(engine, text, tokens)
	local accepted, i = {}, 1
	while i <= #tokens do
		local matched = i - 1
		for _, phrase in ipairs((engine.wowPhrases or {})[normalize(tokens[i].word)] or {}) do
			local last = i + phrase.count - 1
			if tokens[last] then
				local firstByte = tokens[i].first - phrase.prefix
				local lastByte = tokens[last].last + phrase.suffix
				if firstByte >= 1 and lastByte <= #text
					and normalize(text:sub(firstByte, lastByte)) == phrase.text then
					local before = U.Characters(text:sub(1, firstByte - 1))
					local after = U.Characters(text:sub(lastByte + 1))
					if boundary(before[#before]) and boundary(after[1]) then
						matched = last; break
					end
				end
			end
		end
		for index = i, matched do accepted[index] = true end
		i = math.max(i + 1, matched + 1)
	end
	return accepted
end
