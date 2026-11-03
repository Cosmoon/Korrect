local _, ns = ...
ns.MaxLanguages = 2
ns.LanguagePacks = ns.LanguagePacks or {}
ns.LanguagePacks.enUS = { chunks = ns.DictionaryChunks, blocked = ns.NoSuggestChunks }
ns.DictionaryChunks, ns.NoSuggestChunks = nil, nil
ns.Languages = {
	{ "enUS", "English (US)" }, { "enGB", "English (UK)" },
	{ "deDE", "Deutsch" }, { "frFR", "Français" },
	{ "esES", "Español" }, { "itIT", "Italiano" },
	{ "nlNL", "Nederlands (NL)" }, { "nlBE", "Nederlands (BE)" },
}

-- Optional dictionaries ship as LoadOnDemand addons, so only the selected
-- languages are parsed and kept in memory. English (US) is built in.
ns.LanguageAddOns = {
	enGB = "Korrect_enGB", deDE = "Korrect_deDE", frFR = "Korrect_frFR",
	esES = "Korrect_esES", itIT = "Korrect_itIT", nlNL = "Korrect_nlNL", nlBE = "Korrect_nlNL",
}
local aliases = { nlBE = "nlNL" } -- NL/BE share the OpenTaal pack.

local function registerPack(code, pack)
	if type(code) ~= "string" or type(pack) ~= "table" or type(pack.chunks) ~= "table" then return false end
	if not ns.LanguageAddOns[code] then return false end
	ns.LanguagePacks[code] = pack
	for alias, target in pairs(aliases) do
		if target == code then ns.LanguagePacks[alias] = pack end
	end
	return true
end
-- Packs loaded straight into this namespace (developer tests) still alias.
for alias, target in pairs(aliases) do
	ns.LanguagePacks[alias] = ns.LanguagePacks[alias] or ns.LanguagePacks[target]
end
if Korrect then Korrect.RegisterLanguagePack = registerPack end

-- Returns the pack for a language, loading its addon the first time.
function ns.LoadLanguagePack(code)
	local pack = ns.LanguagePacks[code]
	if pack then return pack end
	local addon = ns.LanguageAddOns[code]
	local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
	if not addon or not load then return nil end
	local ok, loaded, reason = pcall(load, addon)
	pack = ns.LanguagePacks[code]
	if not pack then
		ns.LanguageLoadErrors = ns.LanguageLoadErrors or {}
		ns.LanguageLoadErrors[code] = (not ok and tostring(loaded)) or (reason and tostring(reason)) or "not installed"
	end
	return pack
end

function ns.LanguageTitle(code)
	for _, entry in ipairs(ns.Languages) do
		if entry[1] == code then return entry[2] end
	end
	return code
end
