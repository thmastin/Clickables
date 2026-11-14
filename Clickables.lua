local addonName, ns = ...
local ADDON, DB, queue = "Clickables", nil, {}
local errorState=ns.NewErrorState()
local questLogState=ns.NewQuestLogState()
local function safe(label,fn) return function(...)
    local args={...}
    return ns.SafeCall(errorState,label,function() return fn(unpack(args)) end,GetTime and GetTime() or 0,print)
end end
BINDING_HEADER_CLICKABLES = "Clickables"
_G["BINDING_NAME_CLICK ClickablesButton:LeftButton"] = "Use next Clickable"
local frame = CreateFrame("Button", "ClickablesButton", UIParent, "SecureActionButtonTemplate,BackdropTemplate")
frame:SetSize(48,48); frame:RegisterForClicks("AnyUp", "AnyDown"); frame:SetAttribute("type", "item"); frame:SetAttribute("type1", "item")
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
    local useParts,inUse={},false
    local openText=ITEM_OPENABLE or "Right Click to Open"; local questText=ITEM_STARTS_QUEST or "This Item Begins a Quest"
    for i=1,scan:NumLines() do
        local line=_G["ClickablesScanTooltipTextLeft"..i]
        local s=line and line:GetText()
        if s then
            local useStart=s:find("Use:",1,true)
            if useStart then
                inUse=true
                useParts[#useParts+1]=s:sub(useStart+4)
            elseif inUse then
                useParts[#useParts+1]=s
            end
            if s:find(openText,1,true) or s:find("Right Click to Open",1,true) then open=true end
            if s:find(questText,1,true) or s:find("This Item Begins a Quest",1,true) then quest=true end
            if s:find(ITEM_LOCKED or "Locked",1,true) then locked=true end
        end
    end
    scan:Hide(); return open,quest,locked,#useParts>0 and ns.JoinTooltipLines(useParts) or nil
end
local function playerSpec()
    if not GetTalentTabInfo then return nil end
    local points={}
    for tab=1,3 do local _,_,spent=GetTalentTabInfo(tab);points[tab]=spent end
    local best=ns.DominantTalentTab(points)
    if not best then return nil end
    local _,class=UnitClass("player")
    local rule=ns.ClassScrollRules[class]
    local caster=rule and rule.casterTabs and rule.casterTabs[best]
    return caster and "caster" or "melee"
end
local function auras()
    local out={}
    local function add(name,spellID)
        if not name then return end
        local lower=name:lower()
        out[#out+1]={name=name,spellID=spellID}
        for _,stat in ipairs({"strength","agility","intellect","spirit","stamina"}) do
            if lower:find(stat,1,true) then
                local rank=lower:match(" iv$") and 4 or (lower:match(" iii$") and 3 or (lower:match(" ii$") and 2 or 1))
                out[#out+1]={stat=stat,rank=rank};break
            end
        end
        if lower:find("protection",1,true) or lower:find("armor",1,true) then
            local rank=lower:match(" iv$") and 4 or (lower:match(" iii$") and 3 or (lower:match(" ii$") and 2 or 1));out[#out+1]={stat="armor",rank=rank}
        end
        for _,d in pairs(ns.ElixirItemIDs) do if name:lower():find((d.aura or ""):lower(),1,true) then out[#out+1]={category=d.category,stat=d.stat,rank=d.rank,spellID=spellID};break end end
    end
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        for i=1,40 do local a=C_UnitAuras.GetAuraDataByIndex("player",i,"HELPFUL");if not a then break end;local n=#out+1;add(a.name,a.spellId);if a.icon==133950 and #out>=n then out[#out].icon=133950 end end
    else
        local f=UnitBuff or UnitAura
        if f then for i=1,40 do local name,_,_,_,_,_,_,_,_,spellID=f("player",i);if not name then break end;add(name,spellID) end end
    end
    return out
end
local function inferredUse(use)
    if not use then return end
    local s=use:lower()
    local stats={"strength","agility","intellect","spirit","stamina"}
    for _,stat in ipairs(stats) do if s:find(stat,1,true) then return stat end end
    if s:find("armor",1,true) or s:find("defense",1,true) then return "armor" end
    if s:find("attack power",1,true) then return "strength" end
end
local function itemData(bag,slot)
    local info=ns.GetContainerItemInfo(bag,slot)
    if not info or not info.itemID then return end
    local questInfo=ns.GetContainerItemQuestInfo(bag,slot)
    local open,quest,locked,use=getText(info.itemID)
    local foodCandidate=ns.FoodCandidate(info.itemID,use)
    if DB.ignored and DB.ignored[info.itemID] then
        if errorState.debug and foodCandidate then print("Clickables food "..(ns.GetItemName(info.itemID) or tostring(info.itemID)).." ("..info.itemID.." at "..bagName(bag,slot).."): ignored") end
        return nil
    end
    local itemInfo=ns.GetItemInfo(info.itemID)
    local loot=info.hasLoot or info.isLootable or (itemInfo and (itemInfo.hasLoot or itemInfo.isLootable))
    local questID=questInfo and questInfo.questID
    local questStatus={ready=questLogState.ready}
    if questID then
        questStatus.onQuest=C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questID) or false
        questStatus.completed=(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questID))
            or (IsQuestFlaggedCompleted and IsQuestFlaggedCompleted(questID)) or false
    end
    local startsQuest=ns.QuestDecision(questInfo,quest,questStatus)
    local kind=ns.Classify({itemID=info.itemID,lootable=loot,tooltipOpenable=open,allowlisted=ns.OpenableItemIDs[info.itemID],quest=startsQuest,locked=locked},DB)
    local data={bag=bag,slot=slot,itemID=info.itemID,count=info.stackCount or 1,link=ns.GetContainerItemLink(bag,slot)}
    local sd=ns.ScrollItemIDs[info.itemID]; local ed=ns.ElixirItemIDs[info.itemID]
    -- The checked-in IDs come from the installed Forever LibForeverData list;
    -- verify cached client names before applying a mapping.
    local knownName
    if C_Item and C_Item.GetItemInfo then knownName=C_Item.GetItemInfo(info.itemID) else knownName=ns.GetItemName(info.itemID) end
    if sd and (not knownName or knownName~=(sd.name:gsub(" I$",""))) then sd=nil end
    if ed and (not knownName or knownName~=ed.name) then ed=nil end
    if sd and knownName then
        local expected=sd.name:gsub(" I$","")
        if knownName~=expected then sd=nil end
    end
    local food=ns.FoodTooltip(use)
    local mappedFood=ns.FoodItemIDs[info.itemID]
    if not food and mappedFood then food={stats={{stat=mappedFood.stat,bonus=mappedFood.bonus}},bonus=mappedFood.bonus,stat=mappedFood.stat} end
    local foodActive,foodAllowed=false,true
    if foodCandidate then
        foodActive=ns.FoodAuraActive(auras())
        if food then foodAllowed=ns.FoodEligible(food,select(2,UnitClass("player")),playerSpec(),DB.classFilterOverride) end
        if errorState.debug then
            local skipReason
            if not food then skipReason="no Well Fed text"
            elseif foodActive then skipReason="Well Fed/eating aura active"
            elseif not foodAllowed then skipReason="class filter"
            elseif not DB.food then skipReason="Food disabled"
            else skipReason="eligible" end
            print("Clickables food "..(ns.GetItemName(info.itemID) or tostring(info.itemID)).." ("..info.itemID.." at "..bagName(bag,slot).."): "..skipReason)
        end
    end
    if food and DB.food and not foodActive and foodAllowed then
        data.kind="food";data.bonus=food.bonus;data.reason="No Well Fed buff"
    elseif sd and DB.scrolls then
        local best=sd.rank
        for _,d in pairs(ns.ScrollItemIDs) do if d.stat==sd.stat and d.rank>best then for b=0,NUM_BAG_SLOTS do for sl=1,ns.GetContainerNumSlots(b) do local bi=ns.GetContainerItemInfo(b,sl);if bi and bi.itemID then local candidate=ns.ScrollItemIDs[bi.itemID];if candidate and candidate.stat==sd.stat and candidate.rank>d.rank then best=candidate.rank end end end end end end
        local active=ns.ActiveRank(auras(),sd.stat)
        if best==sd.rank and active<sd.rank and ns.ClassAllows(select(2,UnitClass("player")),playerSpec(),sd.stat,DB.classFilterOverride) then data.kind="scroll";data.reason=sd.name..", "..(active>0 and "weaker "..sd.stat.." buff active" or "no "..(sd.stat=="armor" and "Armor" or sd.stat:sub(1,1):upper()..sd.stat:sub(2)).." buff active") end
    elseif ed and DB.elixirs then
        if ns.ClassAllows(select(2,UnitClass("player")),playerSpec(),ed.stat,DB.classFilterOverride) and not ns.ElixirConflict(auras(),ed.category) then data.kind="elixir";data.reason=ed.name..", no "..ed.category.." elixir active" end
    elseif not sd and not ed and use then
        local stat=inferredUse(use)
        local label=(knownName or ns.GetItemName(info.itemID) or ""):lower()
        if stat and label:find("scroll",1,true) and DB.scrolls then
            -- Unknown-rank scrolls are only safe when no buff of that stat is active.
            if ns.ActiveRank(auras(),stat)==0 and ns.ClassAllows(select(2,UnitClass("player")),playerSpec(),stat,DB.classFilterOverride) then data.kind="scroll";data.reason=(knownName or "Scroll")..", no matching buff active" end
        elseif stat and label:find("elixir",1,true) and DB.elixirs then
            local category=use:lower():find("guardian",1,true) and "guardian" or (use:lower():find("battle",1,true) and "battle")
            if category and not ns.ElixirConflict(auras(),category) and ns.ClassAllows(select(2,UnitClass("player")),playerSpec(),stat,DB.classFilterOverride) then data.kind="elixir";data.reason=(knownName or "Elixir")..", no "..category.." elixir active" end
        end
    end
    if kind then data.kind=kind;if kind=="quest" then data.reason="Starts a quest you don't have" end end
    if data.kind then return data end
end
local function updateView()
    ns.UpdateView(queue[1], #queue, DB, frame, icon, count, remain, InCombatLockdown())
end
local function rebuild()
    if InCombatLockdown() then return end
    local fresh={}
    for bag=0,NUM_BAG_SLOTS do for slot=1,ns.GetContainerNumSlots(bag) do local d=itemData(bag,slot); if d then fresh[#fresh+1]=d end end end
    local foods={};for i=#fresh,1,-1 do if fresh[i].kind=="food" then foods[#foods+1]=table.remove(fresh,i) end end
    local best=ns.BestFood(foods)
    if errorState.debug then
        for _,food in ipairs(foods) do
            local status=food==best and "selected" or "not best eligible food"
            print("Clickables food "..(ns.GetItemName(food.itemID) or tostring(food.itemID)).." ("..food.itemID.." at "..bagName(food.bag,food.slot).."): "..status)
        end
    end
    if best then fresh[#fresh+1]=best end
    ns.SortQueue(fresh);queue=fresh;updateView()
end
local function position()
    if DB.positionVersion ~= 2 then
        if DB.x == 0 and DB.y == -120 then
            DB.x = -UIParent:GetWidth() / 4
            DB.y = 0
        end
        DB.positionVersion = 2
    end
    frame:ClearAllPoints(); frame:SetPoint(DB.point or "CENTER",UIParent,DB.point or "CENTER",DB.x or 0,DB.y or -120); frame:SetScale(DB.scale or 1)
end
local refreshIgnoredList
frame:SetScript("OnDragStart",safe("drag start",function(self) if not DB.locked and not InCombatLockdown() then self:StartMoving() end end))
frame:SetScript("OnDragStop",safe("drag stop",function(self) self:StopMovingOrSizing(); local p,_,_,x,y=self:GetPoint(); DB.point=p;DB.x=x;DB.y=y end))
frame:SetScript("PreClick",safe("PreClick",function(self,button)
    if button=="RightButton" and IsAltKeyDown() and queue[1] and not InCombatLockdown() then
        local current=queue[1]
        local ignored=ns.ToggleIgnore(DB.ignored,current.itemID)
        local itemName=ns.GetItemName(current.itemID)
        local itemLink=current.link or (itemName and ("|Hitem:"..current.itemID.."|h["..itemName.."]|h")) or ("item:"..current.itemID)
        if ignored then print("Clickables: ignored "..itemLink) else print("Clickables: no longer ignoring "..itemLink) end
        rebuild()
        if refreshIgnoredList then refreshIgnoredList() end
    end
end))
frame:SetScript("OnEnter",safe("tooltip",function(self)
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); local d=queue[1]
    if d and d.link then GameTooltip:SetHyperlink(d.link) else GameTooltip:AddLine("No clickable items") end
    if d and d.reason then GameTooltip:AddLine(d.reason,0.7,0.9,1) end
    if d and #queue>1 then GameTooltip:AddLine((#queue-1).." more queued",0.8,0.8,0.8) end
    GameTooltip:AddLine("Click to use the next item",0.5,1,0.5); GameTooltip:AddLine("Alt+right-click to ignore",0.5,1,0.5); GameTooltip:Show()
end))
frame:SetScript("OnLeave",safe("tooltip hide",function() GameTooltip:Hide() end))
local function ignoredItemText(itemID)
    local name=ns.GetItemName(itemID)
    if name then return "|Hitem:"..itemID.."|h["..name.."]|h" end
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID)
    else ns.RequestItemLoad(itemID) end
    return "item:"..itemID
end
local function options()
    local panel=CreateFrame("Frame",nil,UIParent); panel.name="Clickables"
    local title=panel:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",16,-16); title:SetText("Clickables")
    local y=-52
    local function check(label,key)
        local c=CreateFrame("CheckButton",nil,panel,"InterfaceOptionsCheckButtonTemplate");c:SetPoint("TOPLEFT",16,y);c.Text:SetText(label);c:SetChecked(DB[key]);c:SetScript("OnClick",safe("option toggle",function(self) DB[key]=self:GetChecked();rebuild() end));y=y-30
    end
    check("Lock position","locked"); check("Hide when empty (otherwise dim)","hideWhenEmpty"); check("Openables","openables"); check("Quest starter items","questStarters");check("Elixirs","elixirs");check("Scrolls","scrolls");check("Food","food");check("Use scrolls/elixirs/food my class normally wouldn't","classFilterOverride")
    local errorsHint=panel:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall");errorsHint:SetPoint("TOPLEFT",16,y);errorsHint:SetText("Show recent errors: /clickables errors    Clear: /clickables errors clear");y=y-24
    local scale=CreateFrame("Slider",nil,panel,"OptionsSliderTemplate");scale:SetPoint("TOPLEFT",20,y);scale:SetMinMaxValues(0.5,2);scale:SetValueStep(0.1);scale:SetValue(DB.scale);scale:SetWidth(180);scale.Text:SetText("Scale");scale:SetScript("OnValueChanged",safe("scale option",function(_,v) DB.scale=v;frame:SetScale(v) end))
    local listTitle=panel:CreateFontString(nil,"ARTWORK","GameFontNormal")
    listTitle:SetPoint("TOPLEFT",16,y-24)
    listTitle:SetText("Ignored items")
    y=y-52
    local clear=CreateFrame("Button",nil,panel,"UIPanelButtonTemplate")
    clear:SetSize(100,22); clear:SetPoint("TOPLEFT",16,y); clear:SetText("Clear ignore")
    clear:SetScript("OnClick",safe("clear ignore option",function(self)
        if self.confirmUntil and GetTime()<=self.confirmUntil then
            wipe(DB.ignored); self.confirmUntil=nil; self:SetText("Clear ignore"); rebuild(); refreshIgnoredList()
        else
            self.confirmUntil=GetTime()+5; self:SetText("Confirm (5s)")
        end
    end))
    local scroll=CreateFrame("ScrollFrame",nil,panel,"UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",panel,"TOPLEFT",16,y-30)
    scroll:SetPoint("BOTTOMRIGHT",panel,"BOTTOMRIGHT",-32,16)
    local scrollChild=CreateFrame("Frame",nil,scroll)
    scrollChild:SetSize(1,1); scroll:SetScrollChild(scrollChild)
    scroll:SetScript("OnSizeChanged",safe("options resize",function(self) scrollChild:SetWidth(math.max(1,self:GetWidth())) end))
    local empty=scrollChild:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    empty:SetPoint("TOPLEFT",scrollChild,"TOPLEFT",4,-4)
    empty:SetText("No ignored items. Alt+right-click the Clickables button to ignore what it’s showing.")
    empty:SetJustifyH("LEFT"); empty:SetWidth(360)
    local rows={}
    local function makeRow()
        local row=CreateFrame("Frame",nil,scrollChild)
        row:SetHeight(24)
        row.icon=row:CreateTexture(nil,"ARTWORK"); row.icon:SetSize(18,18); row.icon:SetPoint("LEFT",row,"LEFT",2,0)
        row.remove=CreateFrame("Button",nil,row,"UIPanelButtonTemplate"); row.remove:SetSize(64,20); row.remove:SetPoint("RIGHT",row,"RIGHT",-2,0); row.remove:SetText("Remove")
        row.label=row:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); row.label:SetPoint("LEFT",row.icon,"RIGHT",5,0); row.label:SetPoint("RIGHT",row.remove,"LEFT",-6,0); row.label:SetJustifyH("LEFT")
        row.remove:SetScript("OnClick",safe("remove ignored item",function()
            if row.itemID then DB.ignored[row.itemID]=nil; rebuild(); refreshIgnoredList() end
        end))
        return row
    end
    refreshIgnoredList=function()
        local ids={}
        for id,isIgnored in pairs(DB.ignored) do if isIgnored then ids[#ids+1]=id end end
        table.sort(ids)
        empty:SetShown(#ids==0)
        for index,itemID in ipairs(ids) do
            local row=rows[index] or makeRow(); rows[index]=row
            row.itemID=itemID; row:ClearAllPoints(); row:SetPoint("TOPLEFT",scrollChild,"TOPLEFT",0,-((index-1)*26)); row:SetPoint("RIGHT",scrollChild,"RIGHT",0,0)
            row.icon:SetTexture(ns.GetItemIcon(itemID)); row.label:SetText(ignoredItemText(itemID)); row:Show()
        end
        for index=#ids+1,#rows do rows[index]:Hide() end
        scrollChild:SetHeight(math.max(1,#ids*26))
        scroll:SetVerticalScroll(0)
    end
    panel:SetScript("OnShow",safe("options panel",refreshIgnoredList))
    refreshIgnoredList()
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end
local function slashImpl(msg)
    local cmd,arg=msg:match("^(%S*)%s*(.-)$");cmd=cmd:lower()
    if cmd=="errors" then
        if arg=="clear" then errorState.errors={} else for _,e in ipairs(errorState.errors) do print("Clickables error ["..tostring(e.time).."] "..e.label..": "..e.msg.."\n"..e.stack) end end
    elseif cmd=="debug" then
        errorState.debug=not errorState.debug;print("Clickables debug mode: "..tostring(errorState.debug))
        local clicks=frame.GetRegisteredClicks and table.concat({frame:GetRegisteredClicks()},", ") or "AnyUp, AnyDown (configured)"
        print("Clickables debug: type="..tostring(frame:GetAttribute("type"))..", item="..tostring(frame:GetAttribute("item"))..", type1="..tostring(frame:GetAttribute("type1"))..", item1="..tostring(frame:GetAttribute("item1"))..", ActionButtonUseKeyDown="..tostring(GetCVar and GetCVar("ActionButtonUseKeyDown"))..", clicks="..clicks)
    elseif cmd=="lock" then DB.locked=true elseif cmd=="unlock" then DB.locked=false elseif cmd=="scale" then DB.scale=tonumber(arg) or DB.scale;frame:SetScale(DB.scale) elseif cmd=="list" then
        for id in pairs(DB.ignored) do
            local itemID=id
            local name=ns.GetItemName(itemID)
            local link=name and ("|Hitem:"..itemID.."|h["..name.."]|h") or ("item:"..itemID)
            print("Clickables ignored: |T"..tostring(ns.GetItemIcon(itemID) or 134400)..":16|t "..link)
            if not name then ns.RequestItemLoad(itemID,safe("item load callback",function(loadedName,texture) if loadedName then print("Clickables ignored: |T"..tostring(texture or 134400)..":16|t |Hitem:"..itemID.."|h["..loadedName.."]|h") end end)) end
        end
    elseif cmd=="clear" then if not DB.clearUntil or GetTime()>DB.clearUntil then DB.clearUntil=GetTime()+5;print("Clickables: run /clickables clear again within 5 seconds") else wipe(DB.ignored);DB.clearUntil=nil;print("Clickables: ignore list cleared");if refreshIgnoredList then refreshIgnoredList() end end end;rebuild()
end
local slash=safe("slash command",slashImpl)
SLASH_CLICKABLES1="/clickables";SlashCmdList.CLICKABLES=slash
local events=CreateFrame("Frame");events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("BAG_UPDATE_DELAYED");events:RegisterEvent("PLAYER_ENTERING_WORLD");events:RegisterEvent("PLAYER_REGEN_ENABLED");events:RegisterEvent("QUEST_ACCEPTED");events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:RegisterEvent("UNIT_AURA");events:RegisterEvent("QUEST_LOG_UPDATE");events:RegisterEvent("QUEST_REMOVED")
events:SetScript("OnEvent",safe("event handler",function(_,event,name)
    if event=="GET_ITEM_INFO_RECEIVED" then if refreshIgnoredList then refreshIgnoredList() end
    elseif event=="ADDON_LOADED" and name==addonName then DB=ns.MergeDefaults(ClickablesDB);ClickablesDB=DB;position();options();rebuild()
    elseif event=="PLAYER_REGEN_ENABLED" then rebuild()
    elseif event=="UNIT_AURA" and name=="player" and not InCombatLockdown() then rebuild()
    elseif event=="QUEST_LOG_UPDATE" or event=="QUEST_ACCEPTED" or event=="QUEST_REMOVED" then ns.MarkQuestLogReady(questLogState);rebuild()
    elseif event=="BAG_UPDATE_DELAYED" or event=="PLAYER_ENTERING_WORLD" then rebuild() end
end))


