local _, ns = ...
ns = ns or {}

ns.Defaults = { point="CENTER", x=0, y=-120, scale=1, locked=false, hideWhenEmpty=false,
    openables=true, questStarters=true, scrolls=true, elixirs=true, food=true, classFilterOverride=false, ignored={} }
ns.OpenableItemIDs = {
    [5523]=true, [5524]=true, [5525]=true, [5526]=true,
    [16882]=true, [16883]=true, [16884]=true, [16885]=true,
    [5758]=true, [5759]=true, [5760]=true, [5761]=true,
}
-- Vanilla scroll IDs and their increasing buff ranks.
ns.ScrollItemIDs = {
    [954]={stat="strength",rank=1,name="Scroll of Strength I"}, [2289]={stat="strength",rank=2,name="Scroll of Strength II"}, [4426]={stat="strength",rank=3,name="Scroll of Strength III"}, [10310]={stat="strength",rank=4,name="Scroll of Strength IV"},
    [3012]={stat="agility",rank=1,name="Scroll of Agility I"}, [1477]={stat="agility",rank=2,name="Scroll of Agility II"}, [4425]={stat="agility",rank=3,name="Scroll of Agility III"}, [10309]={stat="agility",rank=4,name="Scroll of Agility IV"},
    [955]={stat="intellect",rank=1,name="Scroll of Intellect I"}, [2290]={stat="intellect",rank=2,name="Scroll of Intellect II"}, [4419]={stat="intellect",rank=3,name="Scroll of Intellect III"}, [10308]={stat="intellect",rank=4,name="Scroll of Intellect IV"},
    [1181]={stat="spirit",rank=1,name="Scroll of Spirit I"}, [1712]={stat="spirit",rank=2,name="Scroll of Spirit II"}, [4424]={stat="spirit",rank=3,name="Scroll of Spirit III"}, [10306]={stat="spirit",rank=4,name="Scroll of Spirit IV"},
    [1180]={stat="stamina",rank=1,name="Scroll of Stamina I"}, [1711]={stat="stamina",rank=2,name="Scroll of Stamina II"}, [4422]={stat="stamina",rank=3,name="Scroll of Stamina III"}, [10307]={stat="stamina",rank=4,name="Scroll of Stamina IV"},
    [3013]={stat="armor",rank=1,name="Scroll of Protection I"}, [1478]={stat="armor",rank=2,name="Scroll of Protection II"}, [4421]={stat="armor",rank=3,name="Scroll of Protection III"}, [10305]={stat="armor",rank=4,name="Scroll of Protection IV"},
}
-- Each record names its aura. Name matching is a fallback when spell IDs differ across client builds.
ns.ElixirItemIDs = {
    [2454]={category="battle", stat="agility", rank=1, name="Elixir of Lion's Strength", aura="Lion's Strength"},
    [5997]={category="guardian", stat="armor", rank=1, name="Elixir of Minor Defense", aura="Defense"},
    [3389]={category="guardian", stat="armor", rank=2, name="Elixir of Defense", aura="Defense"},
    [3390]={category="battle", stat="agility", rank=2, name="Elixir of Lesser Agility", aura="Agility"},
    [3383]={category="guardian", stat="stamina", rank=2, name="Elixir of Wisdom", aura="Wisdom"},
    [3388]={category="guardian", stat="stamina", rank=2, name="Strong Troll's Blood Elixir", aura="Troll's Blood"},
    [3825]={category="guardian", stat="stamina", rank=3, name="Elixir of Fortitude", aura="Fortitude"},
    [8949]={category="battle", stat="agility", rank=3, name="Elixir of Agility", aura="Agility"},
    [9179]={category="battle", stat="intellect", rank=4, name="Elixir of Greater Intellect", aura="Intellect"},
    [9206]={category="battle", stat="strength", rank=4, name="Elixir of Giants", aura="Giants"},
    [13452]={category="battle", stat="agility", rank=5, name="Elixir of the Mongoose", aura="Mongoose"},
    [9187]={category="battle", stat="agility", rank=4, name="Elixir of Greater Agility", aura="Agility"},
    [8951]={category="guardian", stat="stamina", rank=4, name="Elixir of Greater Defense", aura="Defense"},
}
-- Centralized tuning table for class/spec eligibility.
ns.ClassScrollRules = {
    WARRIOR={allow={stamina=true,armor=true,strength=true,agility=true}}, ROGUE={allow={stamina=true,armor=true,strength=true,agility=true}},
    MAGE={allow={stamina=true,armor=true,intellect=true,spirit=true}}, WARLOCK={allow={stamina=true,armor=true,intellect=true,spirit=true}}, PRIEST={allow={stamina=true,armor=true,intellect=true,spirit=true}},
    HUNTER={allow={stamina=true,armor=true,agility=true,intellect=true}},
    PALADIN={casterTabs={[1]=true},melee={strength=true,agility=true,stamina=true,armor=true},caster={intellect=true,spirit=true,stamina=true,armor=true}},
    SHAMAN={casterTabs={[1]=true,[3]=true},melee={strength=true,agility=true,stamina=true,armor=true},caster={intellect=true,spirit=true,stamina=true,armor=true}},
    DRUID={casterTabs={[3]=true},melee={strength=true,agility=true,stamina=true,armor=true},caster={intellect=true,spirit=true,stamina=true,armor=true}},
}
function ns.NewErrorState()
    return {errors={},last={},debug=false}
end
function ns.SafeCall(state, label, fn, now, printer)
    local ok, result = xpcall(fn, function(err) return {msg=tostring(err),stack=(debug and debug.traceback and debug.traceback("",2)) or ""} end)
    if ok then return true, result end
    local msg = type(result)=="table" and result.msg or tostring(result)
    local stack = type(result)=="table" and result.stack or ""
    now = now or 0
    local prev = state.last[msg]
    if not prev or now-prev >= 30 then
        state.last[msg]=now
        if printer then printer("Clickables: something went wrong ("..msg:sub(1,100).."). /clickables errors for details") end
    end
    state.errors[#state.errors+1]={msg=msg,stack=stack,time=now,label=label}
    while #state.errors>10 do table.remove(state.errors,1) end
    if state.debug and printer then printer("Clickables error stack: "..stack) end
    return false
end
function ns.ClassAllows(class, spec, stat, override)
    if override then return true end
    local rule=ns.ClassScrollRules[class]
    if not rule then return true end
    local allowed=rule.allow
    if rule.melee then allowed=(spec=="melee" and rule.melee) or (spec=="caster" and rule.caster) end
    return not allowed or allowed[stat] == true
end
function ns.ActiveRank(auras, stat)
    local rank=0
    for _,a in ipairs(auras or {}) do if a.stat==stat and (a.rank or 1)>rank then rank=a.rank or 1 end end
    return rank
end
function ns.ElixirConflict(auras, category)
    for _,a in ipairs(auras or {}) do if a.category==category then return true end end
    return false
end
function ns.FoodAuraActive(auras)
    local foodBuffs={[18192]=true,[18194]=true,[22730]=true,[25661]=true,[18125]=true,[18141]=true}
    for _,a in ipairs(auras or {}) do
        if a.name=="Well Fed" or a.name=="Food" or a.icon==133950 or a.spellID==19705 or foodBuffs[a.spellID] then return true end
    end
    return false
end
function ns.FoodTooltip(use)
    if not use then return nil end
    local lower=use:lower()
    if not lower:find("well fed",1,true) then return nil end
    local stats={"stamina","intellect","spirit","strength","agility"}
    local found={}
    for _,stat in ipairs(stats) do
        local n=lower:match("([%d%.]+)%s+"..stat) or lower:match(stat.."%s+by%s+([%d%.]+)")
        if n then found[#found+1]={stat=stat,bonus=tonumber(n) or 0} end
    end
    local bonus=0
    for _,entry in ipairs(found) do if entry.bonus>bonus then bonus=entry.bonus end end
    return {stats=found,bonus=bonus,stat=(#found==1 and found[1].stat or nil)}
end
function ns.FoodEligible(food,class,spec,override)
    if not food or not food.stats or #food.stats==0 then return true end
    if #food.stats>1 then return true end
    return ns.ClassAllows(class,spec,food.stats[1].stat,override)
end
function ns.BestFood(items)
    local best
    for _,item in ipairs(items or {}) do
        if not best or (item.bonus or 0)>(best.bonus or 0) or ((item.bonus or 0)==(best.bonus or 0) and (item.count or 1)>(best.count or 1)) then best=item end
    end
    return best
end
function ns.MergeDefaults(db, defaults)
    db=type(db)=="table" and db or {}; defaults=defaults or ns.Defaults
    for k,v in pairs(defaults) do if db[k]==nil then db[k]=type(v)=="table" and {} or v end end
    return db
end
function ns.ToggleIgnore(ignored,itemID)
    if not itemID then return false end; ignored=ignored or {}; ignored[itemID]=not ignored[itemID] or nil; return ignored[itemID]==true
end
function ns.GetItemInfo(itemID)
    if C_Item and C_Item.GetItemInfo then local info=C_Item.GetItemInfo(itemID); if info then return info end end
    if GetItemInfo then return GetItemInfo(itemID) end
end
function ns.GetItemName(itemID)
    local name=C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID); if name then return name end
    local info=ns.GetItemInfo(itemID); if type(info)=="table" then return info.itemName or info.name end; return info
end
function ns.RequestItemLoad(itemID,callback)
    if not Item or not Item.CreateFromItemID then return false end
    local item=Item:CreateFromItemID(itemID); if not item or not item.ContinueOnItemLoad then return false end
    item:ContinueOnItemLoad(function() if callback then callback(ns.GetItemName(itemID),ns.GetItemIcon(itemID)) end end); return true
end
function ns.GetItemIcon(itemID)
    return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID)) or (GetItemIcon and GetItemIcon(itemID)) or (GetItemInfo and select(10,GetItemInfo(itemID))) or 134400
end
function ns.GetContainerItemInfo(bag,slot)
    if C_Container and C_Container.GetContainerItemInfo then return C_Container.GetContainerItemInfo(bag,slot) end; if GetContainerItemInfo then return GetContainerItemInfo(bag,slot) end
end
function ns.GetContainerItemLink(bag,slot)
    if C_Container and C_Container.GetContainerItemLink then return C_Container.GetContainerItemLink(bag,slot) end; if GetContainerItemLink then return GetContainerItemLink(bag,slot) end
end
function ns.GetContainerNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) end; if GetContainerNumSlots then return GetContainerNumSlots(bag) end; return 0
end
function ns.UpdateView(current,queueLength,db,frame,icon,count,remain,inCombat)
    if inCombat then return end
    frame:SetAttribute("type","item");frame:SetAttribute("type1","item")
    if not current then frame:SetAttribute("item",nil);frame:SetAttribute("item1",nil);icon:SetTexture(nil);count:SetText("");remain:SetText("");if db.hideWhenEmpty then frame:Hide() else frame:SetAlpha(0.35);frame:Show() end;return end
    frame:SetAlpha(1);frame:Show();icon:SetTexture(ns.GetItemIcon(current.itemID));count:SetText(current.count>1 and current.count or "");remain:SetText(queueLength>1 and ((queueLength-1).." more") or "")
    local item="item:"..current.itemID;frame:SetAttribute("item",item);frame:SetAttribute("item1",item)
end
function ns.Classify(item,settings)
    settings=settings or ns.Defaults
    if not item or not item.itemID or (settings.ignored and settings.ignored[item.itemID]) or item.locked then return nil end
    if item.quest and settings.questStarters then return "quest" end
    if (item.lootable or item.tooltipOpenable or item.allowlisted) and settings.openables then return "openable" end
    return nil
end
function ns.SortQueue(items)
    local priority={quest=1,openable=2,elixir=3,scroll=4,food=5}
    table.sort(items,function(a,b) local pa,pb=priority[a.kind] or 99,priority[b.kind] or 99;if pa~=pb then return pa<pb end;if a.bag~=b.bag then return a.bag<b.bag end;return a.slot<b.slot end);return items
end
return ns
