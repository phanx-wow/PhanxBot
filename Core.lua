--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
	Copyright (c) 2008-2013 Phanx. All rights reserved.
	See the accompanying LICENSE file for more information.
----------------------------------------------------------------------]]

local PHANXBOT, PhanxBotNS = ...

local db
local summonPending

local L = setmetatable({}, { __index = function(t, k) t[k] = k return k end })
PhanxBotNS.L = L

------------------------------------------------------------------------

local PhanxBot = CreateFrame("Frame", "PhanxBox")
PhanxBot:SetScript("OnEvent", function(self, event, ...) return self[event](self, event, ...) end)
PhanxBot:RegisterEvent("ADDON_LOADED")
PhanxBotNS.core = PhanxBot

------------------------------------------------------------------------

function PhanxBot:Debug(message, ...)
	if ... and strmatch(message, "%%[dfqsx%d%.]") then
		print("|cffff3333PhanxBot:|r ", format(message, ...))
	else
		print("|cffff3333PhanxBot:|r ", message, ...)
	end
end

function PhanxBot:Print(message, ...)
	if ... and strmatch(message, "%%[dfqsx%d%.]") then
		print("|cffffcc00PhanxBot:|r ", format(message, ...))
	else
		print("|cffffcc00PhanxBot:|r ", message, ...)
	end
end

------------------------------------------------------------------------

function PhanxBot:ADDON_LOADED(event, addon)
	if addon ~= "PhanxBot" then return end

	self.defaults = {
		acceptGroups = true,			-- Accept group invitations from friends
		acceptResurrections = false,	-- Accept resurrections out of combat
		acceptResurrectionstInCombat = false,	-- Accept resurrections in combat
		acceptSummons = false,			-- Accept warlock and meeting stone summons
		summonDelay = 45,				-- Wait this many seconds to accept summons

		confirmDisenchant = false,		-- Confirm disenchant rolls
		confirmGreed = false,			-- Confirm greed rolls
		confirmNeed = false,			-- Confirm need rolls

		declineArenaTeams = false,		-- Decline arena team invitations
		declineDuels = false,			-- Decline duel requests

		lootBoP = false,				-- Loot bind-on-pickup items while ungrouped
		lootBoPInGroup = false,			-- Loot bind-on-pickup items in groups

		repair = true,					-- Repair equipment at vendors
		repairFromGuild = false,		-- Use guild funds to repair

		sellJunk = true,				-- Sell junk items at vendors

		skipGossip = true,				-- Skip gossips if there's only one option

		filterTrainers = true,			-- Hide unavailable skills at trainers
		showNameplatesInCombat = false,	-- Toggle nameplates on while in combat
	}

	PhanxBotDB = PhanxBotDB or { }
	db = PhanxBotDB

	for k, v in pairs(self.defaults) do
		if type(db[k]) ~= type(v) then
			db[k] = v
		end
	end

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then
		self:PLAYER_LOGIN()
	else
		self:RegisterEvent("PLAYER_LOGIN")
	end
end

------------------------------------------------------------------------

function PhanxBot:PLAYER_LOGIN()
	if db.acceptGroups then
		UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
		self:RegisterEvent("PARTY_INVITE_REQUEST")
	else
		UIParent:RegisterEvent("PARTY_INVITE_REQUEST")
	end

	if db.acceptResurrections then
		self:RegisterEvent("RESURRECT_REQUEST")
	end

	if db.acceptSummons then
		self:RegisterEvent("CONFIRM_SUMMON")
	end

	if db.confirmDisenchant then
		self:RegisterEvent("CONFIRM_DISENCHANT_ROLL")
	end

	if db.confirmGreed or db.confirmNeed then
		self:RegisterEvent("CONFIRM_LOOT_ROLL")
	end

	if db.declineArenaTeams then
		self:RegisterEvent("ARENA_TEAM_INVITE_REQUEST")
		self:RegisterEvent("PETITION_SHOW")
	end

	if db.declineDuels then
		self:RegisterEvent("DUEL_REQUESTED")
	end

	if GetAutoDeclineGuildInvites() == 1 then
		self:RegisterEvent("PETITION_SHOW")
	end

	if db.lootBoP then
		self:RegisterEvent("LOOT_BIND_CONFIRM")
	end

	if db.repair or db.sellJunk then
		self:RegisterEvent("MERCHANT_SHOW")
	end

	if db.skipGossip then
		self:RegisterEvent("GOSSIP_SHOW")
	end

	if db.showNameplatesInCombat then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	if db.filterTrainers then
		self:RegisterEvent("TRAINER_SHOW")
	end
end

------------------------------------------------------------------------

local function IsFriend(name)
	if UnitIsInMyGuild(name) then
		return true
	end

	for i = 1, GetNumFriends() do
		if GetFriendInfo(i) == name then
			return true
		end
	end

	for i = 1, select(2, BNGetNumFriends()) do
		for j = 1, BNGetNumFriendToons(i) do
			local _, toonName, client, realm = BNGetFriendToonInfo(i, j)
			if toonName == name and client == "WoW" and realm == GetRealmName() then
				return true
			end
		end
	end
end

------------------------------------------------------------------------
--	Accept group invitations from friends

function PhanxBot:PARTY_INVITE_REQUEST(event, sender)
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

function PhanxBot:RESURRECT_REQUEST(event, sender)
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
			PhanxBot:AcceptSummon()
		end
	end)

	function PhanxBot:StartSummonDelayTimer()
		counter = 0
		summonTimer:Show()
	end

	function PhanxBot:StopSummonDelayTimer()
		summonTimer:Hide()
	end

	function PhanxBot:CancelSummon()
		self:StopSummonDelayTimer()

		if not db.showNameplatesInCombat then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
		self:UnregisterEvent("PLAYER_DEAD")

		summonTime = -1
		summonPending = false
	end

	function PhanxBot:AcceptSummon()
		if GetTime() - summonTime < 120 then
			ConfirmSummon()
			StaticPopup_Hide("CONFIRM_SUMMON")
		else
			self:Print("Summon expired!")
		end
		self:CancelSummon()
	end

	function PhanxBot:CONFIRM_SUMMON(event)
		self:Debug(event)
		self:Print("Accepting summon in %d seconds...", db.summonDelay)

		summonTime = GetTime()
		summonPending = true

		self:StartSummonDelayTimer()

		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
		self:RegisterEvent("PLAYER_DEAD")
	end

	function PhanxBot:PLAYER_DEAD()
		self:CancelSummon()
	end
end

------------------------------------------------------------------------
--	Confirm rolls

function PhanxBot:CONFIRM_DISENCHANT_ROLL(event, id, rollType)
	--self:Debug(event, id, rollType)
	ConfirmLootRoll(id, rollType)
	StaticPopup_Hide("CONFIRM_LOOT_ROLL")
end

function PhanxBot:CONFIRM_LOOT_ROLL(event, id, rollType)
	--self:Debug(event, id, rollType)
	if (rollType == 1 and db.confirmNeed) or (rollType == 2 and db.confirmGreed) then
		ConfirmLootRoll(id, rollType)
		StaticPopup_Hide("CONFIRM_LOOT_ROLL")
	end
end

------------------------------------------------------------------------
--	Decline arena team invitations

function PhanxBot:ARENA_TEAM_INVITE_REQUEST(event, sender)
	--self:Debug(event, sender)
	DeclineArenaTeam()
end

------------------------------------------------------------------------
--	Decline arena team petitions and guild petitions

function PhanxBot:PETITION_SHOW(event)
	local petitionType, _, _, _, sender, isSender = GetPetitionInfo()
	--self:Debug(event, petitionType, sender, isSender)
	if not isSender and ((petitionType == "arena" and db.declineArenaTeams) or (petitionType == "guild" and db.declineGuilds)) then
		ClosePetition()
	end
end

------------------------------------------------------------------------
--	Decline duel requests

local duelCount = {}

function PhanxBot:DUEL_REQUESTED(event, sender)
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

	function PhanxBot:LOOT_BIND_CONFIRM(event, slot)
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

local hooked, junks, profit

local tooltip = CreateFrame("GameTooltip", "PhanxBotTooltip", nil, "GameTooltipTemplate")
local function UpdateProfit(frame, money)
	if frame == tooltip and MerchantFrame:IsShown() then
		junks = junks + 1
		profit = profit + money
	end
end

local function FormatMoney(value)
	value = abs(tonumber(value))
	if value > 10000 then
		local g = floor(abs(value / 10000))
		local s = floor(abs(mod(value / 100, 100)))
		local c = abs(mod(value, 100))
		if c > 0 then
			return "|cffffffff"..g.."|r|cffffd700g|r |cffffffff"..s.."|r|cffc7c7cfs|r |cffffffff"..c.."|r|cffeda55fc|r"
		elseif s > 0 then
			return "|cffffffff"..g.."|r|cffffd700g|r |cffffffff"..s.."|r"
		else
			return "|cffffffff"..g.."|r|cffffd700g|r"
		end
	elseif value > 100 then
		local s = floor(abs(mod(value / 100, 100)))
		local c = abs(mod(value, 100))
		if c > 0 then
			return "|cffffffff"..s.."|r|cffc7c7cfs|r |cffffffff"..c.."|r|cffeda55fc|r"
		else
			return "|cffffffff"..s.."|r|cffc7c7cfs|r"
		end
	else
		return "|cffffffff"..value.."|r|cffeda55fc|r"
	end
end

function PhanxBot:MERCHANT_SHOW(event)
	--self:Debug(event)
	local shift = IsShiftKeyDown()

	if db.sellJunk and not shift then
		if not hooked then
			hooksecurefunc("SetTooltipMoney", UpdateProfit)
			hooked = true
		end
		junks, profit = 0, 0
		for bag = 0, 4 do
			for slot = 0, GetContainerNumSlots(bag) do
				local link = GetContainerItemLink(bag, slot)
				if link then
					local _, _, q = GetItemInfo(link)
					if q == 0 then
						tooltip:SetBagItem(bag, slot)
						UseContainerItem(bag, slot)
					end
				end
			end
		end
		if profit > 0 then
			self:Print("Sold %d junk items for %s.", junks, FormatMoney(profit))
		end
	end

	if db.repair and CanMerchantRepair() then
		local repairAllCost, canRepair = GetRepairAllCost()
		if canRepair and repairAllCost > 0 then
			if db.repairFromGuild and CanGuildBankRepair() and not shift then
				local amount = GetGuildBankWithdrawMoney()
				local guildBankMoney = GetGuildBankMoney()
				if amount == -1 then
					amount = guildBankMoney
				else
					amount = min(amount, guildBankMoney)
				end
				if amount > repairAllCost then
					RepairAllItems(1)
					self:Print("Repaired all items for %s from guild bank funds.", FormatMoney(repairAllCost))
					return
				else
					self:Print("Insufficient guild bank funds to repair! Hold Shift to repair anyway.")
				end
			elseif GetMoney() > repairAllCost then
				RepairAllItems()
				self:Print("Repaired all items for %s.", FormatMoney(repairAllCost))
				return
			else
				self:Print("Insufficient funds to repair!")
			end
		end
	end
end

------------------------------------------------------------------------
--	Skip gossips when there's only one option

local gossipSeen = {}

function PhanxBot:GOSSIP_SHOW(event)
	--self:Debug(event)
	if IsShiftKeyDown() then return end

	local _, instance = GetInstanceInfo()
	if GetNumGossipAvailableQuests() == 0 and GetNumGossipActiveQuests() == 0 and GetNumGossipOptions() == 1 and instance ~= "raid" then
		local text, type = GetGossipOptions()
		if type == "gossip" and (not gossipSeen[text] or GetTime() - gossipSeen[text] > 0.5) then
			gossipSeen[text] = GetTime()
			SelectGossipOption(1)
		end
	end
end

------------------------------------------------------------------------
--	Toggle nameplates on while in combat

function PhanxBot:PLAYER_REGEN_DISABLED(event)
	--self:Debug(event)
	if db.showNameplatesInCombat then
		SetCVar("nameplateShowEnemies", 1)
	end
	if summonPending then
		self:StopSummonDelayTimer()
	end
end

function PhanxBot:PLAYER_REGEN_ENABLED(event)
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

function PhanxBot:TRAINER_SHOW(event)
	--self:Debug(event)
	SetTrainerServiceTypeFilter("unavailable", 0)
	SetTrainerServiceTypeFilter("used", 0)
end