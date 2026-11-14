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
test("quest badge shows only for quest starters",function()
 local badge={texture=nil,shown=false,SetTexture=function(self,v)self.texture=v end,Show=function(self)self.shown=true end,Hide=function(self)self.shown=false end}
 local frame={SetAlpha=function()end,Show=function()end,Hide=function()end,SetAttribute=function()end}
 local icon={SetTexture=function()end};local count={SetText=function()end};local remain={SetText=function()end}
 local function show(kind,active)
  ns.UpdateView({itemID=42,kind=kind,questActive=active,count=1},1,{},frame,icon,count,remain,false,badge)
 end
 show("quest",false);assert(badge.shown and badge.texture=="Interface\\ContainerFrame\\UI-Icon-QuestBang")
 show("quest",true);assert(badge.shown and badge.texture=="Interface\\ContainerFrame\\UI-Icon-QuestBorder")
 for _,kind in ipairs({"openable","elixir","scroll","food"}) do show(kind,false);assert(not badge.shown,kind.." must not show the quest badge") end
 show(nil,false);assert(not badge.shown)
end)
test("button count sums item stacks across bags and hides one",function()
 local oldContainer,oldSlots=C_Container,NUM_BAG_SLOTS
 local bags={
  [0]={{itemID=77,stackCount=2},{itemID=77,stackCount=3}},
  [1]={{itemID=77,stackCount=4}},
 }
 NUM_BAG_SLOTS=1
 C_Container={
  GetContainerNumSlots=function(bag)return #(bags[bag] or {}) end,
  GetContainerItemInfo=function(bag,slot)return bags[bag] and bags[bag][slot] end,
 }
 local shown
 local widget={SetText=function(_,v)shown=v end}
 local current={itemID=77,count=1}
 assert(ns.UpdateItemCount(current,widget)==9 and current.count==9 and shown==9)
 bags[0]={{itemID=77,stackCount=1}};bags[1]={}
 assert(ns.UpdateItemCount(current,widget)==1 and current.count==1 and shown=="")
 C_Container,NUM_BAG_SLOTS=oldContainer,oldSlots
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
test("Forever food Use tooltips parse Strength and Attack Power",function()
 local boar=ns.FoodTooltip("Restores 58 health over 18 sec. Must remain seated while eating. If you spend at least 10 sec eating, you will become well fed and gain 1 Strength for 15 min. Additionally, experience gained from kills is increased by 5%.")
 assert(boar and boar.stats[1].stat=="strength" and boar.bonus==1)
 local fish=ns.FoodTooltip("Restores 58 health over 10 sec. Must remain seated while eating. If you spend at least 10 sec eating, you will become well fed and gain 2 Attack Power for 15 min. Additionally, experience gained from kills is increased by 5%.")
 assert(fish and fish.stats[1].stat=="attack_power" and fish.bonus==2)
 assert(ns.FoodItemIDs[2888].stat=="strength" and ns.FoodItemIDs[6290].stat=="attack_power")
end)
test("wrapped food Use text is joined before matching",function()
 local use=ns.JoinTooltipLines({"Restores 58 health over 18 sec. Must remain seated while eating. If you spend at least 10 sec eating, you will become", "well fed and gain 1 Strength for 15 min."})
 local food=ns.FoodTooltip(use)
 assert(food and food.stats[1].stat=="strength")
end)
test("Attack Power food is limited to melee and hunter",function()
 local ap=ns.FoodTooltip("If you eat, you will become well fed and gain 2 Attack Power for 15 min.")
 assert(ns.FoodEligible(ap,"WARRIOR",nil,false))
 assert(ns.FoodEligible(ap,"HUNTER",nil,false))
 assert(ns.FoodEligible(ap,"SHAMAN","melee",false))
 assert(not ns.FoodEligible(ap,"SHAMAN","caster",false))
 assert(not ns.FoodEligible(ap,"PRIEST",nil,false))
end)
test("zero talent points leave hybrid spec unknown",function()
 assert(ns.DominantTalentTab({0,0,0})==nil)
 assert(ns.ClassAllows("SHAMAN",nil,"strength",false))
 assert(ns.ClassAllows("SHAMAN",nil,"attack_power",false))
 assert(ns.ClassAllows("SHAMAN",nil,"intellect",false))
 assert(not ns.ClassAllows("MAGE",nil,"attack_power",false))
 assert(ns.StatWeight("SHAMAN",nil,"strength")==2)
 assert(ns.StatWeight("SHAMAN",nil,"attack_power")==1)
end)
test("Enhancement Shaman weights ribs and smallfish equally",function()
 local ribs=ns.FoodData(2888,nil)
 local fish=ns.FoodData(6290,nil)
 ribs.score=ns.ItemStatScore(ribs.stats,"SHAMAN","melee");ribs.count=1
 fish.score=ns.ItemStatScore(fish.stats,"SHAMAN","melee");fish.count=6
 assert(ribs.score==2 and fish.score==2)
 assert(ns.BestFood({ribs,fish})==fish)
end)
test("Rogue Agility beats Attack Power",function()
 assert(ns.StatScore("agility",1,"ROGUE",nil)>ns.StatScore("attack_power",1,"ROGUE",nil))
end)
test("Caster Intellect beats Stamina baseline",function()
 assert(ns.StatScore("intellect",1,"MAGE",nil)>ns.StatScore("stamina",1,"MAGE",nil))
end)
test("stat score tie uses total item count",function()
 local a={itemID=1,score=2,count=2};local b={itemID=2,score=2,count=9}
 assert(ns.BestFood({a,b})==b)
end)
test("battle and guardian elixir conflicts",function()
 assert(ns.ElixirConflict({{category="battle"}},"battle"))
 assert(not ns.ElixirConflict({{category="guardian"}},"battle"))
end)
test("full queue priority order",function()
 local q={{kind="food",bag=0,slot=1},{kind="scroll",bag=0,slot=2},{kind="elixir",bag=0,slot=3},{kind="openable",bag=0,slot=4},{kind="quest",bag=0,slot=5}}
 ns.SortQueue(q);assert(q[1].kind=="quest" and q[2].kind=="openable" and q[3].kind=="elixir" and q[4].kind=="scroll" and q[5].kind=="food")
end)
test("scores order candidates within their queue category",function()
 local q={{kind="elixir",score=2,bag=0,slot=1},{kind="elixir",score=5,bag=1,slot=1},{kind="scroll",score=20,bag=0,slot=2}}
 ns.SortQueue(q)
 assert(q[1].kind=="elixir" and q[1].score==5 and q[2].kind=="elixir" and q[3].kind=="scroll")
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
 assert(ns.FoodTooltip("Use: well fed and gain 2 Stamina for 15 min."))
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
