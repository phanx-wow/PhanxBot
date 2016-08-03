--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
	Copyright (c) 2008-2016 Phanx <addons@phanx.net>. All rights reserved.
----------------------------------------------------------------------]]

local ADDON, Addon = ...
local L = Addon.L

local summonPending

------------------------------------------------------------------------

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
		end--[[
		local _, numBNFriends = BNGetNumFriends()
		for i = 1, numBNFriends do
			for j = 1, BNGetNumFriendToons(i) do
				local _, toonName, client, realm = BNGetFriendToonInfo(i, j)
				if toonName == name and client == "WoW" and realm == myRealm then
					return true
				end
			end
		end]]
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
		acceptGroups = true,                  -- Accept group invitations from friends
		acceptResurrections = false,          -- Accept resurrections out of combat
		acceptResurrectionstInCombat = false, -- Accept resurrections in combat
		acceptSummons = false,                -- Accept warlock and meeting stone summons
		summonDelay = 45,                     -- Wait this many seconds to accept summons
		automateQuests = true,                -- Accept and turn in quests
		confirmDisenchant = false,            -- Confirm disenchant rolls
		confirmGreed = false,                 -- Confirm greed rolls
		confirmNeed = false,                  -- Confirm need rolls
		declineDuels = false,                 -- Decline duel requests
		lootBoP = false,                      -- Loot bind-on-pickup items while ungrouped
		lootBoPInGroup = false,               -- Loot bind-on-pickup items in groups
		repair = true,                        -- Repair equipment at vendors
		repairFromGuild = false,              -- Use guild funds to repair
		sellJunk = true,                      -- Sell junk items at vendors
		skipGossip = true,                    -- Skip gossips if there's only one option
		filterTrainers = true,                -- Hide unavailable skills at trainers
		showNameplatesInCombat = false,       -- Toggle nameplates on while in combat
	}

	self.db = PhanxBotDB or {}
	PhanxBotDB = self.db
	for k, v in pairs(self.defaults) do
		if type(self.db[k]) ~= type(v) then
			self.db[k] = v
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
	if self.db.acceptGroups then
		UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
		self.Events:RegisterEvent("PARTY_INVITE_REQUEST")
	else
		UIParent:RegisterEvent("PARTY_INVITE_REQUEST")
	end

	if self.db.acceptResurrections then
		self.Events:RegisterEvent("RESURRECT_REQUEST")
	end

	if self.db.acceptSummons then
		self.Events:RegisterEvent("CONFIRM_SUMMON")
	end

	if self.db.automateQuests then
		Addon.LocalizeQuestNames()
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

	if self.db.confirmDisenchant then
		self.Events:RegisterEvent("CONFIRM_DISENCHANT_ROLL")
	end

	if self.db.confirmGreed or self.db.confirmNeed then
		self.Events:RegisterEvent("CONFIRM_LOOT_ROLL")
	end

	if self.db.declineDuels then
		self.Events:RegisterEvent("DUEL_REQUESTED")
	end

	if GetAutoDeclineGuildInvites() == 1 then
		self.Events:RegisterEvent("PETITION_SHOW")
	end

	if self.db.lootBoP then
		self.Events:RegisterEvent("LOOT_BIND_CONFIRM")
	end

	if self.db.repair or self.db.sellJunk then
		self.Events:RegisterEvent("MERCHANT_SHOW")
	end

	if self.db.skipGossip or self.db.automateQuests then
		self.Events:RegisterEvent("GOSSIP_SHOW")
	end
	if self.db.skipGossip then
		self.Events:RegisterEvent("GOSSIP_CONFIRM")
	end

	if self.db.showNameplatesInCombat then
		self.Events:RegisterEvent("PLAYER_REGEN_DISABLED")
		self.Events:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	if self.db.filterTrainers then
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
--	Accept resurrections

function Addon:RESURRECT_REQUEST(event, sender)
	if HydraSettings and HydraSettings.Automation.acceptResurrections then return end
	--self:Debug(event, sender)
	local _, class = UnitClass(sender)
	if class == "DRUID" and UnitAffectingCombat(sender) and not self.db.acceptResurrectionsInCombat then
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
		if counter > self.db.summonDelay then
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

		if not self.db.showNameplatesInCombat then
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
		if HydraSettings and HydraSettings.Quest.acceptSummons then return end
		--self:Debug(event)
		self:Print("Accepting summon in %d seconds...", self.db.summonDelay)

		summonTime = GetTime()
		summonPending = true

		self:StartSummonDelayTimer()

		self.Events:RegisterEvent("PLAYER_REGEN_DISABLED")
		self.Events:RegisterEvent("PLAYER_REGEN_ENABLED")
		self.Events:RegisterEvent("PLAYER_DEAD")
	end

	function Addon:PLAYER_DEAD()
		if HydraSettings and HydraSettings.Quest.acceptSummons then return end
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
	if (rollType == 1 and self.db.confirmNeed) or (rollType == 2 and self.db.confirmGreed) then
		ConfirmLootRoll(id, rollType)
		StaticPopup_Hide("CONFIRM_LOOT_ROLL")
	end
end

------------------------------------------------------------------------
--	Decline guild petitions
--	TODO: is this covered by the built-in "decline guild invites" option?

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
	if HydraSettings and HydraSettings.Automation.declineDuels then return end
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
		if not loot[slot] and ((group and self.db.lootBoPInGroup) or (not group and self.db.lootBoP)) then
			loot[slot] = true
			delayedLooter:Show()
			StaticPopup_Hide("LOOT_BIND")
		end
	end
end

------------------------------------------------------------------------
--	Repair equipment and sell junk items at vendors

function Addon:MERCHANT_SHOW(event)
	if HydraSettings and HydraSettings.Automation.sellJunk then return end
	--self:Debug(event)
	if IsShiftKeyDown() then return end

	if self.db.sellJunk then
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

	if self.db.repair and CanMerchantRepair() then
		local repairAllCost, canRepair = GetRepairAllCost()
		if canRepair and repairAllCost > 0 then
			if self.db.repairFromGuild and CanGuildBankRepair() then
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
--	Toggle nameplates on while in combat

function Addon:PLAYER_REGEN_DISABLED(event)
	--self:Debug(event)
	if self.db.showNameplatesInCombat then
		SetCVar("nameplateShowAll", 1)
		SetCVar("nameplateShowEnemies", 1)
	end
	if summonPending then
		self:StopSummonDelayTimer()
	end
end

function Addon:PLAYER_REGEN_ENABLED(event)
	--self:Debug(event)
	if self.db.showNameplatesInCombat then
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
