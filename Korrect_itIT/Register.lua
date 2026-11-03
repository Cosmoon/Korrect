-- Hands this LoadOnDemand dictionary to Korrect, then drops the local reference.
local _, ns = ...
local register = Korrect and Korrect.RegisterLanguagePack
if register then
	for code, pack in pairs(ns.LanguagePacks or {}) do register(code, pack) end
end
ns.LanguagePacks = nil
