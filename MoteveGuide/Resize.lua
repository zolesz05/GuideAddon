-- Resize the whole guide proportionally so text, artwork and rows stay aligned.
local ADDON_NAME, ns = ...
local F = MoteveGuideFrame
local MIN_SCALE, MAX_SCALE, DEFAULT_SCALE = 0.55, 1.30, 0.85

local function SaveAnchor()
    if not ns.db then return end
    local p, _, rp, x, y = F:GetPoint()
    if p then
        ns.db.point, ns.db.relPoint, ns.db.x, ns.db.y = p, rp, x, y
    end
end

function ns.SetWindowScale(value, fixedLeft, fixedTop)
    if not ns.db then return end
    value = tonumber(value) or DEFAULT_SCALE
    if value ~= value then value = DEFAULT_SCALE end
    value = math.max(MIN_SCALE, math.min(MAX_SCALE, value))
    local oldEffective = F:GetEffectiveScale()
    local left, top = F:GetLeft(), F:GetTop()
    left = fixedLeft or (left and left * oldEffective)
    top = fixedTop or (top and top * oldEffective)
    F:SetScale(value)
    ns.db.scale = value
    -- Anchor in the frame's new units to keep the top-left corner still on screen.
    if left and top then
        local effective = F:GetEffectiveScale()
        F:ClearAllPoints()
        F:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / effective, top / effective)
        SaveAnchor()
    end
end

local grip = CreateFrame("Button", nil, F)
F.resizeGrip = grip
grip:SetSize(20, 20)
grip:SetPoint("BOTTOMRIGHT", 3, -3)
grip:SetFrameLevel(F:GetFrameLevel() + 12)
grip:RegisterForClicks("RightButtonUp")
local icon = grip:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints()
icon:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
local highlight = grip:CreateTexture(nil, "HIGHLIGHT")
highlight:SetAllPoints()
highlight:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")

local drag
local function Finish()
    if not drag then return end
    drag = nil
    grip:SetScript("OnUpdate", nil)
    SaveAnchor()
end
grip:SetScript("OnMouseDown", function(_, button)
    if button ~= "LeftButton" or not ns.db then return end
    F:StopMovingOrSizing()
    local effective = F:GetEffectiveScale()
    local left, top = F:GetLeft(), F:GetTop()
    if not left or not top then return end
    local x, y = GetCursorPosition()
    drag = { x = x, y = y, scale = F:GetScale(), left = left * effective, top = top * effective,
        width = F:GetWidth() * effective, height = F:GetHeight() * effective }
    ns.Tooltip:Hide()
    grip:SetScript("OnUpdate", function()
        if not IsMouseButtonDown("LeftButton") then Finish(); return end
        local cx, cy = GetCursorPosition()
        local d = drag
        local delta = ((cx - d.x) * d.width - (cy - d.y) * d.height)
            / (d.width * d.width + d.height * d.height)
        ns.SetWindowScale(d.scale * (1 + delta), d.left, d.top)
    end)
end)
grip:SetScript("OnMouseUp", Finish)
grip:SetScript("OnHide", Finish)
grip:SetScript("OnClick", function(_, button)
    if button == "RightButton" then Finish(); ns.SetWindowScale(DEFAULT_SCALE) end
end)
grip:SetScript("OnEnter", function(self)
    if drag then return end
    ns.Tooltip:SetOwner(self, "ANCHOR_TOP")
    ns.Tooltip:AddLine("Ablak méretezése", 1, 0.82, 0)
    ns.Tooltip:AddLine("Húzd a sarkot: kisebb / nagyobb ablak", 1, 1, 1)
    ns.Tooltip:AddLine("Jobb klikk: alapméret (85%)", 0.8, 0.8, 0.8)
    ns.Tooltip:AddLine("Pontos méret: /mg scale 70 (55–130%)", 0.8, 0.8, 0.8)
    ns.ShowTooltip()
end)
grip:SetScript("OnLeave", function() ns.Tooltip:Hide() end)

local initialize = CreateFrame("Frame")
initialize:RegisterEvent("ADDON_LOADED")
initialize:SetScript("OnEvent", function(_, _, name)
    if name == ADDON_NAME then ns.SetWindowScale(ns.db and ns.db.scale) end
end)
