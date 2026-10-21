-- Reversible appearance only: route/progress state belongs to Guide.lua.
local _,ns=...
ns.SkinOrder={"original","minimal","classiclight","glass","moteve"}
ns.Skins={
 original={label="Eredeti",bg={0.045,0.035,0.03},edge={0.7,0.55,0.27},alpha=0.96},
 minimal={label="Minimal",bg={0.045,0.05,0.055},edge={0.36,0.38,0.40},alpha=0.97},
 classiclight={label="Classic Light",bg={0.065,0.052,0.035},edge={0.56,0.44,0.23},alpha=0.96},
 glass={label="Glass",bg={0.055,0.075,0.09},edge={0.49,0.57,0.63},alpha=0.68},
 moteve={label="Moteve",bg={16/255,20/255,44/255},edge={150/255,180/255,1},alpha=0.50},
}
-- Shared palette from Moteve Chat / Moteve Damage Meter, without a dependency.
local M={violet={168/255,139/255,1},cyan={127/255,216/255,1},text={238/255,242/255,1},
 sub={185/255,194/255,230/255},muted={154/255,164/255,199/255},mint={127/255,227/255,176/255}}
local BODY=ns.FONT_BODY:gsub("Marcellus%-Regular.ttf","Barlow-Regular.ttf")
local BOLD=BODY:gsub("Barlow%-Regular.ttf","Barlow-SemiBold.ttf")
local function Font(fs,skin,kind,size)
 local path=(skin=="original" or ((skin=="classiclight" or skin=="moteve") and kind=="title")) and ns.FONT_TITLE or (kind=="body" and BODY or BOLD)
 ns.SetFontSafe(fs,path,size)
end
local function Color(fs,c) fs:SetTextColor(c[1],c[2],c[3]) end
local function Gradient(t,c,a) ns.Grad(t,"HORIZONTAL",c,a,c,a) end
local function Border(frame)
 if not frame.flatBorder then frame.flatBorder=ns.Slice(frame,"roundline",0.25,"BORDER"):Fit(frame,4) end
 return frame.flatBorder
end
function ns.ValidateAppearance()
 for _,key in ipairs({"guideSkin","arrowSkin"}) do
  if type(ns.db[key])~="string" or not ns.Skins[ns.db[key]] then ns.db[key]="glass" end
 end
end
function ns.SetAppearance(key,value)
 if not ns.db or (key~="guideSkin" and key~="arrowSkin") or type(value)~="string" or not ns.Skins[value] then return false end
 ns.db[key]=value
 ns.ApplyAppearance()
 if ns.RefreshAppearanceOptions then ns.RefreshAppearanceOptions() end
 return true
end
local function PaintButton(b,key)
 local original=key=="original"
 b.bg:SetShown(original);b.hl:SetShown(original)
 if b.g then b.g:SetShown(original) end
 if not b.flat then
  b.flat=ns.Font(b,"bold",19,{0.8,0.82,0.84},"CENTER");b.flat:SetPoint("CENTER")
 end
 b.flat:SetText(b.symbol);b.flat:SetShown(not original)
 Font(b.flat,key,"body",b.symbol=="×" and 22 or 20)
 Color(b.flat,key=="moteve" and M.violet or {0.8,0.82,0.84})
end
function ns.ApplyRowSkin(r,key)
 local original=key=="original";local s=ns.Skins[key]
 local current=not r.step or (ns.char and r.step==ns.char.idx)
 r.box:SetShown(original);r.on:SetShown(original and current)
 r.onGrad:SetShown(current)
 if original then
  local step=r.step and ns.guide and ns.guide.steps[r.step]
  if ns.SetStepIcon then ns.SetStepIcon(r.icon,step and step.k or "t",not r.step and 1.1 or current and 1.08 or 1) end
  ns.Grad(r.onGrad,"HORIZONTAL",{0.35,0.8,0.2},0.22,{0.1,0.25,0.05},0)
  ns.Grad(r.sep,"HORIZONTAL",{0.85,0.66,0.3},0.05,{0.85,0.66,0.3},0.22)
  ns.Grad(r.hl,"HORIZONTAL",{1,0.85,0.5},0.10,{1,0.85,0.5},0)
 else
  Gradient(r.onGrad,key=="moteve" and M.violet or key=="classiclight" and {0.42,0.32,0.14} or {0.38,0.49,0.36},key=="glass" and 0.13 or 0.16)
  Gradient(r.sep,s.edge,key=="moteve" and 0.10 or 0.19);Gradient(r.hl,key=="moteve" and M.violet or {0.8,0.85,0.8},0.055)
  r.icon:SetSize(24,24)
 end
 if not r.skinMarker then r.skinMarker=r:CreateTexture(nil,"ARTWORK") end
 r.skinMarker:ClearAllPoints()
 if key=="glass" then
  r.skinMarker:SetTexture(ns.TEX("circle"));r.skinMarker:SetSize(5,5);r.skinMarker:SetPoint("TOPLEFT",2,-20)
  r.skinMarker:SetVertexColor(0.82,0.70,0.37,0.9)
 else
  local c=key=="moteve" and M.violet or {0.52,0.67,0.39}
  r.skinMarker:SetColorTexture(c[1],c[2],c[3],0.9);r.skinMarker:SetWidth(key=="moteve" and 2 or 3)
  r.skinMarker:SetPoint("TOPLEFT",0,-4);r.skinMarker:SetPoint("BOTTOMLEFT",0,4)
 end
 r.skinMarker:SetShown(not original and current)
 if not r.flatChev then
  r.flatChev=ns.Font(r,"body",20,{0.62,0.65,0.66},"CENTER")
  r.flatChev:SetText("›");r.flatChev:SetPoint("RIGHT",-8,0);r.flatChev:SetPoint("TOP",r.box,"CENTER",0,8)
 end
 r.flatChev:SetShown(not original and r.step~=nil);r.chev:SetShown(original and r.step~=nil)
 Color(r.flatChev,key=="moteve" and M.muted or {0.62,0.65,0.66})
 Font(r.l1,key,original and "title" or "bold",current and 14.5 or 13.5)
 Font(r.l2,key,"body",12.5)
 Color(r.l1,original and {0.96,0.95,0.92} or {0.95,0.94,0.91});Color(r.l2,original and {0.68,0.66,0.60} or {0.68,0.70,0.71})
 if key=="moteve" then Color(r.l1,M.text);Color(r.l2,M.muted) end
 if r.skinTitle then r.l1:SetText(original and r.skinTitle or r.skinTitle:gsub("|cffffd040",key=="classiclight" and "|cffe1cca0" or "|cfff0eee8")) end
 for _,bar in ipairs(r.bars) do
  bar.frame:SetShown(original)
  bar:SetStatusBarTexture(original and ns.TEX("skin_bar") or ns.WHITE)
  if bar.skinDone~=nil then
   if original then
    if bar.skinDone then bar:SetStatusBarColor(0.3,0.85,0.2) else bar:SetStatusBarColor(0.95,0.66,0.12) end
   elseif key=="moteve" then
    local c=bar.skinDone and M.mint or M.cyan;bar:SetStatusBarColor(c[1],c[2],c[3],0.65)
   elseif bar.skinDone then bar:SetStatusBarColor(0.45,0.65,0.34)
   else bar:SetStatusBarColor(0.71,0.57,0.25) end
  end
  Font(bar.name,key,"bold",12);Font(bar.num,key,"bold",12)
 end
end
function ns.ApplyMenuSkin(menu,items)
 if not ns.db then return end
 local key=ns.db.guideSkin;local s=ns.Skins[key];local original=key=="original"
 menu.border:SetShown(original)
 Border(menu):SetShown(not original);Border(menu):SetColor(s.edge,0.8)
 if original then ns.Grad(menu.bg,"VERTICAL",{0.04,0.03,0.025},0.97,{0.1,0.08,0.06},0.97)
 else Gradient(menu.bg,s.bg,key=="moteve" and 0.94 or 0.97) end
 for _,b in ipairs(items) do Font(b.text,key,b.menuHead and "title" or "body",b.menuHead and 13 or 12);Font(b.right,key,"body",11.5) end
end
local function PaintFrame(ui,key)
 local f=ui.frame;local s=ns.Skins[key];local original=key=="original"
 f.skin=key
 for _,o in ipairs(ui.decor) do o:SetShown(original) end
 ui.medallion:SetShown(original);f.border:SetShown(original)
 Border(f):SetShown(not original);Border(f):SetColor(s.edge,key=="moteve" and 0.18 or key=="glass" and 0.55 or 0.85)
 f.bg:ClearAllPoints();f.title:ClearAllPoints();f.zone:ClearAllPoints()
 ui.header:ClearAllPoints()
 if original then
  f.bg:SetPoint("TOPLEFT",6,-6);f.bg:SetPoint("BOTTOMRIGHT",-6,6)
  ns.Grad(f.bg,"VERTICAL",{0.045,0.035,0.03},0.96,{0.11,0.09,0.07},0.96)
  f.title:SetPoint("CENTER",f.plate,"CENTER",0,-1)
  f.zone:SetPoint("TOPLEFT",20,-34);f.zone:SetPoint("RIGHT",-78,0)
  ui.header:SetPoint("TOPLEFT",0,20);ui.header:SetPoint("TOPRIGHT",0,20);ui.header:SetHeight(98)
 else
  f.bg:SetPoint("TOPLEFT",1,-1);f.bg:SetPoint("BOTTOMRIGHT",-1,1);Gradient(f.bg,s.bg,s.alpha)
  if key=="moteve" then ns.Grad(f.bg,"VERTICAL",s.bg,0.50,s.bg,0.08) end
  f.title:SetPoint("TOPLEFT",14,-11)
  f.zone:SetPoint("TOPLEFT",14,-36);f.zone:SetPoint("RIGHT",-78,0)
  ui.header:SetPoint("TOPLEFT",0,0);ui.header:SetPoint("TOPRIGHT",0,0);ui.header:SetHeight(84)
 end
 Color(f.title,original and {1,0.82,0.25} or key=="classiclight" and {0.88,0.76,0.49} or {0.9,0.92,0.93})
 Color(f.zone,original and {1,0.82,0.25} or {0.94,0.94,0.92})
 Font(f.title,key,"title",original and 19 or 15);Font(f.zone,key,"title",15)
 Color(f.sub,original and {0.68,0.66,0.60} or {0.68,0.70,0.71})
 if key=="moteve" then Color(f.title,M.muted);Color(f.zone,M.text);Color(f.sub,M.sub) end
 for _,entry in ipairs({{f.sub,"body",13},{f.count,"bold",12},{f.rate,"bold",10.5},{f.ttl,"bold",10.5}}) do Font(entry[1],key,entry[2],entry[3]) end
 if original then
  ns.Grad(f.rule,"HORIZONTAL",{0.85,0.66,0.3},0.15,{0.85,0.66,0.3},0.55)
  ns.Grad(f.frule,"HORIZONTAL",{0.85,0.66,0.3},0.55,{0.85,0.66,0.3},0.15)
 else Gradient(f.rule,s.edge,key=="moteve" and 0.12 or 0.23);Gradient(f.frule,s.edge,key=="moteve" and 0.12 or 0.23) end
 for _,b in ipairs(ui.buttons) do PaintButton(b,key) end
 local close=ui.buttons[1];close:ClearAllPoints();close:SetPoint("TOPRIGHT",original and 6 or -5,original and 8 or -5)
 ui.settings:SetShown(not original)
 local xp=ns.db.xp
 for _,o in ipairs({f.xpIcon,f.barsIcon,f.pipe,f.pill.ptr}) do o:SetShown(original and xp) end
 f.rate:ClearAllPoints();f.ttl:ClearAllPoints()
 if original then
  f.rate:SetPoint("LEFT",f.xpIcon,"RIGHT",5,0);f.rate:SetWidth(88)
  f.ttl:SetPoint("LEFT",f.barsIcon,"RIGHT",4,-1);f.ttl:SetWidth(100)
 else
  f.rate:SetPoint("BOTTOMLEFT",14,15);f.rate:SetWidth(110)
  f.ttl:SetPoint("BOTTOMLEFT",140,15);f.ttl:SetWidth(130)
 end
 local pill=f.pill;pill.frame:SetShown(original)
 pill:SetSize(original and 108 or 78,original and 26 or 20)
 pill.bar:SetStatusBarTexture(original and ns.TEX("skin_bar") or ns.WHITE)
 pill.rest:SetStatusBarTexture(original and ns.TEX("skin_bar") or ns.WHITE)
 if original then pill.bar:SetStatusBarColor(0.2,0.85,0.12);pill.rest:SetStatusBarColor(0.25,0.5,1,0.75)
 elseif key=="moteve" then pill.bar:SetStatusBarColor(M.violet[1],M.violet[2],M.violet[3],0.7);pill.rest:SetStatusBarColor(M.cyan[1],M.cyan[2],M.cyan[3],0.35)
 else pill.bar:SetStatusBarColor(0.44,0.65,0.35);pill.rest:SetStatusBarColor(0.31,0.47,0.57,0.45) end
 Font(pill.pct,key,"bold",12.5)
 for _,r in ipairs(ui.rows) do ns.ApplyRowSkin(r,key) end
end
function ns.UpdateArrowState(a,arrived)
 a.arrived=arrived and true or false
 local special=a.skin and a.skin~="original"
 a.arrival:SetShown(special and a.arrived);a.tex:SetShown(not special or not a.arrived)
end
function ns.StyleArrow(a,key)
 a.skin=key
 a.tex:SetTexture(ns.TEX(key=="original" and "arrow" or key=="moteve" and "nav_glass" or "nav_"..key))
 if key=="moteve" then a.tex:SetVertexColor(M.cyan[1],M.cyan[2],M.cyan[3],1)
 else a.tex:SetVertexColor(1,1,1,1) end
 a.tex:SetSize(64,64)
 a.dist:ClearAllPoints();a.dist:SetPoint("TOP",a.tex,"BOTTOM",0,key=="original" and 0 or -7)
 a.ring:SetTexture(ns.TEX(key=="classiclight" and "nav_compass" or "nav_glassdisc"))
 a.ring:SetShown(key=="classiclight" or key=="glass" or key=="moteve")
 if key=="moteve" then a.ring:SetVertexColor(M.violet[1],M.violet[2],M.violet[3],0.55)
 else a.ring:SetVertexColor(1,1,1,1) end
 Font(a.dist,key,key=="classiclight" and "title" or "bold",17)
 Font(a.what,key,"body",12)
 Color(a.what,key=="original" and {0.7,0.76,0.86} or {0.7,0.72,0.73})
 Color(a.dist,key=="moteve" and M.cyan or {1,1,1})
 if key=="moteve" then Color(a.what,M.muted) end
 a.what:SetWidth(key=="original" and 0 or 180)
 if a.dist and a.arrived then a.dist:SetText(key=="original" and "|cff7fe3b0itt vagy|r" or "|cff9fc58bMegérkeztél|r") end
 ns.UpdateArrowState(a,a.arrived)
end
function ns.ApplyAppearance()
 local ui=ns.Appearance
 if not ui or not ns.db then return end
 ns.ValidateAppearance()
 PaintFrame(ui,ns.db.guideSkin);ns.StyleArrow(ui.arrow,ns.db.arrowSkin)
 if ui.menu then ns.ApplyMenuSkin(ui.menu,ui.menuItems) end
end
