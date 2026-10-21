-- Moteve Guide - page in Options > AddOns
local ADDON_NAME, ns = ...

local OPTIONS = {
    { key = "show",      text = "Útvonal-ablak látszik",              tip = "Ugyanaz, mint a /mg parancs." },
    { key = "arrow",     text = "Irány-nyíl",                         tip = "A képernyő tetején mutatja, merre van a következő cél." },
    { key = "waypoint",  text = "Térképjelölő a célra",               tip = "A játék saját waypointját is beállítja a következő célra." },
    { key = "autoQuest", text = "Automatikus quest felvétel / leadás", tip = "Csak az útvonal questjeinél. Shift nyomva tartásával kikapcsol.\nHa több jutalom közül kell választani, azt neked kell." },
    { key = "xp",        text = "XP/óra sor",                         tip = "XP/óra, hány perc a szintlépésig, rested XP." },
}

local panel = CreateFrame("Frame", "MoteveGuideOptions")
panel.name = "Moteve Guide"
panel:Hide()
local scroll=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT",0,0);scroll:SetPoint("BOTTOMRIGHT",-26,0)
local body=CreateFrame("Frame",nil,scroll);body:SetSize(620,550);scroll:SetScrollChild(body)
ns.AppearanceSettingsBody=body

-- Blizzard's default fonts on some clients lack Hungarian double acute glyphs.
-- Use private font objects so the game's own UI and other addons are unaffected.
local textFont = ns.FONT_BODY:gsub("Marcellus%-Regular.ttf", "Barlow-Regular.ttf")
local buttonFont = textFont:gsub("Barlow%-Regular.ttf", "Barlow-SemiBold.ttf")
local function SettingsText(template, size)
    local fs = body:CreateFontString(nil, "ARTWORK", template)
    ns.SetFontSafe(fs, textFont, size or 14)
    return fs
end
local buttonFonts = {}
for state, color in pairs({Normal={1,0.82,0}, Highlight={1,1,1}, Disabled={0.5,0.5,0.5}}) do
    local font = CreateFont("MoteveGuideOptions" .. state .. "Font")
    ns.SetFontSafe(font, buttonFont, 14)
    font:SetTextColor(color[1], color[2], color[3])
    font:SetShadowColor(0,0,0,1);font:SetShadowOffset(1,-1)
    buttonFonts[state] = font
end
local function SettingsButton()
    local b = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
    b:SetNormalFontObject(buttonFonts.Normal)
    b:SetHighlightFontObject(buttonFonts.Highlight)
    b:SetDisabledFontObject(buttonFonts.Disabled)
    return b
end

local title = SettingsText("GameFontNormalLarge",20)
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Moteve Guide")
local sub = SettingsText("GameFontHighlightSmall",12)
sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
sub:SetText("Horde és Alliance útvonalak, zónaválasztóval 1–30-ig. Parancsok: /mg")

local checks, y = {}, -60
for _, o in ipairs(OPTIONS) do
    local cb = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 20, y)
    cb:SetSize(26, 26)
    local label = (type(rawget(cb, "Text")) == "table" and cb.Text) or (type(rawget(cb, "text")) == "table" and cb.text)
        or cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:ClearAllPoints()
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetFontObject("GameFontHighlight")
    ns.SetFontSafe(label, textFont, 14)
    label:SetText(o.text)
    cb.opt = o
    cb:SetScript("OnClick", function(self)
        if not ns.db then return end
        ns.db[self.opt.key] = self:GetChecked() and true or false
        if ns.Refresh then pcall(ns.Refresh) end
    end)
    cb:SetScript("OnEnter", function(self)
        ns.Tooltip:SetOwner(self, "ANCHOR_RIGHT")
        ns.Tooltip:AddLine(self.opt.text, 1, 1, 1)
        ns.Tooltip:AddLine(self.opt.tip, 1, 0.82, 0, true)
        ns.ShowTooltip()
    end)
    cb:SetScript("OnLeave", function() ns.Tooltip:Hide() end)
    checks[#checks + 1] = cb
    y = y - 28
end

-- how many upcoming steps to list: - [ 4 ] +
y = y - 10
local linesLabel = SettingsText("GameFontNormal")
linesLabel:SetPoint("TOPLEFT", 20, y)
linesLabel:SetText("Előre látható lépések száma")
local linesValue = SettingsText("GameFontHighlight")
local function SetLines(d)
    if not ns.db then return end
    ns.db.lines = math.max(0, math.min(8, (tonumber(ns.db.lines) or 4) + d))
    linesValue:SetText(tostring(ns.db.lines))
    if ns.Refresh then pcall(ns.Refresh) end
end
local minus = SettingsButton()
minus:SetSize(26, 22); minus:SetPoint("LEFT", linesLabel, "RIGHT", 12, 0); minus:SetText("-")
minus:SetScript("OnClick", function() SetLines(-1) end)
linesValue:SetPoint("LEFT", minus, "RIGHT", 8, 0); linesValue:SetWidth(24)
local plus = SettingsButton()
plus:SetSize(26, 22); plus:SetPoint("LEFT", linesValue, "RIGHT", 8, 0); plus:SetText("+")
plus:SetScript("OnClick", function() SetLines(1) end)

-- route picker
y = y - 40
local gLabel = SettingsText("GameFontNormal")
gLabel:SetPoint("TOPLEFT", 20, y)
gLabel:SetText("Útvonal")
local gNow = SettingsText("GameFontHighlight")
gNow:SetPoint("LEFT", gLabel, "RIGHT", 12, 0)
y = y - 26
local picker = SettingsButton()
picker:SetSize(260,24);picker:SetPoint("TOPLEFT",20,y);picker:SetText("Útvonal / zóna kiválasztása…")
picker:SetScript("OnClick",function() ns.ShowMenu() end)

-- handy buttons
y = y - 44
local function Action(txt, cmd, x)
    local b = SettingsButton()
    b:SetSize(190, 24); b:SetPoint("TOPLEFT", x, y); b:SetText(txt)
    b:SetScript("OnClick", function() SlashCmdList.MOTEVEGUIDE(cmd) end)
end
Action("‹ Előző lépés", "prev", 20)
Action("Következő lépés ›", "next", 216)
Action("Újrakezdés a szintemtől", "reset", 412)

local skinButtons={}
local function SkinSelector(key,label,atY)
    local heading=SettingsText("GameFontNormal")
    heading:SetPoint("TOPLEFT",20,atY);heading:SetText(label)
    skinButtons[key]={}
    for i,id in ipairs(ns.SkinOrder) do
        local skin=id
        local b=SettingsButton()
        local width=math.floor((580-(#ns.SkinOrder-1)*8)/#ns.SkinOrder)
        b:SetSize(width,26);b:SetPoint("TOPLEFT",20+(i-1)*(width+8),atY-24)
        b:SetScript("OnClick",function() ns.SetAppearance(key,skin) end)
        b:SetText(ns.Skins[skin].label);skinButtons[key][skin]=b
    end
end
SkinSelector("guideSkin","Guide ablak kinézete",y-48)
SkinSelector("arrowSkin","Irányjelző nyíl kinézete",y-110)
function ns.RefreshAppearanceOptions()
    if not ns.db then return end
    for key,buttons in pairs(skinButtons) do
        for skin,b in pairs(buttons) do
            b:SetText(ns.db[key]==skin and ("[ "..ns.Skins[skin].label.." ]") or ns.Skins[skin].label)
        end
    end
end
ns.AppearanceOptions=skinButtons

local credit = SettingsText("GameFontDisableSmall",11)
credit:SetPoint("BOTTOMLEFT", 16, 16)
credit:SetText("Quest/NPC adatok: QuestieDB (Questie, GPL-3.0). Az útvonalat a Moteve Guide generálja.")

local function Refresh()
    if not ns.db then return end
    for _, cb in ipairs(checks) do cb:SetChecked(ns.db[cb.opt.key] and true or false) end
    linesValue:SetText(tostring(ns.db.lines or 4))
    gNow:SetText(ns.guide and ns.guide.name or "-")
    ns.RefreshAppearanceOptions()
end
panel:SetScript("OnShow", Refresh)
panel.refresh = Refresh

local reg = CreateFrame("Frame")
reg:RegisterEvent("PLAYER_LOGIN")
reg:SetScript("OnEvent", function()
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and cat then pcall(Settings.RegisterAddOnCategory, cat); ns.optionsCategory = cat; return end
    end
    if InterfaceOptions_AddCategory then pcall(InterfaceOptions_AddCategory, panel) end
end)

function ns.OpenOptions()
    if Settings and Settings.OpenToCategory and ns.optionsCategory then
        local c = ns.optionsCategory
        pcall(Settings.OpenToCategory, c.GetID and c:GetID() or c.ID)
    elseif InterfaceOptionsFrame_OpenToCategory then
        pcall(InterfaceOptionsFrame_OpenToCategory, panel); pcall(InterfaceOptionsFrame_OpenToCategory, panel)
    end
end
