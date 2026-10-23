local _, ns = ...
local UI = ns.UI
function UI:CreateCompletionPanel()
	local panel = CreateFrame("Frame", "KorrectCompletionPanel", UIParent, "BackdropTemplate")
	panel:SetSize(310, 110); panel:SetFrameStrata("DIALOG"); panel:SetClampedToScreen(true)
	UI.Background(panel)
	UI.Label(panel, "Complete word - click to choose", 10, -9, "GameFontHighlightSmall")
	panel.buttons = {}
	for i=1,3 do
		local b = UI.Button(panel, "", 290, 23, function(self) ns.Autofill:Apply(self.word) end)
		b:SetPoint("TOPLEFT", 10, -28-(i-1)*26)
		b:GetFontString():SetWidth(270); b:GetFontString():SetWordWrap(false)
		b:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(self.word or ""); GameTooltip:Show()
		end)
		b:SetScript("OnLeave", function() GameTooltip:Hide() end)
		panel.buttons[i] = b
	end
	panel:Hide(); self.completion = panel
end
function UI:ShowCompletions(box, results)
	self.panel:Hide()
	local panel = self.completion
	panel:ClearAllPoints(); panel:SetPoint("BOTTOMLEFT", box, "TOPLEFT", 0, 8)
	panel:SetScale(ns.db.panelScale); panel:SetHeight(34 + #results*26)
	for i,b in ipairs(panel.buttons) do
		b.word = results[i]
		b:SetText(results[i] or ""); b:SetShown(results[i] ~= nil)
	end
	panel:Show()
end
