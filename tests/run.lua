local ns={}
assert(loadfile("ClickablesCore.lua"))("Clickables",ns)
local passed=0
local function test(name,fn) fn();passed=passed+1;print("PASS "..name) end

test("openable classification",function()
 assert(ns.Classify({itemID=1,lootable=true})=="openable")
 assert(ns.Classify({itemID=2,tooltipOpenable=true})=="openable")
 assert(ns.Classify({itemID=3,allowlisted=true})=="openable")
end)
test("quest classification and priority",function()
 assert(ns.Classify({itemID=4,quest=true})=="quest")
 local q={{kind="openable",bag=0,slot=1},{kind="quest",bag=2,slot=3},{kind="quest",bag=0,slot=8}}
 ns.SortQueue(q);assert(q[1].kind=="quest" and q[1].bag==0 and q[2].kind=="quest" and q[3].kind=="openable")
end)
test("locked and ignored skipped",function()
 assert(ns.Classify({itemID=5,lootable=true,locked=true})==nil)
 assert(ns.Classify({itemID=6,lootable=true},{openables=true,questStarters=true,ignored={[6]=true}})==nil)
end)
test("defaults merge preserves saved values",function()
 local d={scale=1.4,ignored={[7]=true}};assert(ns.MergeDefaults(d)==d);assert(d.scale==1.4 and d.locked==false and d.ignored[7])
end)
test("ignore toggling",function()
 local ignored={};assert(ns.ToggleIgnore(ignored,9)==true and ignored[9]);assert(ns.ToggleIgnore(ignored,9)==false and not ignored[9])
end)
print("PASS "..passed.." tests")
