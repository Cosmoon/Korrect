local _, ns = ...
local E = ns.Engine
local Session = {terms={}, count=0, wowPhrases={}}
ns.Session = Session
local function safe(value) return not (issecretvalue and issecretvalue(value)) end
local function count(value, maximum)
	return safe(value) and type(value) == "number" and math.max(0, math.min(value, maximum)) or 0
end

function Session:Add(name, player)
	if not ns.db or not ns.db.rememberNames or not safe(name) or type(name) ~= "string" then return end
	if player then name = name:match("^[^-]+") or "" end
	if #name < 2 or #name > 120 or name:find("[|%c]") then return end
	local key = E.Normalize(name)
	if self.terms[key] or self.count >= 2000 then return end
	self.terms[key], self.count = name, self.count + 1
	E.names[key] = true
	local tokens = E:Tokens(key)
	if #tokens > 1 then
		local first = E.Normalize(tokens[1].word)
		local bucket = self.wowPhrases[first] or {}
		self.wowPhrases[first] = bucket
		bucket[#bucket + 1] = {text=key, count=#tokens, prefix=tokens[1].first-1, suffix=#key-tokens[#tokens].last}
		table.sort(bucket, function(a,b) return #a.text > #b.text end)
	end
end

function Session:Clear()
	self.terms, self.count, self.wowPhrases = {}, 0, {}
	E.names = {}
end

function Session:Units()
	if not ns.db.rememberNames then return end
	for _, unit in ipairs({"player", "target", "mouseover", "focus"}) do self:Add(UnitName(unit)) end
	for i=1,4 do self:Add(UnitName("party"..i), true) end
	for i=1,40 do self:Add(UnitName("raid"..i), true) end
end

function Session:Social()
	if not ns.db.rememberNames then return end
	if GetNumGuildMembers and GetGuildRosterInfo then
		for i=1,count(GetNumGuildMembers(), 1000) do self:Add(GetGuildRosterInfo(i), true) end
	end
	if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
		for i=1,count(C_FriendList.GetNumFriends(), 500) do
			local info = C_FriendList.GetFriendInfoByIndex(i)
			if safe(info) and type(info) == "table" then self:Add(info.name, true) end
		end
	elseif GetNumFriends and GetFriendInfo then
		for i=1,count(GetNumFriends(), 500) do self:Add(GetFriendInfo(i), true) end
	end
	if BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
		for i=1,count(BNGetNumFriends(), 500) do
			local info = C_BattleNet.GetFriendAccountInfo(i)
			local game = safe(info) and type(info) == "table" and info.gameAccountInfo
			if safe(game) and type(game) == "table" and safe(game.clientProgram) and game.clientProgram == "WoW" then
				self:Add(game.characterName, true)
			end
		end
	end
end

function Session:Links(text)
	if not ns.db.rememberNames or not safe(text) or type(text) ~= "string" then return end
	for name in text:gmatch("|Hitem:[^|]*|h%[([^%]]+)%]|h") do self:Add(name) end
end

function Session:HandleEvent(event, message, sender)
	if not ns.db.rememberNames then return end
	if event:match("^CHAT_MSG_") then
		self:Links(message); self:Add(sender, true)
	elseif event == "GUILD_ROSTER_UPDATE" or event == "FRIENDLIST_UPDATE" or event == "BN_FRIEND_INFO_CHANGED" then
		self:Social()
	elseif event == "UPDATE_MOUSEOVER_UNIT" or event == "PLAYER_FOCUS_CHANGED"
		or event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" then self:Units() end
end

function Session:Initialize()
	local frame = CreateFrame("Frame")
	for _, event in ipairs({"UPDATE_MOUSEOVER_UNIT", "PLAYER_FOCUS_CHANGED", "PLAYER_TARGET_CHANGED",
		"GROUP_ROSTER_UPDATE", "GUILD_ROSTER_UPDATE", "FRIENDLIST_UPDATE", "BN_FRIEND_INFO_CHANGED",
		"PLAYER_LOGIN", "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER",
		"CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
		"CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL", "CHAT_MSG_LOOT",
		"CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER"}) do frame:RegisterEvent(event) end
	frame:SetScript("OnEvent", function(_, event, ...)
		if event == "PLAYER_LOGIN" then
			self:Social()
			if ns.db.rememberNames then
				if C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster()
				elseif GuildRoster then GuildRoster() end
			end
			frame:UnregisterEvent(event)
		else self:HandleEvent(event, ...) end
	end)
	self:Social()
end
