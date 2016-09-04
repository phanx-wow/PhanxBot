--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
	Copyright (c) 2008-2016 Phanx <addons@phanx.net>. All rights reserved.
----------------------------------------------------------------------]]

local ADDON, Addon = ...
local L = Addon.L

local questChoicePending, questChoiceFinished

local ignoreGossip      = Addon.GossipToIgnore
local ignoreGossipNPC   = Addon.GossipNPCsToIgnore
local confirmGossipNPC  = Addon.GossipNPCsToConfirm
local selectMultiGossip = Addon.GossipToSelect
local dismountForGossip = Addon.GossipNeedsDismount

local ignoreQuest       = Addon.QuestsToIgnore
local ignoreQuestNPC    = Addon.QuestNPCsToIgnore
local questRewardValues = Addon.QuestRewardValues

local repeatableQuestRequirements = Addon.RepeatableQuestRequirements

------------------------------------------------------------------------

local function GetNPCID()
	return tonumber(strmatch(UnitGUID("npc") or "", "Creature%-.-%-.-%-.-%-.-%-(.-)%-"))
end

local function IsTrackingTrivial()
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		if name == MINIMAP_TRACKING_TRIVIAL_QUESTS then
			return active
		end
	end
end

local function StripText(text)
	if not text then return "" end
	text = gsub(text, "%[.*%]%s*","")
	text = gsub(text, "|c%x%x%x%x%x%x%x%x(.+)|r","%1")
	text = gsub(text, "(.+) %(.+%)", "%1")
	return strtrim(text)
end

------------------------------------------------------------------------
--	Accept and turn in quests

function Addon:QUEST_GREETING()
	if HydraSettings and HydraSettings.Quest.enable then return end
	self:Debug("QUEST_GREETING")
	if ignoreQuestNPC[GetNPCID()] or IsShiftKeyDown() then return end
	-- Turn in complete quests:
	for i = 1, GetNumActiveQuests() do
		local title, complete = GetActiveTitle(i)
		self:Debug("Checking active quest:", title)
		if complete and not ignoreQuest[StripText(title)] then
			self:Debug("Select!")
			SelectActiveQuest(i)
		end
	end
	-- Pick up available quests:
	for i = 1, GetNumAvailableQuests() do
		local title = StripText(GetAvailableTitle(i))
		self:Debug("Checking available quest:", title)
		if not ignoreQuest[title] and (not IsAvailableQuestTrivial(i) or IsTrackingTrivial()) then
			self:Debug("Select!")
			SelectAvailableQuest(i)
		end
	end
end

function Addon:QUEST_DETAIL()
	if HydraSettings and HydraSettings.Quest.enable then return end
	--self:Debug("QUEST_DETAIL")
	if IsShiftKeyDown() then return end

	local giver = UnitName("questnpc")
	local item, _, _, _, minLevel = GetItemInfo(giver or "")
	if not item or not minLevel or minLevel < 2 or (UnitLevel("player") - minLevel < GetQuestGreenRange()) or IsTrackingTrivial() then
		-- No way to get the quest level from the item, so if the item
		-- doesn't have a level requirement, we just have to take it.
		--self:Debug("Accepting quest %q from %s", StripText(GetTitleText()), giver)
		AcceptQuest()
	end
end

function Addon:QUEST_ACCEPT_CONFIRM(event, giver, quest)
	if HydraSettings and HydraSettings.Quest.enable then return end
	--self:Debug("QUEST_ACCEPT_CONFIRM", giver, quest)
	if IsShiftKeyDown() then return end
	AcceptQuest()
	--ConfirmAcceptQuest()
	--StaticPopup_Hide("QUEST_ACCEPT")
end

function Addon:QUEST_ACCEPTED(event, id)
	if HydraSettings and HydraSettings.Quest.enable then return end
	--self:Debug("QUEST_ACCEPTED", id)
	if QuestFrame:IsShown() and QuestGetAutoAccept() then
		CloseQuest()
	end
	if not GetCVarBool("autoQuestWatch") or IsQuestWatched(id) or GetNumQuestWatches() >= MAX_WATCHABLE_QUESTS then return end
	--self:Debug("Adding quest to tracker")
	AddQuestWatch(id)
end

function Addon:QUEST_PROGRESS()
	if HydraSettings and HydraSettings.Quest.enable then return end
	--self:Debug("QUEST_PROGRESS")
	if IsShiftKeyDown() or not IsQuestCompletable() then return end
	--self:Debug("Completing quest", StripText(GetTitleText()))
	CompleteQuest()
end

function Addon:QUEST_ITEM_UPDATE()
	if HydraSettings and HydraSettings.Quest.enable then return end
	--self:Debug("QUEST_ITEM_UPDATE", questChoicePending)
	if questChoicePending then
		self:QUEST_COMPLETE("QUEST_ITEM_UPDATE")
	end
end

function Addon:QUEST_COMPLETE()
	if HydraSettings and HydraSettings.Quest.enable then return end
	if not questChoicePending then
		--self:Debug("QUEST_COMPLETE")
		if IsShiftKeyDown() then return end
	end
	local choices = GetNumQuestChoices()
	if choices <= 1 then
		--self:Debug("Completing quest", StripText(GetTitleText()), choices == 1 and "with only reward" or "with no reward")
		GetQuestReward(1)
	elseif choices > 1 then
		--self:Debug("Quest has multiple rewards, not automating")
		local bestValue, bestIndex = 0
		for i = 1, choices do
			local link = GetQuestItemLink("choice", i)
			if link then
				local _, _, _, _, _, _, _, _, _, _, value = GetItemInfo(link)
				value = questRewardValues[tonumber(strmatch(link, "item:(%d+)"))] or value or 0
				if value > bestValue then
					bestValue, bestIndex = value, i
				end
			else
				questChoicePending = true
				return GetQuestItemInfo("choice", i)
			end
		end
		if bestIndex then
			questChoiceFinished = true
			QuestInfoItem_OnClick(QuestInfoRewardsFrame.RewardButtons[bestIndex])
		end
		QuestRewardScrollFrame:SetVerticalScroll(QuestRewardScrollFrame:GetVerticalScrollRange())
	end
end

function Addon:QUEST_FINISHED()
	if HydraSettings and HydraSettings.Quest.enable then return end
	--self:Debug("QUEST_FINISHED")
	if questChoiceFinished then
		questChoicePending = false
	end
end

function Addon:QUEST_AUTOCOMPLETE(event, id)
	if HydraSettings and HydraSettings.Quest.enable then return end
	--self:Debug("QUEST_AUTOCOMPLETE", id)
	local index = GetQuestLogIndexByID(id)
	if GetQuestLogIsAutoComplete(index) then
		ShowQuestComplete(index)
	end
end

--[[
	local popups = GetNumAutoQuestPopups()
	if popups == 0 then return end
	for i = popups, 1, -1 do
		local id, status = GetAutoQuestPopup(i)
		if status == "COMPLETE" then
			ShowQuestComplete(GetQuestLogIndexByID(id))
		end
	end
]]

------------------------------------------------------------------------
--	Skip gossips when there's only one option
--	Select quest gossips for pickup and turnin

local gossipLastSeen = {}

function Addon:GOSSIP_SHOW(event)
	--self:Debug("GOSSIP_SHOW")
	if IsShiftKeyDown() then return end

	if self.db.automateQuests and not (HydraSettings and HydraSettings.Quest.enable) then
		-- Turn in complete quests:
		for i = 1, GetNumGossipActiveQuests() do
			local title, level, isLowLevel, isComplete, isLegendary, isIgnored = select(i * 6 - 5, GetGossipActiveQuests())
			--self:Debug("ACTIVE:", i, '"'..title..'"', isLowLevel, isRepeatable)
			if isComplete and not ignoreQuest[title] then
				--self:Debug("Turn in:", title)
				return SelectGossipActiveQuest(i)
			end
		end
		-- Pick up available quests:
		Addon.LocalizeQuestNames()
		for i = 1, GetNumGossipAvailableQuests() do
			local title, level, isLowLevel, isDaily, isRepeatable, isLegendary, isIgnored = select(i * 7 - 6, GetGossipAvailableQuests())
			--self:Debug("AVAILALBLE:", i, '"'..title..'"', isLowLevel, isRepeatable)
			if not ignoreQuest[title] then
				local go
				local req = isRepeatable and repeatableQuestRequirements[title]
				if req then
					if type(req) == "number" then
						go = GetItemCount(req) >= 1
					else
						go = GetItemCount(req[1]) >= req[2]
					end
					--self:Debug("Repeatable", go)
				else
					go = not isLowLevel or IsTrackingTrivial()
					--self:Debug("Accept", go)
				end
				if go then
					--self:Debug("Go!")
					return SelectGossipAvailableQuest(i)
				end
			end
		end
	end
	
	if not self.db.skipGossip then return end

	-- Process other gossips:
	local npcID = GetNPCID()
	local _, instanceType = GetInstanceInfo()
	--self:Debug(instanceType, ignoreGossipNPC[npcID], GetNumGossipAvailableQuests(), GetNumGossipActiveQuests(), selectMultiGossip[npcID])
	if instanceType == "raid" or ignoreGossipNPC[npcID] or GetNumGossipAvailableQuests() > 0 or GetNumGossipActiveQuests() > 0 then return end

	local pickIndex, gossipText, gossipType = selectMultiGossip[npcID], GetGossipOptions()
	if not pickIndex and gossipType == "gossip" and not ignoreGossip[gossipText] and not dismountForGossip[gossipText] and GetNumGossipOptions() == 1 and (GetTime() - (gossipLastSeen[gossipText] or 0) > 0.5) then
		pickIndex = 1
	end
	if pickIndex then
		--self:Debug("Selecting gossip \"" .. gossipText .. "\"")
		gossipLastSeen[gossipText] = GetTime()
		if dismountForGossip[npcID] or dismountForGossip[gossipText] then
			--self:Debug("Dismounting")
			Dismount()
		end
		SelectGossipOption(pickIndex)
	end
end

function Addon:GOSSIP_CONFIRM(event, index)
	local npcID = GetNPCID()
	if npcID and confirmGossipNPC[npcID] then
		--self:Debug("Confirmed gossip")
		SelectGossipOption(index, "", true)
		StaticPopup_Hide("GOSSIP_CONFIRM")
	end
end

------------------------------------------------------------------------
--	Dismount for transport-related gossip options

local ClickGossip = GossipTitleButton_OnClick
function GossipTitleButton_OnClick(self, button, down)
	local gossipText = self:GetText()
	--Addon:Debug("Clicking gossip", self:GetID(), gossipText)
	if dismountForGossip[gossipText] then
		--Addon:Debug("Dismounting")
		Dismount()
	end
	ClickGossip(self, button, down)
end
