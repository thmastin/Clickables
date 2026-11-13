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
