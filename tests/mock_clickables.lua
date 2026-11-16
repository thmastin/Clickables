return function(ns,test)
 local function mockClient(saved,bags,tooltipBySlot,config)
  config=config or {}
  local timers,frames={},{}
  local client={bags=bags or {[0]={{itemID=5523,stackCount=1}}},tooltipBySlot=tooltipBySlot or {},tooltipFrames=0,scanCalls=0,combat=false,alt=false,keyDown=false,now=10,printed={},auras=config.auras or {},questInfo=config.questInfo or {},onQuest=config.onQuest or {},completed=config.completed or {},talentPoints=config.talentPoints or {0,0,0},className=config.className or "WARRIOR",localizedClass=config.localizedClass or "Warrior",classIDs=config.classIDs or {}}
  local function itemClass(id)if config.unknownClassIDs and config.unknownClassIDs[id] then return nil end;return client.classIDs[id] or 0 end
  client.names={}
  for itemID,data in pairs(ns.ScrollItemIDs)do client.names[itemID]=data.name:gsub(" I$","")end
  for itemID,data in pairs(ns.ElixirItemIDs)do client.names[itemID]=data.name end
  local env=setmetatable({},{__index=_G})
  env._G=env;env.unpack=unpack;env.ClickablesDB=saved;env.NUM_BAG_SLOTS=0
  env.UIParent={GetWidth=function()return 800 end,GetHeight=function()return 600 end}
  env.GetTime=function()return client.now end
  env.GetCVar=function()return client.keyDown and "1" or "0" end
  env.GetCVarBool=function()return client.keyDown end
  env.IsAltKeyDown=function()return client.alt end
  env.InCombatLockdown=function()return client.combat end
  env.print=function(...)client.printed[#client.printed+1]=table.concat({...}," ")end
  env.wipe=function(t)for k in pairs(t)do t[k]=nil end end
  env.C_Timer={After=function(_,fn)timers[#timers+1]=fn end}
  env.C_EventUtils={IsEventValid=function()return true end}
  env.C_Item={
   GetItemNameByID=function(id)return client.names and client.names[id] end,
   GetItemInfo=function(id)return client.names[id],nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,itemClass(id) end,
   GetItemInfoInstant=function(id)
    local classID=itemClass(id)
    return id,classID==0 and "Consumable" or "Item",classID==0 and "Food & Drink" or "Recipe",nil,nil,classID,0
   end,
   RequestLoadItemDataByID=function(id)client.requested=client.requested or {};client.requested[id]=true end
  }
  env.GetItemInfo=nil;env.GetItemInfoInstant=nil
  env.Enum={ItemClass={Consumable=0,Recipe=9}}
  env.C_Container={
   GetContainerNumSlots=function(bag)return #(client.bags[bag] or {})end,
   GetContainerItemInfo=function(bag,slot)return client.bags[bag] and client.bags[bag][slot]end,
   GetContainerItemQuestInfo=function(bag,slot)return client.questInfo[bag] and client.questInfo[bag][slot] end,
   GetContainerItemLink=function()return nil end,
  }
  env.C_UnitAuras={GetAuraDataByIndex=function(unit,index)
   if unit~="player" then return nil end
   local aura=client.auras[index]
   if aura then return {name=aura.name,spellId=aura.spellID,icon=aura.icon}end
  end}
  env.C_QuestLog={IsOnQuest=function(questID)return client.onQuest[questID] or false end,IsQuestFlaggedCompleted=function(questID)return client.completed[questID] or false end}
  env.GetTalentTabInfo=function(tab)return nil,nil,client.talentPoints[tab] or 0 end
  env.UnitClass=function()return client.localizedClass,client.className end
  env.C_Item.GetItemIconByID=function()return 134400 end
  env.ITEM_OPENABLE="Right Click to Open";env.ITEM_STARTS_QUEST="This Item Begins a Quest";env.ITEM_LOCKED="Locked"
  env.SlashCmdList={};env.InterfaceOptions_AddCategory=function()end
  local function widget(kind,name)
   local obj={kind=kind,name=name,scripts={},attributes={},events={},clicks={},lines={},text="",shown=false}
   local methods={
    SetScript=function(self,key,fn)self.scripts[key]=fn end,
    RegisterEvent=function(self,event)self.events[event]=true end,
    RegisterForClicks=function(self,...)self.clicks={...}end,
    GetRegisteredClicks=function(self)return unpack(self.clicks)end,
    SetAttribute=function(self,key,value)self.attributes[key]=value end,
    GetAttribute=function(self,key)return self.attributes[key]end,
    SetText=function(self,value)self.text=value end,
    GetText=function(self)return self.text end,
    SetChecked=function(self,value)self.checked=value end,
    GetChecked=function(self)return self.checked end,
    Show=function(self)self.shown=true end,
    Hide=function(self)self.shown=false end,
    SetShown=function(self,value)self.shown=value end,
    GetWidth=function()return 420 end,
    GetHeight=function()return 320 end,
    GetPoint=function()return "CENTER",nil,"CENTER",0,-120 end,
    SetSize=function()end,SetMovable=function()end,EnableMouse=function()end,RegisterForDrag=function()end,
    SetBackdrop=function()end,SetBackdropColor=function()end,SetAllPoints=function()end,SetPoint=function()end,
    SetAlpha=function()end,SetScale=function()end,ClearAllPoints=function()end,StartMoving=function()end,
    StopMovingOrSizing=function()end,SetMinMaxValues=function()end,SetValueStep=function()end,SetValue=function()end,
    SetWidth=function()end,SetHeight=function()end,SetJustifyH=function()end,SetScrollChild=function()end,
    SetVerticalScroll=function()end,
    SetOwner=function()end,SetHyperlink=function()end,AddLine=function()end,
    SetTexture=function(self,value)self.texture=value end,
    CreateTexture=function(self) return widget("Texture") end,
    CreateFontString=function(self,_,_,template)
     local fs=widget("FontString");fs.template=template
     if template=="NumberFontNormal" then self.countWidget=fs end
     return fs
    end,
    NumLines=function(self)return #self.lines end,
    SetBagItem=function(self,bag,slot)
     client.scanCalls=client.scanCalls+1;self.lines={}
     local source=client.tooltipBySlot[bag] and client.tooltipBySlot[bag][slot] or {}
     for i,lineText in ipairs(source)do
      local line=env["ClickablesScanTooltipTextLeft"..i]
      if not line then line=widget("TooltipLine");env["ClickablesScanTooltipTextLeft"..i]=line end
      line.text=lineText;self.lines[i]=line
     end
    end,
   }
   setmetatable(obj,{__index=function(self,key)
    if methods[key]then return methods[key]end
     error("unknown mock widget method: "..tostring(key).." on "..tostring(self.kind),2)
   end})
   return obj
  end
  env.CreateFrame=function(kind,name,parent,template)
   local frame=widget(kind,name);frame.template=template;frames[#frames+1]=frame
   if kind=="GameTooltip"then client.tooltipFrames=client.tooltipFrames+1 end
   if kind=="CheckButton"or kind=="Slider"then frame.Text=widget("FontString")end
   if name then env[name]=frame end
   return frame
  end
  local core=assert(loadfile("ClickablesCore.lua"));setfenv(core,env);core("Clickables",ns)
  local chunk=assert(loadfile("Clickables.lua"));setfenv(chunk,env);chunk("Clickables",ns)
  client.frames=frames
  client.button=env.ClickablesButton
  for _,frame in ipairs(frames)do if frame.kind=="Frame"and frame.events.ADDON_LOADED then client.eventFrame=frame end end
  client.fire=function(self,event,...)
   assert(client.eventFrame and client.eventFrame.scripts.OnEvent,"addon event frame missing")
   client.eventFrame.scripts.OnEvent(client.eventFrame,event,...)
  end
  client.flush=function()
   while #timers>0 do local pending=timers;timers={};for _,fn in ipairs(pending)do fn()end end
  end
  client.load=function()
   client:fire("ADDON_LOADED","Clickables");client.flush()
  end
  client.setCombat=function(value)client.combat=value end
  return client,env
 end

 test("real Clickables button click phases toggle ignore once without right action",function()
  for _,keyDown in ipairs({false,true})do
   local c,env=mockClient(nil,{[0]={{itemID=5523,stackCount=1},{itemID=5524,stackCount=1}}});c:load()
   assert(table.concat(c.button.clicks,",")=="AnyUp,AnyDown")
   assert(c.button:GetAttribute("type1")=="item"and c.button:GetAttribute("item1")=="item:5523", "button item="..tostring(c.button:GetAttribute("item1")).." errors="..table.concat(c.printed," | "))
   assert(c.button:GetAttribute("type")==nil and c.button:GetAttribute("type2")==nil and c.button:GetAttribute("item2")==nil)
   c.alt=true
   c.keyDown=keyDown
   c.button.scripts.PreClick(c.button,"RightButton",false)
   c.button.scripts.PreClick(c.button,"RightButton",true)
   local ignoredCount=0;for _,id in ipairs({5523,5524})do if env.ClickablesDB.ignored[id]then ignoredCount=ignoredCount+1 end end
   assert(ignoredCount==1 and env.ClickablesDB.ignored[5523]and not env.ClickablesDB.ignored[5524],"one physical click must ignore only the original queue item")
  end
 end)

 test("priority setting controls mixed-kind rebuild order",function()
  local c=mockClient({priority={"food","quest","openable","elixir","scroll"}},
   {[0]={{itemID=2454,stackCount=1},{itemID=2888,stackCount=1}}},
   {[0]={[2]={"Use: Eat to become Well Fed and gain 1 Strength for 15 min."}}})
  c:load();assert(c.button:GetAttribute("item1")=="item:2888","saved priority should put food before elixir")
 end)

 test("recipe tooltip cannot become food and Blood Sausage remains eligible",function()
  local c,env=mockClient(nil,{[0]={{itemID=3679,stackCount=1},{itemID=3220,stackCount=1}}},
   {[0]={[1]={"Use: Eat to become Well Fed and gain 3 Strength for 15 min."},[2]={"Use: Eat to become Well Fed and gain 2 Strength for 15 min."}}},
   {classIDs={[3679]=9,[3220]=0}})
  c:load()
  assert(env.GetItemInfo==nil and env.GetItemInfoInstant==nil,"Forever mock should expose class APIs only on C_Item")
  assert(c.button:GetAttribute("item1")=="item:3220","Blood Sausage should win while recipe is excluded")
  c.bags[0][3]={itemID=100001,stackCount=1};c.bags[0][4]={itemID=5758,stackCount=1}
  c.bags[0][5]={itemID=6948,stackCount=1};c.bags[0][6]={itemID=2454,stackCount=1}
  c.classIDs[100001]=4;c.classIDs[5758]=1;c.classIDs[6948]=0;c.classIDs[2454]=0
  c.tooltipBySlot[0][3]={"Equip: Increases Strength by 7."}
  c.tooltipBySlot[0][5]={"Use: Returns you to your home."}
  c.tooltipBySlot[0][6]={"Use: Increases Strength by 5."}
  c.names[3679]="Recipe: Blood Sausage"
  env.SlashCmdList.CLICKABLES("debug");c:fire("BAG_UPDATE_DELAYED");c:flush()
  local found,unexpectedSkipped= false,{}
  for _,line in ipairs(c.printed)do
   if line:find("Clickables Recipe: Blood Sausage (3679): skipped, recipe",1,true) then found=true end
   if line:find("skipped",1,true) and (line:find("100001",1,true) or line:find("5758",1,true) or line:find("6948",1,true) or line:find("2454",1,true)) then unexpectedSkipped[#unexpectedSkipped+1]=line end
  end
  assert(found,"debug should report recipe exclusion")
  assert(#unexpectedSkipped==0,"gear and openable lockbox should not produce skipped lines: "..table.concat(unexpectedSkipped," | "))

  local unknown,unknownEnv=mockClient(nil,{[0]={{itemID=3679,stackCount=1},{itemID=3220,stackCount=1}}},
   {[0]={[1]={"Use: Eat to become Well Fed and gain 3 Strength for 15 min."},[2]={"Use: Eat to become Well Fed and gain 2 Strength for 15 min."}}},
   {unknownClassIDs={[3679]=true}})
  unknown.names[3679]="Recipe: Blood Sausage"
  unknown:load()
  assert(unknown.button:GetAttribute("item1")=="item:3220","unknown-class recipe name should be excluded while Blood Sausage remains eligible")
  assert(unknownEnv.GetItemInfo==nil and unknownEnv.GetItemInfoInstant==nil)
 end)

 test("recipe tooltip cannot enter elixir or scroll candidates",function()
  local c=mockClient(nil,{[0]={{itemID=2454,stackCount=1},{itemID=954,stackCount=1}}},
   {[0]={[1]={"Use: Teaches Elixir of Lion's Strength. Use: Increases Strength by 5."},[2]={"Use: Teaches Scroll of Strength I. Increases Strength by 5."}}},
   {classIDs={[2454]=9,[954]=9}})
  c:load()
  assert(c.button:GetAttribute("item1")==nil,"recipe must not enter elixir or scroll candidates")
 end)

 test("ignored food and scroll items are skipped by rebuild",function()
  for _,itemID in ipairs({2888,954})do
   local c=mockClient({ignored={[itemID]=true}}, {[0]={{itemID=itemID,stackCount=1}}},
    {[0]={[1]={"Use: Eat to become Well Fed and gain 1 Strength for 15 min."}}})
   c:load();assert(c.button:GetAttribute("item1")==nil,"ignored item must not enter queue: "..itemID)
  end
 end)

 test("event bursts coalesce; combat updates count and regen rebuilds once",function()
  local c=mockClient();c:load();local baseline=c.scanCalls
  for i=1,25 do
   if i%4==0 then c:fire("UNIT_AURA","player")
   elseif i%4==1 then c:fire("QUEST_LOG_UPDATE")
   elseif i%4==2 then c:fire("QUEST_ACCEPTED",1)
   else c:fire("BAG_UPDATE_DELAYED")end
  end
  c:flush();assert(c.scanCalls==baseline+1,"25 refresh events should rebuild once baseline="..baseline.." actual="..c.scanCalls)
  baseline=c.scanCalls;c.combat=true;c.bags[0][1].stackCount=7
  for i=1,25 do c:fire(i%2==0 and "BAG_UPDATE_DELAYED"or "UNIT_AURA","player")end
  c:flush();assert(c.scanCalls==baseline,"combat must not rebuild")
  assert(c.button.count.text==7,"combat count should update live after the event burst")
  c.combat=false;c:fire("PLAYER_REGEN_ENABLED");c:flush();assert(c.scanCalls==baseline+1)
  baseline=c.scanCalls;c:fire("BAG_UPDATE_DELAYED");c.combat=true;c:flush()
  assert(c.scanCalls==baseline,"queued timer must respect combat lockdown")
  c.combat=false;c:fire("PLAYER_REGEN_ENABLED");c:flush();assert(c.scanCalls==baseline+1)
 end)

 test("item info refreshes only carried or pending item IDs",function()
  local c=mockClient();c:load();local baseline=c.scanCalls
  c:fire("GET_ITEM_INFO_RECEIVED",99999,true);c:flush();assert(c.scanCalls==baseline,"unrelated item must not rebuild")
  c:fire("GET_ITEM_INFO_RECEIVED",5523,true);c:flush();assert(c.scanCalls==baseline+1,"carried item should rebuild")
  local pending,env=mockClient({ignored={[999]=true}});pending:load();baseline=pending.scanCalls
  assert(pending.requested and pending.requested[999],"ignored list item load should be pending")
  pending:fire("GET_ITEM_INFO_RECEIVED",999,true);pending:flush();assert(pending.scanCalls==baseline+1,"pending item should rebuild")
 end)

 test("repeated scans reuse one tooltip and read picked lockboxes by bag slot",function()
  local c=mockClient(nil,{[0]={{itemID=5758,stackCount=1}}},{[0]={[1]={"Locked"}}});c:load()
  assert(c.tooltipFrames==1 and c.button:GetAttribute("item1")==nil,"locked box should be skipped")
  c.tooltipBySlot[0][1]={};c:fire("BAG_UPDATE_DELAYED");c:flush()
  assert(c.button:GetAttribute("item1")=="item:5758","picked box should not inherit the locked tooltip")
  c.tooltipBySlot[0][1]={"Locked"};c:fire("BAG_UPDATE_DELAYED");c:flush()
  assert(c.button:GetAttribute("item1")==nil,"locked box should be skipped on a cached item scan")
  for i=1,5 do c:fire("BAG_UPDATE_DELAYED");c:flush()end
  assert(c.tooltipFrames==1,"only one scan tooltip frame may be created")
 end)

 test("v1.2.0 saved settings migrate without losing user values",function()
  local oldIgnore={[12345]=true};local saved={ignored=oldIgnore,point="TOPLEFT",x=45,y=67,scale=1.6}
  local c,env=mockClient(saved);c:load()
  assert(env.ClickablesDB.ignored==oldIgnore and env.ClickablesDB.ignored[12345])
  assert(env.ClickablesDB.point=="TOPLEFT"and env.ClickablesDB.x==45 and env.ClickablesDB.y==67 and env.ClickablesDB.scale==1.6)
  assert(env.ClickablesDB.settingsVersion==2 and #env.ClickablesDB.priority==5)
  assert(table.concat(env.ClickablesDB.priority,",")=="quest,openable,elixir,scroll,food")
 end)

 test("rebuild deduplicates a three-slot item ID and keeps the summed count",function()
  local c=mockClient(nil,{[0]={{itemID=5523,stackCount=1},{itemID=5523,stackCount=1},{itemID=5523,stackCount=1}}});c:load()
  assert(c.button:GetAttribute("item1")=="item:5523","deduplicated current item should remain selectable")
  assert(c.button.count.text==3,"dedupe real rebuild should report total count 3")
  assert(c.button.remain.text=="","duplicate stacks must not add queued actions")
 end)

 test("rebuild chooses highest carried scroll and suppresses buffed rank IV by ID",function()
  local c=mockClient(nil,{[0]={{itemID=954,stackCount=1},{itemID=2289,stackCount=1}}});c:load()
  assert(c.button:GetAttribute("item1")=="item:2289","Rank I should be hidden when only Rank II is also carried")
  assert(c.button.remain.text=="","only Rank II should remain queued")
  local buffed=mockClient(nil,{[0]={{itemID=10309,stackCount=1}}},nil,{auras={{name="Agility",spellID=12174}}});buffed:load()
  assert(buffed.button:GetAttribute("item1")==nil,"Rank IV agility aura should suppress Scroll of Agility IV by spell ID")
 end)

 test("Alt right-click during combat does not change ignore list",function()
  local c,env=mockClient(nil,{[0]={{itemID=5523,stackCount=1},{itemID=5524,stackCount=1}}});c:load()
  c.combat=true;c.alt=true;c.keyDown=true;c.button.scripts.PreClick(c.button,"RightButton",true)
  assert(not env.ClickablesDB.ignored[5523] and not env.ClickablesDB.ignored[5524])
 end)

 test("non-player UNIT_AURA does not schedule rebuild",function()
  local c=mockClient();c:load();local baseline=c.scanCalls
  c:fire("UNIT_AURA","target");c:flush();assert(c.scanCalls==baseline)
 end)

 test("debug output omits secure attributes and count hides one",function()
  local c,env=mockClient();c:load()
  assert(c.button.count.text=="")
  env.SlashCmdList.CLICKABLES("debug")
  for _,line in ipairs(c.printed)do assert(not line:find("type1=",1,true) and not line:find("item1=",1,true),"debug must omit plain secure attributes") end
 end)

 test("mock widgets reject unknown API methods",function()
  local c=mockClient();local ok,err=pcall(function()c.button.SetWidht(c.button,10)end)
  assert(not ok and tostring(err):find("unknown mock widget method",1,true))
 end)

 test("errors clear slash command empties the error history",function()
  local c,env=mockClient(nil,{[0]={{itemID=5523,stackCount=1}}});c:load();c.alt=true;c.keyDown=true
  local original=env.C_Item.GetItemNameByID;env.C_Item.GetItemNameByID=function()error("lookup failure")end
  c.button.scripts.PreClick(c.button,"RightButton",true);env.C_Item.GetItemNameByID=original
  env.SlashCmdList.CLICKABLES("errors clear")
  local before=#c.printed;env.SlashCmdList.CLICKABLES("errors");assert(#c.printed==before,"cleared errors should print nothing")
 end)

 test("rebuild suppresses matching elixir spell ID but ignores unrelated intellect and fortitude buffs",function()
  local unrelated=mockClient(nil,{[0]={{itemID=2454,stackCount=1}}},nil,{auras={{name="Arcane Intellect",spellID=1459},{name="Fortitude",spellID=3593}}});unrelated:load()
  assert(unrelated.button:GetAttribute("item1")=="item:2454","unrelated buffs must not suppress Lion's Strength")
  local matching=mockClient(nil,{[0]={{itemID=2454,stackCount=1}}},nil,{auras={{name="Lion's Strength",spellID=2367}}});matching:load()
  assert(matching.button:GetAttribute("item1")==nil,"matching elixir buff ID should suppress the item; got="..tostring(matching.button:GetAttribute("item1")))
 end)

 test("rebuild skips quest starters already active or completed",function()
  local tooltip={[0]={[1]={"This Item Begins a Quest"}}}
  local cases={
   {"active item flag",{questInfo={[0]={[1]={isQuestItem=true,questID=41,isActive=true}}}},nil},
   {"quest already active",{questInfo={[0]={[1]={isQuestItem=true,questID=41,isActive=false}}},onQuest={[41]=true}},nil},
   {"completed quest",{questInfo={[0]={[1]={isQuestItem=true,questID=41,isActive=false}}},completed={[41]=true}},nil},
  }
  for _,case in ipairs(cases)do
   local c=mockClient(nil,{[0]={{itemID=18000,stackCount=1}}},tooltip,case[2]);c:load()
   c:fire("QUEST_LOG_UPDATE");c:flush()
   assert(c.button:GetAttribute("item1")==nil,case[1].." quest starter should be skipped")
  end
 end)

 test("rebuild skips buff food while Well Fed or eating aura is active",function()
  for _,aura in ipairs({{name="Well Fed",spellID=19705},{name="Food",icon=133950}})do
   local c=mockClient(nil,{[0]={{itemID=2888,stackCount=1}}},nil,{auras={aura}});c:load()
   assert(c.button:GetAttribute("item1")==nil,"active food aura must suppress food")
  end
 end)

 test("Forever XP food ranks useful meals first and offers off-stat fallback",function()
  local xp="Use: If you spend at least 10 sec eating, you will become well fed and gain 1 Intellect for 15 min. Additionally, experience gained from kills is increased by 5%."
  local ap="Use: If you spend at least 10 sec eating, you will become well fed and gain 2 Attack Power for 15 min. Additionally, experience gained from kills is increased by 5%."
  local stew,env=mockClient(nil,{[0]={{itemID=5477,stackCount=1},{itemID=6290,stackCount=1}}},{[0]={[1]={xp},[2]={ap}}},{className="WARLOCK",localizedClass="Warlock"})
  stew:load();assert(stew.button:GetAttribute("item1")=="item:5477","useful Intellect food must beat off-stat XP food")
  local only=mockClient(nil,{[0]={{itemID=6290,stackCount=1}}},{[0]={[1]={ap}}},{className="WARLOCK",localizedClass="Warlock"})
  only:load();assert(only.button:GetAttribute("item1")=="item:6290","XP food should remain as a tier 2 fallback")
  local warrior=mockClient(nil,{[0]={{itemID=5477,stackCount=1},{itemID=6290,stackCount=1}}},{[0]={[1]={xp},[2]={ap}}},{className="WARRIOR",localizedClass="Warrior"})
  warrior:load();assert(warrior.button:GetAttribute("item1")=="item:6290","Attack Power food should be useful to warriors")
  assert(env.ClickablesDB~=nil)
 end)

 test("identical scans print food debug lines only once",function()
  local use="Use: If you spend at least 10 sec eating, you will become well fed and gain 1 Strength for 15 min. Additionally, experience gained from kills is increased by 5%."
  local c,env=mockClient(nil,{[0]={}},{[0]={[1]={use}}});c:load()
  env.SlashCmdList.CLICKABLES("debug");c.bags[0][1]={itemID=2888,stackCount=1};c:fire("BAG_UPDATE_DELAYED");c:flush()
  local first=0;for _,line in ipairs(c.printed)do if line:find("Clickables food",1,true)then first=first+1 end end
  c:fire("BAG_UPDATE_DELAYED");c:flush()
  local total=0;for _,line in ipairs(c.printed)do if line:find("Clickables food",1,true)then total=total+1 end end
  assert(first>0 and total==first,"identical result should not repeat food diagnostics")
 end)

 test("both talent-change events rebuild and rerank hybrid scrolls",function()
  local c=mockClient(nil,{[0]={{itemID=954,stackCount=1},{itemID=955,stackCount=1}}},nil,{className="PALADIN",localizedClass="Paladin",talentPoints={0,5,0}});c:load()
  assert(c.button:GetAttribute("item1")=="item:954","melee spec should queue Strength")
  assert(c.eventFrame.events.PLAYER_TALENT_UPDATE and c.eventFrame.events.CHARACTER_POINTS_CHANGED)
  c.talentPoints={5,0,0};local before=c.scanCalls;c:fire("PLAYER_TALENT_UPDATE");c:flush()
  assert(c.scanCalls==before+2 and c.button:GetAttribute("item1")=="item:955","talent update should queue Intellect for caster spec")
  c.talentPoints={0,5,0};before=c.scanCalls;c:fire("CHARACTER_POINTS_CHANGED");c:flush()
  assert(c.scanCalls==before+2 and c.button:GetAttribute("item1")=="item:954","character points change should restore melee ranking")
 end)

 test("slash clear requires a second call within five seconds",function()
  local c,env=mockClient({ignored={[5523]=true}});c:load()
  env.SlashCmdList.CLICKABLES("clear");assert(env.ClickablesDB.ignored[5523])
  c.now=14.9;env.SlashCmdList.CLICKABLES("clear");assert(next(env.ClickablesDB.ignored)==nil,"second clear within five seconds should empty the ignore list")
  env.ClickablesDB.ignored[5523]=true;c.now=20;env.SlashCmdList.CLICKABLES("clear")
  c.now=25.1;env.SlashCmdList.CLICKABLES("clear");assert(env.ClickablesDB.ignored[5523],"an expired confirmation must only arm a new window")
 end)
end
