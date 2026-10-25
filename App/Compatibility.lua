local _, ns = ...
local Compat = {}
ns.Compat = Compat

-- Public opt-in integration. Custom inputs stay plain by default because an
-- addon may save drafts or read text before our script hooks execute.
local chatBoxes = setmetatable({}, { __mode = "k" })
local messengerInputs = setmetatable({}, { __mode = "k" })
local wireRegisteredBox
local API = {}
_G.Korrect = API

function API.RegisterChatBox(box, options)
	if (type(box) ~= "table" and type(box) ~= "userdata")
		or type(box.GetObjectType) ~= "function" or box:GetObjectType() ~= "EditBox" then
		return false, "Expected a WoW EditBox"
	end
	options = options or {}
	if type(options) ~= "table" or (type(options.chatType) ~= "string" and type(options.chatType) ~= "function") then
		return false, "Expected chatType string or function"
	end
	if chatBoxes[box] and chatBoxes[box].highlights and options.highlights ~= true then
		API.PrepareChatBox(box)
	end
	chatBoxes[box] = { chatType = options.chatType, highlights = options.highlights == true }
	if wireRegisteredBox then wireRegisteredBox(box) end
	return true
end

function API.GetRawText(box)
	if not chatBoxes[box] then return end
	if ns.UI and ns.UI.RawText then return ns.UI:RawText(box) end
	return box:GetText(), box:GetCursorPosition()
end

function API.PrepareChatBox(box)
	if not chatBoxes[box] then return false end
	if ns.db and ns.Chat and ns.Chat.FinishInput then ns.Chat:FinishInput(box) end
	return true
end

function Compat:CanHighlight(box)
	if messengerInputs[box] then return ns.db and ns.db.whisperMessengerHighlights == true end
	local options = chatBoxes[box]
	return not options or options.highlights
end

local version, build, _, interface
if GetBuildInfo then version, build, _, interface = GetBuildInfo() end
interface = tonumber(interface) or 0
Compat.version, Compat.build, Compat.interface = version or "unknown", build or "unknown", interface
Compat.projectID = WOW_PROJECT_ID

-- Interface ranges also distinguish Forever from Era when project constants
-- are unavailable. API selection below is capability-based, not version-based.
if interface >= 16000 and interface < 20000 then Compat.client = "Forever"
elseif interface >= 100000 then Compat.client = "Retail"
elseif interface >= 20000 and interface < 30000 then Compat.client = "TBC Classic / Anniversary"
elseif interface >= 10000 and interface < 16000 then Compat.client = "Classic Era"
elseif interface >= 50000 and interface < 60000 then Compat.client = "Mists of Pandaria Classic"
elseif interface >= 30000 then Compat.client = "Progression Classic"
else Compat.client = "Unknown" end

-- Shared vocabulary is extended by the selected client dataset.
-- Other progression clients retain the Forever fallback until dedicated packs exist.
local vocabularyByClient = {
	Retail = "Retail", Forever = "Forever", ["Classic Era"] = "ClassicEra",
	["TBC Classic / Anniversary"] = "AnniversaryTBC", ["Progression Classic"] = "Forever",
	["Mists of Pandaria Classic"] = "MoPClassic",
}
Compat.vocabulary = vocabularyByClient[Compat.client] or "Retail"

local wimChannels = {
	guild = "GUILD", officer = "OFFICER", party = "PARTY", raid = "RAID",
	battleground = "INSTANCE_CHAT", say = "SAY", channel = "CHANNEL", community = "CHANNEL",
}

function Compat:GetChatType(box)
	local options = chatBoxes[box]
	if options then
		local channel = options.chatType
		if type(channel) == "function" then channel = channel(box) end
		return channel or "KORRECT_UNKNOWN"
	end
	local window = box.widgetName == "msg_box" and box.parentWindow
	if window and (window.type == "whisper" or window.type == "w2w") then
		return window.isBN and "BN_WHISPER" or "WHISPER"
	elseif window and window.type == "chat" then
		return wimChannels[window.chatType] or "WIM_UNKNOWN"
	end
	return box:GetAttribute("chatType") or "SAY"
end

function Compat:HookWIM(wireBox)
	local wim = _G.WIM
	if not wim or type(wim.RegisterWidgetTrigger) ~= "function" then return end
	local function registerBox(box)
		if not box then return end
		API.RegisterChatBox(box, { highlights = true, chatType = function(input)
			local window = input.parentWindow
			if not window then return end
			if window.type == "whisper" or window.type == "w2w" then
				return window.isBN and "BN_WHISPER" or "WHISPER"
			elseif window.type == "chat" then return wimChannels[window.chatType] end
		end })
		wireBox(box)
	end
	if self.wim ~= wim then
		self.wim = wim
		-- WIM's public triggers cover newly created and recycled pop-ups.
		wim.RegisterWidgetTrigger("msg_box", "whisper,chat,w2w", "OnShow", registerBox)
		wim.RegisterWidgetTrigger("msg_box", "whisper,chat,w2w", "OnEditFocusGained", registerBox)
	end
	if type(wim.GetWindowSoupBowl) == "function" then
		local pool = wim.GetWindowSoupBowl()
		for _, entry in ipairs(pool and pool.windows or {}) do
			local window = entry.obj
			if window and (window.type == "whisper" or window.type == "chat" or window.type == "w2w") then
				registerBox(window.widgets and window.widgets.msg_box)
			end
		end
	end
end

local messengerChannels = {
	WOW = "WHISPER", BN = "BN_WHISPER", WHISPER = "WHISPER", BN_WHISPER = "BN_WHISPER",
	PARTY = "PARTY", RAID = "RAID", INSTANCE_CHAT = "INSTANCE_CHAT", GUILD = "GUILD",
	OFFICER = "OFFICER", CHANNEL = "CHANNEL", COMMUNITY = "CHANNEL",
}

function Compat:ScanWhisperMessenger(root)
	-- Inspect only this addon's named window. Its composer is the plain input
	-- given GetChatType by Composer/LinkHooks.lua; search/note inputs lack it.
	local inputs, lists = {}, {}
	local function scan(frame)
		if type(frame.rows) == "table" then lists[#lists + 1] = frame end
		if frame:GetObjectType() == "EditBox" and type(frame.GetChatType) == "function"
			and frame:GetScript("OnEnterPressed") and frame:GetScript("OnTextChanged") then
			inputs[#inputs + 1] = frame
		end
		for _, child in ipairs({ frame:GetChildren() }) do scan(child) end
	end
	scan(root)
	-- The current composer is a single input shared by all conversations.
	-- Fail closed when a future layout does not match, rather than hook search.
	if #inputs ~= 1 then return end
	messengerInputs[inputs[1]] = true
	API.RegisterChatBox(inputs[1], { chatType = function()
		local channel
		for _, list in ipairs(lists) do
			for _, row in ipairs(list.rows or {}) do
				local item = row.item
				if row.selected == true and type(item) == "table" then
					local candidate = messengerChannels[item.channel]
					if not candidate or (channel and channel ~= candidate) then return end
					channel = candidate
				end
			end
		end
		-- Filtering/paging can omit the selected row. Never reuse its old channel.
		return channel
	end })
end

function Compat:HookWhisperMessenger()
	if not self.messengerCreationHook then
		self.messengerCreationHook = true
		-- The window is built lazily, possibly long after ADDON_LOADED. A named
		-- creation observer avoids a permanent timer or scanning unrelated frames.
		hooksecurefunc("CreateFrame", function(_, name)
			if name ~= "WhisperMessengerWindow" then return end
			local deferred = self.messengerDeferred
			if not deferred then deferred = CreateFrame("Frame"); self.messengerDeferred = deferred end
			deferred:SetScript("OnUpdate", function(frame)
				frame:SetScript("OnUpdate", nil)
				self:HookWhisperMessenger()
			end)
		end)
	end
	local root = _G.WhisperMessengerWindow
	if not root then return end
	if self.messengerWindow ~= root then
		self.messengerWindow = root
		root:HookScript("OnShow", function() self:ScanWhisperMessenger(root) end)
	end
	self:ScanWhisperMessenger(root)
end

function Compat:VisitChatBoxes(visit)
	visit(_G.ChatFrameEditBox)
	-- Cellular reuses and reparents the active/default Blizzard input instead
	-- of creating its own composer. Never hook CellularEB: it copies history.
	visit(DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox)
	for i = 1, NUM_CHAT_WINDOWS or 10 do
		local frame = _G["ChatFrame" .. i]
		visit(frame and frame.editBox)
		visit(_G["ChatFrame" .. i .. "EditBox"])
	end
	for _, name in pairs(CHAT_FRAMES or {}) do
		local frame = _G[name]
		visit(frame and frame.editBox)
	end
	if ChatFrameUtil and type(ChatFrameUtil.GetActiveWindow) == "function" then
		visit(ChatFrameUtil.GetActiveWindow())
	elseif type(ChatEdit_GetActiveWindow) == "function" then
		visit(ChatEdit_GetActiveWindow())
	end
end

function Compat:HookChat(wireBox, wireAllBoxes)
	wireRegisteredBox = wireBox
	for box in pairs(chatBoxes) do wireBox(box) end
	self:HookWIM(wireBox)
	self:HookWhisperMessenger()
	-- Hook both if a client exposes both entry points; wireBox is idempotent.
	if ChatFrameUtil and type(ChatFrameUtil.ActivateChat) == "function" then
		hooksecurefunc(ChatFrameUtil, "ActivateChat", wireBox)
	end
	if type(ChatEdit_ActivateChat) == "function" then
		hooksecurefunc("ChatEdit_ActivateChat", wireBox)
	end
	if type(FCF_OpenTemporaryWindow) == "function" then
		hooksecurefunc("FCF_OpenTemporaryWindow", wireAllBoxes)
	end
end

function Compat:RegisterOptions(canvas)
	if Settings and type(Settings.RegisterCanvasLayoutCategory) == "function"
		and type(Settings.RegisterAddOnCategory) == "function" then
		local category = Settings.RegisterCanvasLayoutCategory(canvas, canvas.name)
		Settings.RegisterAddOnCategory(category)
		return category
	elseif type(InterfaceOptions_AddCategory) == "function" then
		InterfaceOptions_AddCategory(canvas)
	end
end

function Compat:Describe()
	local chat = ChatFrameUtil and type(ChatFrameUtil.ActivateChat) == "function" and "modern" or "legacy"
	return self.client .. " " .. self.version .. " (Interface " .. self.interface
		.. ", chat=" .. chat .. ", vocabulary=" .. self.vocabulary .. ")"
end
