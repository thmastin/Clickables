return function(ns,test)
 local function mockClient(saved,bags,tooltipBySlot)
  local timers,frames={},{}
  local client={bags=bags or {[0]={{itemID=5523,stackCount=1}}},tooltipBySlot=tooltipBySlot or {},tooltipFrames=0,scanCalls=0,combat=false,alt=false,keyDown=false,now=10,printed={}}
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
  env.C_Item={GetItemNameByID=function(id)return client.names and client.names[id] end,GetItemInfo=function(id)return client.names and client.names[id] end,RequestLoadItemDataByID=function(id)client.requested=client.requested or {};client.requested[id]=true end}
  env.C_Container={
   GetContainerNumSlots=function(bag)return #(client.bags[bag] or {})end,
   GetContainerItemInfo=function(bag,slot)return client.bags[bag] and client.bags[bag][slot]end,
   GetContainerItemQuestInfo=function()return nil end,
   GetContainerItemLink=function()return nil end,
  }
  env.C_UnitAuras={GetAuraDataByIndex=function(unit,index)
   if unit~="player" then return nil end
   local aura=client.auras and client.auras[index]
   if aura then return {name=aura.name,spellId=aura.spellID,icon=aura.icon}end
  end}
  env.C_QuestLog={IsOnQuest=function()return false end,IsQuestFlaggedCompleted=function()return false end}
  env.GetTalentTabInfo=function()return nil,nil,0 end
  env.UnitClass=function()return "Warrior","WARRIOR" end
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
    return function()end
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
   local c,env=mockClient();c:load()
   assert(table.concat(c.button.clicks,",")=="AnyUp,AnyDown")
   assert(c.button:GetAttribute("type1")=="item"and c.button:GetAttribute("item1")=="item:5523", "button item="..tostring(c.button:GetAttribute("item1")).." errors="..table.concat(c.printed," | "))
   assert(c.button:GetAttribute("type")==nil and c.button:GetAttribute("type2")==nil and c.button:GetAttribute("item2")==nil)
   c.alt=true
   c.keyDown=keyDown
   c.button.scripts.PreClick(c.button,"RightButton",false)
   c.button.scripts.PreClick(c.button,"RightButton",true)
   assert(env.ClickablesDB.ignored[5523]==true,"ignore toggle should fire exactly once keyDown="..tostring(keyDown).." output="..table.concat(c.printed," | "))
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
end
