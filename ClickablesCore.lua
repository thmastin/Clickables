local _, ns = ...
ns = ns or {}

ns.Defaults = { point="CENTER", x=0, y=-120, scale=1, locked=false, hideWhenEmpty=false,
    openables=true, questStarters=true, ignored={} }
ns.OpenableItemIDs = {
    [5523]=true, [5524]=true, [5525]=true, [5526]=true, -- clams
    [16882]=true, [16883]=true, [16884]=true, [16885]=true, -- junkboxes
    [5758]=true, [5759]=true, [5760]=true, [5761]=true, -- lockboxes
}

function ns.MergeDefaults(db, defaults)
    db = type(db) == "table" and db or {}
    defaults = defaults or ns.Defaults
    for k,v in pairs(defaults) do
        if db[k] == nil then db[k] = type(v)=="table" and {} or v end
    end
    return db
end

function ns.ToggleIgnore(ignored, itemID)
    if not itemID then return false end
    ignored = ignored or {}
    ignored[itemID] = not ignored[itemID] or nil
    return ignored[itemID] == true
end

function ns.GetItemInfo(itemID)
    if C_Item and C_Item.GetItemInfo then
        local info = C_Item.GetItemInfo(itemID)
        if info then return info end
    end
    if GetItemInfo then return GetItemInfo(itemID) end
end

function ns.GetItemName(itemID)
    local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    if name then return name end
    local info = ns.GetItemInfo(itemID)
    if type(info) == "table" then return info.itemName or info.name end
    return info
end

function ns.RequestItemLoad(itemID, callback)
    if not Item or not Item.CreateFromItemID then return false end
    local item = Item:CreateFromItemID(itemID)
    if not item or not item.ContinueOnItemLoad then return false end
    item:ContinueOnItemLoad(function()
        if callback then callback(ns.GetItemName(itemID), ns.GetItemIcon(itemID)) end
    end)
    return true
end

function ns.GetItemIcon(itemID)
    return (C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID))
        or (GetItemIcon and GetItemIcon(itemID))
        or (GetItemInfo and select(10, GetItemInfo(itemID)))
        or 134400
end

function ns.GetContainerItemInfo(bag, slot)
    if C_Container and C_Container.GetContainerItemInfo then return C_Container.GetContainerItemInfo(bag, slot) end
    if GetContainerItemInfo then return GetContainerItemInfo(bag, slot) end
end

function ns.GetContainerItemLink(bag, slot)
    if C_Container and C_Container.GetContainerItemLink then return C_Container.GetContainerItemLink(bag, slot) end
    if GetContainerItemLink then return GetContainerItemLink(bag, slot) end
end

function ns.GetContainerNumSlots(bag)
    if C_Container and C_Container.GetContainerNumSlots then return C_Container.GetContainerNumSlots(bag) end
    if GetContainerNumSlots then return GetContainerNumSlots(bag) end
    return 0
end

function ns.UpdateView(current, queueLength, db, frame, icon, count, remain, inCombat)
    if inCombat then return end
    frame:SetAttribute("type", "item")
    frame:SetAttribute("type1", "item")
    if not current then
        frame:SetAttribute("item", nil); frame:SetAttribute("item1", nil)
        icon:SetTexture(nil); count:SetText(""); remain:SetText("")
        if db.hideWhenEmpty then frame:Hide() else frame:SetAlpha(0.35); frame:Show() end
        return
    end
    frame:SetAlpha(1); frame:Show(); icon:SetTexture(ns.GetItemIcon(current.itemID))
    count:SetText(current.count > 1 and current.count or "")
    remain:SetText(queueLength > 1 and ((queueLength - 1) .. " more") or "")
    local item = current.bag .. " " .. current.slot
    frame:SetAttribute("item", item)
    frame:SetAttribute("item1", item)
end

function ns.Classify(item, settings)
    settings = settings or ns.Defaults
    if not item or not item.itemID or (settings.ignored and settings.ignored[item.itemID]) or item.locked then return nil end
    if item.quest and settings.questStarters then return "quest" end
    if (item.lootable or item.tooltipOpenable or item.allowlisted) and settings.openables then return "openable" end
    return nil
end

function ns.SortQueue(items)
    table.sort(items, function(a,b)
        if a.kind ~= b.kind then return a.kind == "quest" end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    return items
end

return ns
