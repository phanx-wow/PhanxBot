--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
	Copyright (c) 2008-2015 Phanx <addons@phanx.net>. All rights reserved.
----------------------------------------------------------------------]]

local ADDON, Addon = ...
local L = Addon.L

local db
local questChoicePending, questChoiceFinished
local summonPending

local ignoreGossip = {
	-- Klaxxi
	[L["Grant me your assistance, Bloodseeker. [Klaxxi Augmentation]"]] = true,
	[L["Grant me your assistance, Dissector. [Klaxxi Enhancement]"]] = true,
	[L["Grant me your assistance, Iyyokuk. [Klaxxi Enhancement]"]] = true,
	[L["Grant me your assistance, Locust. [Klaxxi Augmentation]"]] = true,
	[L["Grant me your assistance, Malik. [Klaxxi Enhancement]"]] = true,
	[L["Grant me your assistance, Manipulator. [Klaxxi Augmentation]"]] = true,
	[L["Grant me your assistance, Prime. [Klaxxi Augmentation]"]] = true,
	[L["Grant me your assistance, Wind-Reaver. [Klaxxi Enhancement]"]] = true,
	[L["Please fly me to the Terrace of Gurthan"]] = true,
	-- Tillers
	[L["What kind of gifts do you like?"]] = true,
}

local dismountForGossip = {
	-- Pandaria
	[L["I am ready to go."]] = true, -- CHECK ENGLISH -- Jade Forest, Fei, "Es geht voran"
	[L["Please fly me to the Terrace of Gurthan"]] = true,
	[L["Send me to Dawn's Blossom."]] = true, -- CHECK ENGLISH
	-- Northrend
	[L["I am ready to fly to Sholazar Basin."]] = true, -- CHECK ENGLISH
	[L["I need a bat to intercept the Alliance reinforcements."]] = true, -- CHECK ENGLISH
	-- Outland
	[L["Absolutely!  Send me to the Skyguard Outpost."]] = true,
	[L["I'm on a bombing mission for Forward Command To'arch.  I need a wyvern destroyer!"]] = true,
	[L["Lend me a Windrider.  I'm going to Spinebreaker Post!"]] = true,
	[L["Send me to the Abyssal Shelf!"]] = true,
	[L["Send me to Thrallmar!"]] = true,
	[L["Yes, I'd love a ride to Blackwind Landing."]] = true,
	[20235] = true, -- Schick mich zum Ehrenposten! @ Greifnerin Heulwind
	[19409] = true, -- Schick mich zum Trümmerposten. @ Schwadronskommandant Dabir'ee
	[20236] = true, -- Schick mich zum Trümmerposten. @ Greifner Laubbart
	-- Isle of Quel'Danas
	[L["I need to intercept the Dawnblade reinforcements."]] = true,
	[L["Speaking of action, I've been ordered to undertake an air strike."]] = true,
}

local selectMultiGossip = {
	[57850] = 1, -- Teleportologist Fozlebub, "Teleport me to the cannon."
}

local confirmGossipNPC = {
	[54334] = true, -- Darkmoon Faire Mystic Mage (Alliance)
	[55382] = true, -- Darkmoon Faire Mystic Mage (Horde)
	[57850] = true, -- Teleportologist Fozlebub
}

local ignoreGossipNPC = {
	-- Bodyguards
	[86945] = true, -- Aeda Brightdawn (Horde)
	[86927] = true, -- Delvar Ironfist (Alliance)
	[86934] = true, -- Defender Illona (Alliance)
	[86964] = true, -- Leorajh
	[86946] = true, -- Talonpriest Ishaal
	[86682] = true, -- Tormmok
	[86933] = true, -- Vivianne (Horde)
	-- Misc NPCs
	[79953] = true, -- Lieutenant Thorn (Alliance)
	[79740] = true, -- Warmaster Zog (Horde)
}

local ignoreQuest = {
	-- Manual
	[32296] = true, -- Treasures of the Thunder King
	-- Suboptimal rewards: Blue Feather, Jade Cat, Lovely Apple, Marsh Lily, Ruby Shard
	[30382] = true, [30419] = true, [30425] = true, [30388] = true, [30412] = true, [30437] = true, [30406] = true, [30431] = true,
	[30399] = true, [30418] = true, [30387] = true, [30411] = true, [30436] = true, [30393] = true, [30405] = true, [30430] = true,
	[30398] = true, [30189] = true, [30417] = true, [30423] = true, [30380] = true, [30410] = true, [30392] = true, [30429] = true,
	[30401] = true, [30383] = true, [30426] = true, [30413] = true, [30438] = true, [30395] = true, [30407] = true, [30432] = true,
	[30397] = true, [30160] = true, [30416] = true, [30422] = true, [30379] = true, [30434] = true, [30391] = true, [30403] = true,
	-- Mutually exclusive: Work Order
	[32642] = true, [32647] = true, [32645] = true, [32649] = true, [32653] = true, [32658] = true,
	-- Mutually exclusive: Fiona's Caravan
	[27560] = true, [27562] = true, [27555] = true, [27556] = true, [27558] = true, [27561] = true, [27557] = true, [27559] = true,
	-- Mutually exclusive: Allegiance to the Aldor/Scryers
	[10551] = true, [10552] = true,
	-- Mutually exclusive: Little Orphan Kekek/Roo of the Wolvar/Oracles
	[13927] = true, [13926] = true,
	-- No reward: Return to the Abyssal Shelf (Alliance/Horde)
	[10346] = true, [10347] = true,
	-- Stuck on 5-minute flight: To Venomspite!
	[12182] = true,
	-- Profession specializations: Elixir/Potion/Transmutation Master, Goblin/Gnomish Engineering
	[29481] = true, [29067] = true, [29482] = true,
	[29475] = true, [29477] = true,
}

local ignoreQuestNPC = {
	[88570] = true, -- Fate-Twister Tiklal
	[87391] = true, -- Fate-Twister Seress
}

local repeatableQuestComplete = {
	-- {{ DRAENOR
	[35147] = {118099,20}, -- Fragments of the Past -> 20 Gorian Artifact Fragment
	[37125] = 118100, -- A Rare Find -> Highmaul Relic
	[37210] = 118654, -- Aogexon's Fang
	[37211] = 118655, -- Bergruu's Horn
	[37221] = 118656, -- Dekorhan's Tusk
	[37222] = 118657, -- Direhoof's Hide
	[37223] = 118658, -- Gagrog's Skull
	[37224] = 118659, -- Mu'gra's Head
	[37225] = 118660, -- Thek'talon's Talon
	[37226] = 118661, -- Xelganak's Stinger
	[37520] = 120172, -- Vileclaw's Claw
	-- }}
	-- {{ PANDARIA
	[31535] = 87557, -- Replenishing the Pantry -> Bundle of Groceries
	[31603] = {87903,6}, -- Seeds of Fear -> 6 Dread Amber Shards
	-- }}
}

local cashRewards = {
	[45724] = 100000,  --  10g: Champion's Purse
	[64491] = 2000000, -- 200g: Royal Reward
}

local function GetNPCID()
	return tonumber(strmatch(UnitGUID("npc") or "", "Creature%-.-%-.-%-.-%-.-%-(.-)%-"))
end

local GetQuestName
do
	local tooltip
	function GetQuestName(id)
		if not tooltip then
			tooltip = CreateFrame("GameTooltip")
			tooltip.titleText = tooltip:CreateFontString(nil, "OVERLAY", "GameTooltipHeaderText")
			tooltip:AddFontStrings(tooltip.titleText, tooltip:CreateFontString(nil, "OVERLAY", "GameTooltipHeaderText"))
		end
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		tooltip:SetHyperlink("quest:" .. id)
		local name = tooltip.titleText:GetText()
		GameTooltip:Hide()
		return name
	end
end

local PopulateQuestNames
do
	local complete
	local toPopulate = {
		ignoreQuest,
		repeatableQuestComplete,
	}
	function PopulateQuestNames()
		if complete then return end
		complete = true
		for i = 1, #toPopulate do
			local t = toPopulate[i]
			for id, v in pairs(t) do
				if type(id) == "number" then
					local name = GetQuestName(id)
					if name then
						t[name] = v
						t[id] = nil
					else
						complete = false
					end
				end
			end
		end
	end
end

local function IsTrackingTrivial()
	for i = 1, GetNumTrackingTypes() do
		local name, _, active = GetTrackingInfo(i)
		if name == MINIMAP_TRACKING_TRIVIAL_QUESTS then
			return active
		end
	end
end

local IsFriend
do
	local myRealm = GetRealmName()
	 function IsFriend(name)
		if UnitIsInMyGuild(name) then
			return true
		end
		for i = 1, GetNumFriends() do
			if GetFriendInfo(i) == name then
				return true
			end
		end
		local _, numBNFriends = BNGetNumFriends()
		for i = 1, numBNFriends do
			for j = 1, BNGetNumFriendToons(i) do
				local _, toonName, client, realm = BNGetFriendToonInfo(i, j)
				if toonName == name and client == "WoW" and realm == myRealm then
					return true
				end
			end
		end
	end
end

------------------------------------------------------------------------

local Events = CreateFrame("Frame", ADDON)
Events:RegisterEvent("ADDON_LOADED")
Events:SetScript("OnEvent", function(self, event, ...) return Addon[event](Addon, event, ...) end)
Addon.Events = Events

------------------------------------------------------------------------

function Addon:Debug(message, ...)
	if (...) and strmatch(message, "%%[$dfqsx%d%.]") then
		print("|cffff3333PhanxBot:|r", format(message, ...))
	else
		print("|cffff3333PhanxBot:|r", message, ...)
	end
end

function Addon:Print(message, ...)
	if (...) and strmatch(message, "%%[$dfqsx%d%.]") then
		print("|cffffcc00PhanxBot:|r", format(message, ...))
	else
		print("|cffffcc00PhanxBot:|r", message, ...)
	end
end

------------------------------------------------------------------------

function Addon:ADDON_LOADED(event, addon)
	if addon ~= ADDON then return end

	self.defaults = {
		acceptGroups = true,					-- Accept group invitations from friends
		acceptResurrections = false,		-- Accept resurrections out of combat
		acceptResurrectionstInCombat = false,	-- Accept resurrections in combat
		acceptSummons = false,				-- Accept warlock and meeting stone summons
		summonDelay = 45,						-- Wait this many seconds to accept summons
		automateQuests = true,				-- Accept and turn in quests
		confirmDisenchant = false,			-- Confirm disenchant rolls
		confirmGreed = false,				-- Confirm greed rolls
		confirmNeed = false,					-- Confirm need rolls
		declineDuels = false,				-- Decline duel requests
		lootBoP = false,						-- Loot bind-on-pickup items while ungrouped
		lootBoPInGroup = false,				-- Loot bind-on-pickup items in groups
		repair = true,							-- Repair equipment at vendors
		repairFromGuild = false,			-- Use guild funds to repair
		sellJunk = true,						-- Sell junk items at vendors
		skipGossip = true,					-- Skip gossips if there's only one option
		filterTrainers = true,				-- Hide unavailable skills at trainers
		showNameplatesInCombat = false,	-- Toggle nameplates on while in combat
	}

	db = PhanxBotDB or {}
	PhanxBotDB = db
	for k, v in pairs(self.defaults) do
		if type(db[k]) ~= type(v) then
			db[k] = v
		end
	end

	self.Events:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then
		self:PLAYER_LOGIN()
	else
		self.Events:RegisterEvent("PLAYER_LOGIN")
	end
end

------------------------------------------------------------------------

function Addon:PLAYER_LOGIN()
	if db.acceptGroups then
		UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
		self.Events:RegisterEvent("PARTY_INVITE_REQUEST")
	else
		UIParent:RegisterEvent("PARTY_INVITE_REQUEST")
	end

	if db.acceptResurrections then
		self.Events:RegisterEvent("RESURRECT_REQUEST")
	end

	if db.acceptSummons then
		self.Events:RegisterEvent("CONFIRM_SUMMON")
	end

	if db.automateQuests then
		PopulateQuestNames()
		self.Events:RegisterEvent("QUEST_GREETING")
		self.Events:RegisterEvent("QUEST_DETAIL")
		self.Events:RegisterEvent("QUEST_ACCEPT_CONFIRM")
		self.Events:RegisterEvent("QUEST_ACCEPTED")
		self.Events:RegisterEvent("QUEST_PROGRESS")
		self.Events:RegisterEvent("QUEST_ITEM_UPDATE")
		self.Events:RegisterEvent("QUEST_COMPLETE")
		self.Events:RegisterEvent("QUEST_FINISHED")
		self.Events:RegisterEvent("QUEST_AUTOCOMPLETE")
	end

	if db.confirmDisenchant then
		self.Events:RegisterEvent("CONFIRM_DISENCHANT_ROLL")
	end

	if db.confirmGreed or db.confirmNeed then
		self.Events:RegisterEvent("CONFIRM_LOOT_ROLL")
	end

	if db.declineDuels then
		self.Events:RegisterEvent("DUEL_REQUESTED")
	end

	if GetAutoDeclineGuildInvites() == 1 then
		self.Events:RegisterEvent("PETITION_SHOW")
	end

	if db.lootBoP then
		self.Events:RegisterEvent("LOOT_BIND_CONFIRM")
	end

	if db.repair or db.sellJunk then
		self.Events:RegisterEvent("MERCHANT_SHOW")
	end

	if db.skipGossip or db.automateQuests then
		self.Events:RegisterEvent("GOSSIP_SHOW")
	end
	if db.skipGossip then
		self.Events:RegisterEvent("GOSSIP_CONFIRM")
	end

	if db.showNameplatesInCombat then
		self.Events:RegisterEvent("PLAYER_REGEN_DISABLED")
		self.Events:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	if db.filterTrainers then
		self.Events:RegisterEvent("TRAINER_SHOW")
	end
end

------------------------------------------------------------------------
--	Accept group invitations from friends

function Addon:PARTY_INVITE_REQUEST(event, sender)
	--self:Debug(event, sender)
	if IsFriend(sender) then
		AcceptGroup()
	else
		SendWho("n-\"" .. sender .. "\"")
		UIParent_OnEvent(UIParent, event, sender)
	end
end

------------------------------------------------------------------------
-- Accept and turn in quests

local function StripText(text)
	if not text then return "" end
	text = gsub(text, "%[.*%]%s*","")
	text = gsub(text, "|c%x%x%x%x%x%x%x%x(.+)|r","%1")
	text = gsub(text, "(.+) %(.+%)", "%1")
	return strtrim(text)
end

function Addon:QUEST_GREETING()
	if HydraSettings then return end
	--self:Debug("QUEST_GREETING")
	if ignoreQuestNPC[GetNPCID()] or IsShiftKeyDown() then return end
	-- Turn in complete quests:
	for i = 1, GetNumActiveQuests() do
		local title, complete = GetActiveTitle(i)
		--self:Debug("Checking active quest:", title)
		if complete and not ignoreQuest[StripText(title)] then
			--self:Debug("Select!")
			SelectActiveQuest(i)
		end
	end
	-- Pick up available quests:
	for i = 1, GetNumAvailableQuests() do
		local title = StripText(GetAvailableTitle(i))
		--self:Debug("Checking available quest:", title)
		if not ignoreQuest[title] and (not IsAvailableQuestTrivial(i) or IsTrackingTrivial()) then
			--self:Debug("Select!")
			SelectAvailableQuest(i)
		end
	end
end

function Addon:QUEST_DETAIL()
	if HydraSettings then return end
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
	if HydraSettings then return end
	--self:Debug("QUEST_ACCEPT_CONFIRM", giver, quest)
	if IsShiftKeyDown() then return end
	AcceptQuest()
	--ConfirmAcceptQuest()
	--StaticPopup_Hide("QUEST_ACCEPT")
end

function Addon:QUEST_ACCEPTED(event, id)
	if HydraSettings then return end
	--self:Debug("QUEST_ACCEPTED", id)
	if QuestFrame:IsShown() and QuestGetAutoAccept() then
		CloseQuest()
	end
	if not GetCVarBool("autoQuestWatch") or IsQuestWatched(id) or GetNumQuestWatches() >= MAX_WATCHABLE_QUESTS then return end
	--self:Debug("Adding quest to tracker")
	AddQuestWatch(id)
end

function Addon:QUEST_PROGRESS()
	if HydraSettings then return end
	--self:Debug("QUEST_PROGRESS")
	if IsShiftKeyDown() or not IsQuestCompletable() then return end
	--self:Debug("Completing quest", StripText(GetTitleText()))
	CompleteQuest()
end

function Addon:QUEST_ITEM_UPDATE()
	if HydraSettings then return end
	--self:Debug("QUEST_ITEM_UPDATE", questChoicePending)
	if questChoicePending then
		self:QUEST_COMPLETE("QUEST_ITEM_UPDATE")
	end
end

function Addon:QUEST_COMPLETE()
	if HydraSettings then return end
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
				value = cashRewards[tonumber(strmatch(link, "item:(%d+)"))] or value or 0
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
	if HydraSettings then return end
	--self:Debug("QUEST_FINISHED")
	if questChoiceFinished then
		questChoicePending = false
	end
end

function Addon:QUEST_AUTOCOMPLETE(event, id)
	if HydraSettings then return end
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
--	Accept resurrections

function Addon:RESURRECT_REQUEST(event, sender)
	if HydraSettings then return end
	--self:Debug(event, sender)
	local _, class = UnitClass(sender)
	if class == "DRUID" and UnitAffectingCombat(sender) and not db.acceptResurrectionsInCombat then
		return
	end
	AcceptResurrect()
	StaticPopup_Hide("RESURRECT_NO_SICKNESS")
end

------------------------------------------------------------------------
--	Accept summons

do
	local summonTime = -1
	local counter = 0

	local summonTimer = CreateFrame("Frame")
	summonTimer:Hide()
	summonTimer:SetScript("OnUpdate", function(self, elapsed)
		counter = counter + elapsed
		if counter > db.summonDelay then
			Addon:AcceptSummon()
		end
	end)

	function Addon:StartSummonDelayTimer()
		counter = 0
		summonTimer:Show()
	end

	function Addon:StopSummonDelayTimer()
		summonTimer:Hide()
	end

	function Addon:CancelSummon()
		self:StopSummonDelayTimer()

		if not db.showNameplatesInCombat then
			self.Events:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self.Events:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
		self.Events:UnregisterEvent("PLAYER_DEAD")

		summonTime = -1
		summonPending = false
	end

	function Addon:AcceptSummon()
		if GetTime() - summonTime < 120 then
			ConfirmSummon()
			StaticPopup_Hide("CONFIRM_SUMMON")
		else
			self:Print("Summon expired!")
		end
		self:CancelSummon()
	end

	function Addon:CONFIRM_SUMMON(event)
		if HydraSettings then return end
		--self:Debug(event)
		self:Print("Accepting summon in %d seconds...", db.summonDelay)

		summonTime = GetTime()
		summonPending = true

		self:StartSummonDelayTimer()

		self.Events:RegisterEvent("PLAYER_REGEN_DISABLED")
		self.Events:RegisterEvent("PLAYER_REGEN_ENABLED")
		self.Events:RegisterEvent("PLAYER_DEAD")
	end

	function Addon:PLAYER_DEAD()
		if HydraSettings then return end
		--self:Debug(event)
		self:CancelSummon()
	end
end

------------------------------------------------------------------------
--	Confirm rolls

function Addon:CONFIRM_DISENCHANT_ROLL(event, id, rollType)
	--self:Debug(event, id, rollType)
	ConfirmLootRoll(id, rollType)
	StaticPopup_Hide("CONFIRM_LOOT_ROLL")
end

function Addon:CONFIRM_LOOT_ROLL(event, id, rollType)
	--self:Debug(event, id, rollType)
	if (rollType == 1 and db.confirmNeed) or (rollType == 2 and db.confirmGreed) then
		ConfirmLootRoll(id, rollType)
		StaticPopup_Hide("CONFIRM_LOOT_ROLL")
	end
end

------------------------------------------------------------------------
--	Decline guild petitions
-- TODO: is this covered by the built-in "decline guild invites" option?

function Addon:PETITION_SHOW(event)
	local petitionType, _, _, _, sender, isSender = GetPetitionInfo()
	--self:Debug(event, petitionType, sender, isSender)
	if not isSender and petitionType == "guild" and GetAutoDeclineGuildInvites() == 1 then
		ClosePetition()
	end
end

------------------------------------------------------------------------
--	Decline duel requests

local duelCount = {}

function Addon:DUEL_REQUESTED(event, sender)
	if HydraSettings then return end
	duelCount[sender] = (duelCount[sender] or 0) + 1
	--self:Debug(event, sender, duelCount)
	CancelDuel()
	StaticPopup_Hide("DUEL_REQUESTED")
end

------------------------------------------------------------------------
--	Loot bind-on-pickup items

do
	local loot = {}

	local delayedLooter = CreateFrame("Frame")
	delayedLooter:Hide()
	delayedLooter:SetScript("OnUpdate", function(self, elapsed)
		for slot in pairs(loot) do
			LootSlot(slot)
			ConfirmLootSlot(slot)
			loot[slot] = nil
		end
	end)

	function Addon:LOOT_BIND_CONFIRM(event, slot)
		--self:Debug(event, slot, GetLootSlotLink(slot))
		local group = IsInGroup()
		if not loot[slot] and ((group and db.lootBoPInGroup) or (not group and db.lootBoP)) then
			loot[slot] = true
			delayedLooter:Show()
			StaticPopup_Hide("LOOT_BIND")
		end
	end
end

------------------------------------------------------------------------
--	Repair equipment and sell junk items at vendors

function Addon:MERCHANT_SHOW(event)
	if HydraSettings then return end
	--self:Debug(event)
	if IsShiftKeyDown() then return end

	if db.sellJunk then
		local junks, profit = 0, 0
		for bag = 0, 4 do
			for slot = 0, GetContainerNumSlots(bag) do
				local _, quantity, locked, _, _, _, link = GetContainerItemInfo(bag, slot)
				if link and not locked then
					local _, _, quality, _, _, _, _, _, _, _, value = GetItemInfo(link)
					if quality == LE_ITEM_QUALITY_POOR then
						junks = junks + 1
						profit = profit + value
						UseContainerItem(bag, slot)
					end
				end
			end
		end
		if profit > 0 then
			self:Print("Sold %d junk items for %s.", junks, GetCoinTextureString(profit))
		end
	end

	if db.repair and CanMerchantRepair() then
		local repairAllCost, canRepair = GetRepairAllCost()
		if canRepair and repairAllCost > 0 then
			if db.repairFromGuild and CanGuildBankRepair() then
				local amount = GetGuildBankWithdrawMoney()
				local guildBankMoney = GetGuildBankMoney()
				if amount == -1 then
					amount = guildBankMoney
				else
					amount = min(amount, guildBankMoney)
				end
				if amount > repairAllCost then
					RepairAllItems(1)
					self:Print("Repaired all items for %s from guild bank funds.", GetCoinTextureString(repairAllCost))
					return
				else
					self:Print("Insufficient guild bank funds to repair!")
				end
			elseif GetMoney() > repairAllCost then
				RepairAllItems()
				self:Print("Repaired all items for %s.", GetCoinTextureString(repairAllCost))
				return
			else
				self:Print("Insufficient funds to repair!")
			end
		end
	end
end

------------------------------------------------------------------------
-- Skip gossips when there's only one option
-- Select quest gossips for pickup and turnin

local gossipLastSeen = {}

function Addon:GOSSIP_SHOW(event)
	--self:Debug(event)
	if IsShiftKeyDown() then return end

	if db.automateQuests and not HydraSettings then
		-- Turn in complete quests:
		for i = 1, GetNumGossipActiveQuests() do
			local title, level, isLowLevel, isComplete, isLegendary = select(i * 5 - 4, GetGossipActiveQuests())
			if isComplete and not ignoreQuest[title] then
				--self:Debug("Turn in:", title)
				return SelectGossipActiveQuest(i)
			end
		end
		-- Pick up available quests:
		for i = 1, GetNumGossipAvailableQuests() do
			local title, level, isLowLevel, isDaily, isRepeatable, isLegendary = select(i * 6 - 5, GetGossipAvailableQuests())
			--self:Debug(i, '"'..title..'"', isLowLevel, isRepeatable)
			if not ignoreQuest[title] then
				local go
				local req = isRepeatable and repeatableQuestComplete[title]
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
	
	if not db.skipGossip then return end

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
	--self:Debug("Clicking gossip", self:GetID(), gossipText)
	if dismountForGossip[gossipText] then
		--self:Debug("Dismounting")
		Dismount()
	end
	ClickGossip(self, button, down)
end

------------------------------------------------------------------------
--	Toggle nameplates on while in combat

function Addon:PLAYER_REGEN_DISABLED(event)
	--self:Debug(event)
	if db.showNameplatesInCombat then
		SetCVar("nameplateShowEnemies", 1)
	end
	if summonPending then
		self:StopSummonDelayTimer()
	end
end

function Addon:PLAYER_REGEN_ENABLED(event)
	--self:Debug(event)
	if db.showNameplatesInCombat then
		SetCVar("nameplateShowEnemies", 0)
	end
	if summonPending then
		self:StartSummonDelayTimer()
	end
end

------------------------------------------------------------------------
--	Hide unavailable skills at trainers

function Addon:TRAINER_SHOW(event)
	--self:Debug(event)
	SetTrainerServiceTypeFilter("unavailable", 0)
	SetTrainerServiceTypeFilter("used", 0)
end