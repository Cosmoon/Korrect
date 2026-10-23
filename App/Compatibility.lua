local _, ns = ...
local Compat = {}
ns.Compat = Compat

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
elseif interface >= 30000 then Compat.client = "Progression Classic"
else Compat.client = "Unknown" end

-- Shared vocabulary is extended by the selected client dataset.
-- Progression Classic retains the Forever fallback until a dedicated pack exists.
local vocabularyByClient = {
	Retail = "Retail", Forever = "Forever", ["Classic Era"] = "ClassicEra",
	["TBC Classic / Anniversary"] = "AnniversaryTBC", ["Progression Classic"] = "Forever",
}
Compat.vocabulary = vocabularyByClient[Compat.client] or "Retail"

function Compat:VisitChatBoxes(visit)
	visit(_G.ChatFrameEditBox)
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
