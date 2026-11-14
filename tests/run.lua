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
test("active quest starter is skipped",function()
 local item={questID=41,isQuestItem=true,isActive=true}
 assert(not ns.QuestDecision(item,false,{ready=true}))
 assert(not ns.QuestDecision({questID=41,isQuestItem=true},false,{ready=true,onQuest=true}))
end)
test("completed quest starter is skipped",function()
 assert(not ns.QuestDecision({questID=42,isQuestItem=true},false,{ready=true,completed=true}))
end)
test("empty quest log at load waits for a rescan",function()
 local state=ns.NewQuestLogState()
 local item={questID=43,isQuestItem=true,isActive=false}
 assert(not ns.QuestDecision(item,false,{ready=state.ready,onQuest=false,completed=false}))
 ns.MarkQuestLogReady(state)
 assert(ns.QuestDecision(item,false,{ready=state.ready,onQuest=false,completed=false}))
end)
test("tooltip quest fallback only applies without a quest ID",function()
 assert(ns.QuestDecision(nil,true,{ready=false}))
 assert(not ns.QuestDecision(nil,false,{ready=false}))
 assert(not ns.QuestDecision({questID=44,isActive=false},true,{ready=false}))
 assert(ns.QuestDecision({questID=44,isActive=false},false,{ready=true}))
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
test("buff rank comparison keeps stronger active buffs",function()
 assert(ns.ActiveRank({{stat="agility",rank=2},{stat="agility",rank=4}},"agility")==4)
 assert(ns.ActiveRank({{stat="spirit",rank=1}},"agility")==0)
end)
test("class and spec filtering with override",function()
 assert(not ns.ClassAllows("WARRIOR",nil,"intellect",false))
 assert(ns.ClassAllows("WARRIOR",nil,"stamina",false))
 assert(not ns.ClassAllows("MAGE",nil,"agility",false))
 assert(ns.ClassAllows("HUNTER",nil,"intellect",false) and not ns.ClassAllows("HUNTER",nil,"spirit",false))
 assert(ns.ClassAllows("DRUID","caster","spirit",false) and not ns.ClassAllows("DRUID","caster","strength",false))
 assert(ns.ClassAllows("PALADIN","melee","strength",false) and ns.ClassAllows("PALADIN","melee","spirit",true))
end)
test("battle and guardian elixir conflicts",function()
 assert(ns.ElixirConflict({{category="battle"}},"battle"))
 assert(not ns.ElixirConflict({{category="guardian"}},"battle"))
end)
test("full queue priority order",function()
 local q={{kind="food",bag=0,slot=1},{kind="scroll",bag=0,slot=2},{kind="elixir",bag=0,slot=3},{kind="openable",bag=0,slot=4},{kind="quest",bag=0,slot=5}}
 ns.SortQueue(q);assert(q[1].kind=="quest" and q[2].kind=="openable" and q[3].kind=="elixir" and q[4].kind=="scroll" and q[5].kind=="food")
end)
test("Well Fed active skips food",function()
 assert(ns.FoodAuraActive({{name="Well Fed"}}))
 assert(ns.FoodAuraActive({{spellID=19705}}))
 assert(not ns.FoodAuraActive({{name="Arcane Intellect"}}))
end)
test("eating aura skips food",function()
 assert(ns.FoodAuraActive({{name="Food",icon=133950}}))
end)
test("class filtering on stat food",function()
 local stamina=ns.FoodTooltip("Use: Eat to become Well Fed and gain 2 Stamina for 15 min.")
 local intellect=ns.FoodTooltip("Use: Eat to become Well Fed and gain 3 Intellect for 15 min.")
 assert(ns.FoodEligible(stamina,"MAGE",nil,false))
 assert(not ns.FoodEligible(intellect,"WARRIOR",nil,false))
 assert(ns.FoodEligible(intellect,"WARRIOR",nil,true))
 local mixed=ns.FoodTooltip("Use: Eat to become Well Fed and gain 3 Intellect and 2 Agility for 15 min.")
 assert(ns.FoodEligible(mixed,"WARRIOR",nil,false))
end)
test("best food uses highest stat then larger stack",function()
 local best=ns.BestFood({{itemID=1,bonus=2,count=20},{itemID=2,bonus=4,count=1},{itemID=3,bonus=4,count=3}})
 assert(best.itemID==3)
end)
test("food tooltip fallback",function()
 assert(ns.FoodTooltip("Use: Eat to become Well Fed for 15 seconds."))
 assert(ns.FoodTooltip("Use: Eat for 10 seconds, then become well fed and gain 2 Stamina."))
 assert(not ns.FoodTooltip("Use: well fed and gain 2 Stamina for 15 min."))
 assert(not ns.FoodTooltip("Use: Restores health over 20 seconds."))
end)
test("safe call logs, throttles, caps, and clears",function()
 local s=ns.NewErrorState();local messages={}
 local function run(t) ns.SafeCall(s,"test",function() error("boom") end,t,function(m)messages[#messages+1]=m end) end
 run(1);run(2);run(31);assert(#messages==2 and #s.errors==3 and s.errors[1].stack~="")
 for i=1,9 do run(60+i*30) end
 assert(#s.errors==10);s.errors={};assert(#s.errors==0)
end)
print("PASS "..passed.." tests")
