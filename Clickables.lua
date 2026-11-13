local addonName, ns = ...
local ADDON, DB, queue = "Clickables", nil, {}
local frame = CreateFrame("Button", "ClickablesButton", UIParent, "SecureActionButtonTemplate,BackdropTemplate")
frame:SetSize(48,48); frame:RegisterForClicks("AnyUp"); frame:SetAttribute("type", "item")
frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); frame:SetBackdropColor(0.04,0.04,0.04,0.75)
local icon=frame:CreateTexture(nil,"ARTWORK"); icon:SetAllPoints(); frame.icon=icon
local count=frame:CreateFontString(nil,"OVERLAY","NumberFontNormal"); count:SetPoint("BOTTOMRIGHT",-1,1); frame.count=count
local remain=frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); remain:SetPoint("TOP",frame,"BOTTOM",0,-2); frame.remain=remain
local function bagName(bag,slot) return bag.." "..slot end
local function getText(itemID)
    local scan=CreateFrame("GameTooltip", "ClickablesScanTooltip", nil, "GameTooltipTemplate")
    scan:SetOwner(UIParent,"ANCHOR_NONE"); scan:SetItemByID(itemID)
    local open,quest,locked=false,false,false
    local openText=ITEM_OPENABLE or "Right Click to Open"; local questText=ITEM_STARTS_QUEST or "This Item Begins a Quest"
    for i=1,scan:NumLines() do
        local line=_G["ClickablesScanTooltipTextLeft"..i]
        local s=line and line:GetText()
        if s then
            if s:find(openText,1,true) or s:find("Right Click to Open",1,true) then open=true end
            if s:find(questText,1,true) or s:find("This Item Begins a Quest",1,true) then quest=true end
            if s:find(ITEM_LOCKED or "Locked",1,true) then locked=true end
        end
    end
    scan:Hide(); return open,quest,locked
end
local function itemData(bag,slot)
    local info=C_Container.GetContainerItemInfo(bag,slot)
    if not info or not info.itemID then return end
    local open,quest,locked=getText(info.itemID)
    local itemInfo=C_Item.GetItemInfo(info.itemID)
    local loot=info.hasLoot or info.isLootable or (itemInfo and (itemInfo.hasLoot or itemInfo.isLootable))
    local kind=ns.Classify({itemID=info.itemID,lootable=loot,tooltipOpenable=open,allowlisted=ns.OpenableItemIDs[info.itemID],quest=quest,locked=locked},DB)
    if kind then return {bag=bag,slot=slot,itemID=info.itemID,kind=kind,count=info.stackCount or 1,link=C_Container.GetContainerItemLink(bag,slot)} end
end
local function updateView()
    local current=queue[1]
    if InCombatLockdown() then return end
    if not current then
        frame:SetAttribute("item",nil); icon:SetTexture(nil); count:SetText(""); remain:SetText("")
        if DB.hideWhenEmpty then frame:Hide() else frame:SetAlpha(0.35); frame:Show() end
        return
    end
    frame:SetAlpha(1); frame:Show(); icon:SetTexture(GetItemIcon(current.itemID)); count:SetText(current.count>1 and current.count or "")
    remain:SetText(#queue>1 and ((#queue-1).." more") or "")
    frame:SetAttribute("item",bagName(current.bag,current.slot))
end
local function rebuild()
    if InCombatLockdown() then return end
    wipe(queue)
    for bag=0,NUM_BAG_SLOTS do for slot=1,C_Container.GetContainerNumSlots(bag) do local d=itemData(bag,slot); if d then queue[#queue+1]=d end end end
    ns.SortQueue(queue); updateView()
end
local function position()
    frame:ClearAllPoints(); frame:SetPoint(DB.point or "CENTER",UIParent,DB.point or "CENTER",DB.x or 0,DB.y or -120); frame:SetScale(DB.scale or 1)
end
frame:SetScript("OnDragStart",function(self) if not DB.locked and not InCombatLockdown() then self:StartMoving() end end)
frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); local p,_,_,x,y=self:GetPoint(); DB.point=p;DB.x=x;DB.y=y end)
frame:SetScript("OnClick",function(self,button) if button=="RightButton" and IsAltKeyDown() and queue[1] then ns.ToggleIgnore(DB.ignored,queue[1].itemID); rebuild() end end)
frame:SetScript("OnEnter",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); local d=queue[1]
    if d and d.link then GameTooltip:SetHyperlink(d.link) else GameTooltip:AddLine("No clickable items") end
    if d and #queue>1 then GameTooltip:AddLine((#queue-1).." more queued",0.8,0.8,0.8) end
    GameTooltip:AddLine("Click to use the next item",0.5,1,0.5); GameTooltip:AddLine("Alt+right-click to ignore",0.5,1,0.5); GameTooltip:Show()
end)
frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
function UseNextClickable() if queue[1] and not InCombatLockdown() then UseContainerItem(queue[1].bag,queue[1].slot) end end

local function toggleBagButton(button)
    if button.clickablesHooked then return end; button.clickablesHooked=true
    hooksecurefunc(button,"OnClick",function(self,mouseButton)
        if mouseButton=="RightButton" and IsAltKeyDown() and not InCombatLockdown() then
            local bag=self.GetBagID and self:GetBagID() or self.bagID or self.bag
            local slot=self.GetID and self:GetID() or self.slotID or self:GetID()
            local info=bag and slot and C_Container.GetContainerItemInfo(bag,slot)
            if info and info.itemID then ns.ToggleIgnore(DB.ignored,info.itemID); rebuild() end
        end
    end)
end
local function hookBlizzard()
    for _,b in pairs(ContainerFrameItemButton_Cached or {}) do toggleBagButton(b) end
    for _,f in ipairs({ContainerFrame1,ContainerFrame2,ContainerFrame3,ContainerFrame4,ContainerFrame5}) do if f and f.Items then for _,b in ipairs(f.Items) do toggleBagButton(b) end end end
end
local function hookEUI()
    if EUI_Bags and EUI_Bags.RefreshInventory and not EUI_Bags.clickablesHooked then
        EUI_Bags.clickablesHooked=true; hooksecurefunc(EUI_Bags,"RefreshInventory",function(self) if not InCombatLockdown() then for _,b in pairs(self.buttons or self.Buttons or {}) do toggleBagButton(b) end end end)
    end
    if EUI_BagsReagent and EUI_BagsReagent.RefreshInventory and not EUI_BagsReagent.clickablesHooked then
        EUI_BagsReagent.clickablesHooked=true; hooksecurefunc(EUI_BagsReagent,"RefreshInventory",function(self) if not InCombatLockdown() then for _,b in pairs(self.buttons or self.Buttons or {}) do toggleBagButton(b) end end end)
    end
end
local function options()
    local panel=CreateFrame("Frame",nil,UIParent); panel.name="Clickables"
    local title=panel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-16); title:SetText("Clickables")
    local y=-52
    local function check(label,key)
        local c=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate");c:SetPoint("TOPLEFT",16,y);c.Text:SetText(label);c:SetChecked(DB[key]);c:SetScript("OnClick",function(self) DB[key]=self:GetChecked();rebuild() end);y=y-30
    end
    check("Lock position","locked"); check("Hide when empty (otherwise dim)","hideWhenEmpty"); check("Openables","openables"); check("Quest starter items","questStarters")
    local scale=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate");scale:SetPoint("TOPLEFT",20,y);scale:SetMinMaxValues(0.5,2);scale:SetValueStep(0.1);scale:SetValue(DB.scale);scale:SetWidth(180);_G[scale:GetName().."Text"]:SetText("Scale");scale:SetScript("OnValueChanged",function(_,v) DB.scale=v;frame:SetScale(v) end)
    local listTitle=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    listTitle:SetPoint("TOPLEFT",16,y-24)
    listTitle:SetText("Ignored items")
    y=y-48
    local clear=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    clear:SetSize(100,22); clear:SetPoint("TOPLEFT",16,y); clear:SetText("Clear ignore")
    clear:SetScript("OnClick",function(self)
        if self.confirmUntil and GetTime()<=self.confirmUntil then
            wipe(DB.ignored); self.confirmUntil=nil; self:SetText("Clear ignore"); rebuild()
        else
            self.confirmUntil=GetTime()+5; self:SetText("Confirm (5s)")
        end
    end)
    y=y-28
    for id in pairs(DB.ignored) do
        local row=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
        row:SetPoint("TOPLEFT",18,y); row:SetText("Item "..id)
        local remove=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
        remove:SetSize(64,20); remove:SetPoint("TOPLEFT",180,y+4); remove:SetText("Remove")
        remove:SetScript("OnClick",function() DB.ignored[id]=nil; rebuild(); row:SetText("Removed") end)
        y=y-24
    end
    InterfaceOptions_AddCategory(panel)
end
local function slash(msg)
    local cmd,arg=msg:match("^(%S*)%s*(.-)$");cmd=cmd:lower()
    if cmd=="lock" then DB.locked=true elseif cmd=="unlock" then DB.locked=false elseif cmd=="scale" then DB.scale=tonumber(arg) or DB.scale;frame:SetScale(DB.scale) elseif cmd=="list" then for id in pairs(DB.ignored) do print("Clickables ignored:",id) end elseif cmd=="clear" then if not DB.clearUntil or GetTime()>DB.clearUntil then DB.clearUntil=GetTime()+5;print("Clickables: run /clickables clear again within 5 seconds") else wipe(DB.ignored);DB.clearUntil=nil;print("Clickables: ignore list cleared") end end;rebuild()
end
SLASH_CLICKABLES1="/clickables";SlashCmdList.CLICKABLES=slash
local events=CreateFrame("Frame");events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("BAG_UPDATE_DELAYED");events:RegisterEvent("PLAYER_ENTERING_WORLD");events:RegisterEvent("PLAYER_REGEN_ENABLED");events:RegisterEvent("QUEST_ACCEPTED")
events:SetScript("OnEvent",function(_,event,name)
    if event=="ADDON_LOADED" and name==addonName then DB=ns.MergeDefaults(ClickablesDB);ClickablesDB=DB;position();options();hookBlizzard();hookEUI();rebuild()
    elseif event=="PLAYER_REGEN_ENABLED" then rebuild();hookBlizzard();hookEUI()
    elseif event=="BAG_UPDATE_DELAYED" or event=="PLAYER_ENTERING_WORLD" or event=="QUEST_ACCEPTED" then rebuild();hookBlizzard();hookEUI() end
end)


