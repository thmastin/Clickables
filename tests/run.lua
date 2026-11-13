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
test("ignored item names prefer C_Item and fall back to GetItemInfo",function()
 local oldCItem,oldInfo=C_Item,GetItemInfo
 C_Item={GetItemNameByID=function(id) if id==12 then return "Known item" end end}
 GetItemInfo=function() return "Fallback item" end
 assert(ns.GetItemName(12)=="Known item" and ns.GetItemName(13)=="Fallback item")
 C_Item,GetItemInfo=oldCItem,oldInfo
end)
test("updateView works when GetItemIcon is unavailable",function()
 local oldIcon,oldInfo,oldCItem=GetItemIcon,GetItemInfo,C_Item
 GetItemIcon=nil; C_Item=nil
 GetItemInfo=function(id) return "Item",nil,nil,nil,nil,nil,nil,nil,nil,"icon-"..id end
 local view={texture=nil,text=nil,attributes={},alpha=nil,shown=false}
 local frame={SetAlpha=function(_,v)view.alpha=v end,Show=function()view.shown=true end,
  Hide=function()view.shown=false end,SetAttribute=function(_,k,v)view.attributes[k]=v end}
 local icon={SetTexture=function(_,v)view.texture=v end}
 local count={SetText=function(_,v)view.count=v end}
 local remain={SetText=function(_,v)view.remain=v end}
 ns.UpdateView({itemID=42,bag=0,slot=3,count=2},2,{hideWhenEmpty=false},frame,icon,count,remain,false)
 assert(view.texture=="icon-42" and view.attributes.type=="item" and view.attributes.type1=="item")
 assert(view.attributes.item=="item:42" and view.attributes.item1=="item:42")
 assert(view.count==2 and view.remain=="1 more" and view.shown)
 ns.UpdateView(nil,0,{hideWhenEmpty=false},frame,icon,count,remain,false)
 assert(view.attributes.item==nil and view.attributes.item1==nil)
 GetItemIcon,GetItemInfo,C_Item=oldIcon,oldInfo,oldCItem
end)
print("PASS "..passed.." tests")
