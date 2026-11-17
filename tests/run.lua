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
test("defaults deep-copy nested tables and validate settings lists",function()
 local d=ns.MergeDefaults({priority={"food","food","bad"},ignored="bad"})
 assert(d.settingsVersion==2 and d.ignored and #d.priority==5 and d.priority[1]=="food")
 d.priority[1]="changed";assert(ns.Defaults.priority[1]=="quest")
 local a=ns.MergeDefaults({});a.priority[1]="changed";local b=ns.MergeDefaults({});assert(b.priority[1]=="quest")
 local laterDefaults={settingsVersion=3,priority={"quest","openable","elixir","scroll","food"},ignored={},future={nested={values={11,22}}}}
 local oldSaved={scale=1.25};local migrated=ns.MergeDefaults(oldSaved,laterDefaults)
 migrated.future.nested.values[1]=99
 assert(laterDefaults.future.nested.values[1]==11,"new nested defaults must not alias the defaults table")
 local second=ns.MergeDefaults({},laterDefaults)
 assert(second.future.nested.values[1]==11,"new SavedVariables must receive an independent deep copy")
end)
test("ignore toggling",function()
 local ignored={};assert(ns.ToggleIgnore(ignored,9)==true and ignored[9]);assert(ns.ToggleIgnore(ignored,9)==false and not ignored[9])
end)
test("Alt right-click toggle runs only on the configured click phase",function()
 for _,keyDown in ipairs({false,true}) do
  local calls=0
  for _,down in ipairs({false,true}) do if ns.ShouldHandleClickPhase(down,keyDown) then calls=calls+1 end end
  assert(calls==1)
 end
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
 assert(view.texture=="icon-42" and view.attributes.type==nil and view.attributes.type1=="item")
 assert(view.attributes.item==nil and view.attributes.item1=="item:42")
 assert(view.count==2 and view.remain=="+1 queued" and view.shown)
 ns.UpdateView(nil,0,{hideWhenEmpty=false},frame,icon,count,remain,false)
 assert(view.attributes.item==nil and view.attributes.item1==nil)
 GetItemIcon,GetItemInfo,C_Item=oldIcon,oldInfo,oldCItem
end)
test("quest badge shows only for quest starters",function()
 local badge={texture=nil,shown=false,SetTexture=function(self,v)self.texture=v end,SetAllPoints=function(self,icon)self.anchoredTo=icon end,Show=function(self)self.shown=true end,Hide=function(self)self.shown=false end}
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
 assert(boar.xp==true)
 local fish=ns.FoodTooltip("Restores 58 health over 10 sec. Must remain seated while eating. If you spend at least 10 sec eating, you will become well fed and gain 2 Attack Power for 15 min. Additionally, experience gained from kills is increased by 5%.")
 assert(fish and fish.stats[1].stat=="attack_power" and fish.bonus==2)
 assert(ns.FoodItemIDs[2888].stat=="strength" and ns.FoodItemIDs[6290].stat=="attack_power")
end)
test("Forever food parses caster, healer, mana, critical, armor, and unknown stats",function()
 local cases={
  {"Spell Damage","spell_damage"},{"healing spells","healing"},{"Healing","healing"},
  {"Spell Power","spell_damage"},{"mana every 5 sec","mp5"},{"mp5","mp5"},
  {"Spell Critical","spell_critical"},{"Armor","armor"},
 }
 for _,case in ipairs(cases)do
  local food=ns.FoodTooltip("Use: Eat to become Well Fed and gain 1 "..case[1].." for 15 min.")
  assert(food and food.stats[1] and food.stats[1].stat==case[2],"failed stat phrase: "..case[1])
 end
 local healingSpells=ns.FoodTooltip("Use: Eat to become Well Fed and gain 3 healing spells for 15 min.")
 assert(#healingSpells.stats==1 and healingSpells.stats[1].stat=="healing" and healingSpells.stats[1].bonus==3,"healing spells must map to healing once")
 local unknown=ns.FoodTooltip("Use: Eat to become Well Fed and gain 7 Nature Resistance for 15 min.")
 assert(unknown and #unknown.stats==0 and unknown.rawStatPhrase=="nature resistance")
 assert(ns.StatWeight("WARLOCK",nil,"spell_damage")>0)
 assert(ns.StatWeight("PRIEST",nil,"healing")>0 and ns.StatWeight("PRIEST",nil,"mp5")>0)
 assert(ns.FoodItemIDs[787].bonus==6 and ns.FoodData(787,nil).stats[1].bonus==6,"Slitherskin Mackerel fallback should match its 6 AP tooltip")
 assert(ns.StatWeight("WARRIOR",nil,"healing")==0 and ns.StatWeight("WARRIOR",nil,"mp5")==0)
end)
test("required level parser reads English tooltip requirement",function()
 assert(ns.RequiredLevel("Requires Level 12")==12)
 assert(ns.RequiredLevel("REQUIRES LEVEL 60")==60)
 assert(ns.RequiredLevel("Requires level 100 skill") == 100)
 assert(ns.RequiredLevel("Use: Eat to become Well Fed.")==nil)
end)
test("Forever XP food preserves XP flag and filters plain off-stat food",function()
 local xp=ns.FoodTooltip("If you spend at least 10 sec eating, you will become well fed and gain 2 Attack Power for 15 min. Additionally, Experience Gained From Kills Is Increased By 5%.")
 local plain=ns.FoodTooltip("If you spend at least 10 seconds eating, you will become well fed and gain 2 Attack Power for 15 min.")
 assert(xp.xp and not plain.xp)
 assert(ns.FoodEligible(xp,"WARLOCK",nil,false) and not ns.FoodEligible(plain,"WARLOCK",nil,false))
 assert(ns.FoodEligible(xp,"WARLOCK",nil,true))
 for _,itemID in ipairs({6290,2888,5477,6888,4592})do assert(ns.FoodItemIDs[itemID] and ns.FoodData(itemID,nil).xp,"Forever XP food fallback should be flagged: "..itemID)end
 for _,itemID in ipairs({17197,17198,5527,21023})do assert(not ns.FoodItemIDs[itemID],"plain Well Fed food must not be marked as XP fallback: "..itemID)end
end)
test("food tiers always rank useful food ahead of XP off-stat food",function()
 local off={itemID=6290,score=2,count=1,tier=2}
 local useful={itemID=5477,score=2,count=8,tier=1}
 assert(ns.BestFood({off,useful})==useful)
 assert(ns.BestFood({off})==off)
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
test("caster damage and healing stats filter by class",function()
 local spell=ns.FoodTooltip("Use: Eat to become Well Fed and gain 1 Spell Damage for 15 min.")
 local healing=ns.FoodTooltip("Use: Eat to become Well Fed and gain 1 Healing for 15 min.")
 assert(ns.FoodEligible(spell,"WARLOCK",nil,false) and not ns.FoodEligible(spell,"WARRIOR",nil,false))
 assert(ns.FoodEligible(healing,"PRIEST",nil,false) and not ns.FoodEligible(healing,"WARRIOR",nil,false))
end)
test("caster and healer stat weights are explicit by class and spec",function()
 local checks={
  {"MAGE",nil,"healing",0},{"MAGE",nil,"mp5",0},{"MAGE",nil,"spell_critical",1.5},{"MAGE",nil,"spirit",1.5},
  {"WARLOCK",nil,"healing",0},{"WARLOCK",nil,"mp5",0},{"WARLOCK",nil,"spell_critical",1.5},{"WARLOCK",nil,"spirit",1.5},
  {"PRIEST",nil,"healing",2},{"PRIEST",nil,"mp5",1.5},{"PRIEST",nil,"spell_critical",0.5},{"PRIEST",nil,"spirit",1.5},
  {"DRUID","caster","healing",2},{"DRUID","caster","mp5",1.25},{"DRUID","caster","spell_critical",1},{"DRUID","caster","spirit",1},
  {"DRUID","melee","healing",0},{"DRUID","melee","mp5",0},{"DRUID","melee","spell_critical",0},{"DRUID","melee","spirit",0},
  {"SHAMAN","caster","healing",2},{"SHAMAN","caster","mp5",1.25},{"SHAMAN","caster","spell_critical",1},{"SHAMAN","caster","spirit",0.75},
  {"SHAMAN","melee","healing",0},{"SHAMAN","melee","mp5",0},{"SHAMAN","melee","spell_critical",0},{"SHAMAN","melee","spirit",0},
  {"PALADIN","caster","healing",2},{"PALADIN","caster","mp5",1.5},{"PALADIN","caster","spell_critical",0.5},{"PALADIN","caster","spirit",1},
  {"PALADIN","melee","healing",0},{"PALADIN","melee","mp5",0},{"PALADIN","melee","spell_critical",0},{"PALADIN","melee","spirit",0},
 }
 for _,c in ipairs(checks)do assert(ns.StatWeight(c[1],c[2],c[3])==c[4],c[1].."/"..tostring(c[2]).." "..c[3].." weight")end
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
 assert(ns.BestFood({ribs,fish})==ribs)
end)
test("Rogue Agility beats Attack Power",function()
 assert(ns.StatScore("agility",1,"ROGUE",nil)>ns.StatScore("attack_power",1,"ROGUE",nil))
end)
test("Caster Intellect beats Stamina baseline",function()
 assert(ns.StatScore("intellect",1,"MAGE",nil)>ns.StatScore("stamina",1,"MAGE",nil))
end)
test("stat score tie favors smaller total count then smaller slot stack",function()
 local smallerTotal={itemID=1,score=2,count=2,slotCount=2};local largerTotal={itemID=2,score=2,count=9,slotCount=1}
 assert(ns.BestFood({largerTotal,smallerTotal})==smallerTotal)
 local smallerSlot={itemID=3,score=2,count=5,slotCount=2};local largerSlot={itemID=4,score=2,count=5,slotCount=4}
 assert(ns.BestFood({largerSlot,smallerSlot})==smallerSlot)
end)
test("duplicate item queue selection prefers smallest carried stack, then bag and slot",function()
 local duplicate={{itemID=8,bag=1,slot=2,slotCount=3},{itemID=8,bag=0,slot=4,slotCount=2},{itemID=8,bag=0,slot=2,slotCount=2}}
 local q=ns.DedupeQueue(duplicate,{[8]=8})
 assert(#q==1 and q[1].bag==0 and q[1].slot==2 and q[1].slotCount==2 and q[1].count==8)
end)
test("elixir aura uses spell ID or exact fallback",function()
 local elixir={aura="Greater Defense",auraSpellID=11349}
 assert(ns.ElixirAuraActive({{spellID=11349,name="Armor"}},elixir))
 assert(not ns.ElixirAuraActive({{spellID=1,name="Greater Defense"}},elixir))
 assert(ns.ElixirAuraActive({{name="Greater Defense"}},{aura="Greater Defense"}))
 assert(not ns.ElixirConflict({{category="battle"}},"battle"))
end)
test("Forever elixir aura spell IDs",function()
 local expected={
  {2454,2367,"https://www.wowhead.com/classic/spell=2367/lions-strength"}, -- Lion's Strength
  {5997,673,"https://www.wowhead.com/classic/spell=673/armor"}, -- Minor Defense
  {3389,3220,"https://www.wowhead.com/classic/spell=3220/defense"}, -- Defense
  {3390,3160,"https://www.wowhead.com/classic/spell=3160/lesser-agility"}, -- Lesser Agility
  {3383,3166,"https://www.wowhead.com/classic/spell=3166/wisdom"}, -- Wisdom
  {3825,3593,"https://www.wowhead.com/classic/spell=3593/fortitude"}, -- Fortitude
  {8949,11328,"https://www.wowhead.com/classic/spell=11328/agility"}, -- Agility
  {9179,11396,"https://www.wowhead.com/classic/spell=11396/greater-intellect"}, -- Greater Intellect
  {9206,11405,"https://www.wowhead.com/classic/spell=11405/giants"}, -- Giants
  {13452,17538,"https://www.wowhead.com/classic/spell=17538/mongoose"}, -- Mongoose
  {9187,11334,"https://www.wowhead.com/classic/spell=11334/greater-agility"}, -- Greater Agility
  {8951,11349,"https://www.wowhead.com/classic/spell=11349/greater-defense"}, -- Greater Defense
 }
 assert(#expected==12)
 for _,ref in ipairs(expected) do assert(ns.ElixirItemIDs[ref[1]].auraSpellID==ref[2],"elixir aura ID mismatch: "..ref[3]) end
 local total=0;for _ in pairs(ns.ElixirItemIDs) do total=total+1 end;assert(total==#expected)
end)
test("scroll aura spell IDs cover every rank",function()
 local expected={
  {"strength",1,8118,"https://www.wowhead.com/classic/spell=8118/strength"}, -- Strength I
  {"strength",2,8119,"https://www.wowhead.com/classic/spell=8119/strength"}, -- Strength II
  {"strength",3,8120,"https://www.wowhead.com/classic/spell=8120/strength"}, -- Strength III
  {"strength",4,12179,"https://www.wowhead.com/classic/spell=12179/strength"}, -- Strength IV
  {"agility",1,8115,"https://www.wowhead.com/classic/spell=8115/agility"}, -- Agility I
  {"agility",2,8116,"https://www.wowhead.com/classic/spell=8116/agility"}, -- Agility II
  {"agility",3,8117,"https://www.wowhead.com/classic/spell=8117/agility"}, -- Agility III
  {"agility",4,12174,"https://www.wowhead.com/classic/spell=12174/agility"}, -- Agility IV
  {"intellect",1,8096,"https://www.wowhead.com/classic/spell=8096/intellect"}, -- Intellect I
  {"intellect",2,8097,"https://www.wowhead.com/classic/spell=8097/intellect"}, -- Intellect II
  {"intellect",3,8098,"https://www.wowhead.com/classic/spell=8098/intellect"}, -- Intellect III
  {"intellect",4,12176,"https://www.wowhead.com/classic/spell=12176/intellect"}, -- Intellect IV
  {"spirit",1,8112,"https://www.wowhead.com/classic/spell=8112/spirit"}, -- Spirit I
  {"spirit",2,8113,"https://www.wowhead.com/classic/spell=8113/spirit"}, -- Spirit II
  {"spirit",3,8114,"https://www.wowhead.com/classic/spell=8114/spirit"}, -- Spirit III
  {"spirit",4,12177,"https://www.wowhead.com/classic/spell=12177/spirit"}, -- Spirit IV
  {"stamina",1,8099,"https://www.wowhead.com/classic/spell=8099/stamina"}, -- Stamina I
  {"stamina",2,8100,"https://www.wowhead.com/classic/spell=8100/stamina"}, -- Stamina II
  {"stamina",3,8101,"https://www.wowhead.com/classic/spell=8101/stamina"}, -- Stamina III
  {"stamina",4,12178,"https://www.wowhead.com/classic/spell=12178/stamina"}, -- Stamina IV
  {"armor",1,8091,"https://www.wowhead.com/classic/spell=8091/protection"}, -- Protection I
  {"armor",2,8094,"https://www.wowhead.com/classic/spell=8094/protection"}, -- Protection II
  {"armor",3,8095,"https://www.wowhead.com/classic/spell=8095/protection"}, -- Protection III
  {"armor",4,12175,"https://www.wowhead.com/classic/spell=12175/protection"}, -- Protection IV
 }
 for _,ref in ipairs(expected) do local aura=ns.ScrollAuraSpellIDs[ref[3]];assert(aura and aura.stat==ref[1] and aura.rank==ref[2],"scroll aura ID mismatch: "..ref[4]) end
 local total=0;for _ in pairs(ns.ScrollAuraSpellIDs) do total=total+1 end;assert(total==#expected)
 assert(ns.ScrollAuraSpellIDs[12174].rank==4 and ns.ScrollAuraSpellIDs[12174].stat=="agility")
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
test("shared comparator favors smaller total and single stack counts",function()
 local q={{kind="elixir",score=3,count=8,slotCount=1},{kind="elixir",score=3,count=2,slotCount=4},{kind="elixir",score=3,count=2,slotCount=1}}
 ns.SortQueue(q);assert(q[1].slotCount==1 and q[2].slotCount==4 and q[3].count==8)
 local ordered={{kind="elixir",score=10},{kind="food",score=1}}
 ns.SortQueue(ordered,{"food","quest","openable","elixir","scroll"});assert(ordered[1].kind=="food")
end)
test("adjacent carried scroll ranks suppress all lower ranks",function()
 local ranks=ns.BestCarriedRanks({{stat="strength",rank=2},{stat="strength",rank=3},{stat="agility",rank=1}})
 assert(ranks.strength==3 and ranks.agility==1 and ranks.intellect==nil)
 assert(ranks.strength>2 and ranks.strength>1)
end)
test("queue candidates deduplicate by item ID while preserving total count",function()
 local q=ns.DedupeQueue({{itemID=5,count=2,score=1},{itemID=5,count=2,score=3},{itemID=6,count=1}}, {[5]=7,[6]=1})
 assert(#q==2 and q[1].count==7 and q[1].score==3 and q[2].itemID==6)
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
test("best food uses highest stat then smaller total stack",function()
 local best=ns.BestFood({{itemID=1,bonus=2,count=20},{itemID=2,bonus=4,count=1},{itemID=3,bonus=4,count=3}})
 assert(best.itemID==2)
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
 assert(#s.errors==10);for i=1,500 do ns.SafeCall(s,"unique",function()error("unique-"..i)end,1000+i,function()end) end
 local throttleCount=0;for _ in pairs(s.last)do throttleCount=throttleCount+1 end;assert(throttleCount<=100,"throttle map must stay bounded")
 s.errors={};assert(#s.errors==0)
end)
assert(loadfile("tests/mock_clickables.lua"))()(ns,test)
print("PASS "..passed.." tests")
