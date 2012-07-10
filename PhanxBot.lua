--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
----------------------------------------------------------------------]]

local db
local summonPending
local summonTime = -1

local L = setmetatable({ }, { __index = function(t, k) t[k] = k return k end })

local function echo(message, ...)
	if ... then
		message = message:format(...)
	end
	print("|cffffcc00PhanxBot:|r " .. message)
end

local function debug(message, ...)
	if ... then
		message = message:format(...)
	end
	print("|cffff3333PhanxBot:|r " .. message)
end

------------------------------------------------------------------------

PhanxBot = CreateFrame("Frame")
PhanxBot:SetScript("OnEvent", function(self, event, ...) return self[event] and self[event](self, ...) end)
PhanxBot:RegisterEvent("ADDON_LOADED")

------------------------------------------------------------------------

function PhanxBot:ADDON_LOADED(addon)
	if addon ~= "PhanxBot" then return end

	self.defaults = {
		arena = false,				-- Decline arena team invitations
		duel = false,				-- Decline duel requests
		group = true,				-- Accept group invitations from friends
		guild = false,				-- Decline guild invitations
		loot = false,				-- Loot bind-on-pickup items while ungrouped
		nameplates = false,			-- Toggle nameplates on while in combat
		repair = true,				-- Repair equipment at vendors
		repairFromGuild = false,	-- Use guild funds to repair
		resurrect = false,			-- Accept non-combat resurrections
		resurrectInCombat = false,	-- Also accept combat resurrections
		sell = true,				-- Sell junk items at vendors
		summon = false,				-- Accept warlock and meeting stone summons
		summonDelay = 45,			-- Wait this many seconds to accept summons
		trainer = true,				-- Hide unavailable skills at trainers
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
	if db.arena then
		self:RegisterEvent("ARENA_TEAM_INVITE_REQUEST")
		self:RegisterEvent("PETITION_SHOW")
	end

	if db.duel then
		self:RegisterEvent("DUEL_REQUESTED")
	end

	if db.group then
		UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
		self:RegisterEvent("PARTY_INVITE_REQUEST")
	end

	if db.guild then
		self:RegisterEvent("PETITION_SHOW")
	end

	if db.nameplates then
		self:RegisterEvent("PLAYER_REGEN_DISABLED")
		self:RegisterEvent("PLAYER_REGEN_ENABLED")
	end

	if db.repair or db.sell then
		self:RegisterEvent("MERCHANT_SHOW")
	end

	if db.resurrect then
		self:RegisterEvent("RESURRECT_REQUEST")
	end

	if db.summon then
		self:RegisterEvent("CONFIRM_SUMMON")
	end

	if db.train then
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
--	Decline arena team and guild creation petitions

function PhanxBot:PETITION_SHOW()
	local type, _, _, _, sender, isMine = GetPetitionInfo()
	-- debug("PETITION_SHOW from " .. sender)

	if not isMine and db[type] then
		ClosePetition()
	end
end

------------------------------------------------------------------------
--	Decline arena team invitations

function PhanxBot:ARENA_TEAM_INVITE_REQUEST(sender)
	-- debug("ARENA_TEAM_INVITE_REQUEST from " .. sender)

	DeclineArenaTeam()
end

------------------------------------------------------------------------
--	Decline duel requests

function PhanxBot:DUEL_REQUESTED(sender)
	-- debug("DUEL_REQUESTED from " .. sender)

	CancelDuel()
	StaticPopup_Hide("DUEL_REQUESTED")
end

------------------------------------------------------------------------
--	Accept group invitations from friends

function PhanxBot:PARTY_INVITE_REQUEST(sender)
	-- debug("PARTY_INVITE_REQUEST from " .. sender)
	if IsFriend(sender) then
		AcceptGroup()
	else
		SendWho("n-\"" .. sender .. "\"")
		UIParent:GetScript("OnEvent")(UIParent, "PARTY_INVITE_REQUEST", sender)
	end
end

------------------------------------------------------------------------
--	Loot bind-on-pickup items while ungrouped

function PhanxBot:LOOT_BIND_CONFIRM(slot)
	-- debug("LOOT_BIND_CONFIRM for slot " .. slot)

	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
		ConfirmLootSlot(slot)
		StaticPopup_Hide("LOOT_BIND")
	end
end

------------------------------------------------------------------------
--	Toggle nameplates on while in combat

function PhanxBot:PLAYER_REGEN_DISABLED()
	-- debug("PLAYER_REGEN_DISABLED")

	if db.nameplates then
		SetCVar("nameplateShowEnemies", 1)
	end

	if summonPending then
		self:StopSummonDelayTimer()
	end
end

function PhanxBot:PLAYER_REGEN_ENABLED()
	-- debug("PLAYER_REGEN_ENABLED")

	if db.nameplates then
		SetCVar("nameplateShowEnemies", 0)
	end

	if summonPending then
		self:StartSummonDelayTimer()
	end
end

------------------------------------------------------------------------
--	Repair equipment and sell junk items at vendors

local hooked
local profit = 0
local tooltip = CreateFrame("GameTooltip", "PhanxBotTooltip", nil, "GameTooltipTemplate")
local function UpdateProfit(frame, money)
	if frame == tooltip and MerchantFrame:IsShown() then
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

function PhanxBot:MERCHANT_SHOW()
	-- debug("MERCHANT_SHOW")
	if IsShiftKeyDown() then return end

	if db.sell then
		if not hooked then
			hooksecurefunc("SetTooltipMoney", UpdateProfit)
			hooked = true
		end
		profit = 0
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
			echo("Sold all junk for %s.", FormatMoney(profit))
		end
	end

	if db.repair and CanMerchantRepair() then
		local cost = GetRepairAllCost()
		if cost > 0 then
			local money = GetMoney()
			local guildmoney = GetGuildBankWithdrawMoney()
			if guildmoney == -1 then
				guildmoney = GetGuildBankMoney()
			end

			if db.repairFromGuild and guildmoney >= cost and IsInGuild() then
				RepairAllItems(1)
				echo("Repaired all items for %s from guild bank funds.", FormatMoney(cost))
			elseif db.repairFromGuild and IsInGuild() then
				echo("Insufficient guild bank funds to repair! Hold Shift to repair anyway.")
			elseif money > cost then
				RepairAllItems()
				echo("Repaired all items for %s.", FormatMoney(cost))
			else
				echo("Insufficient funds to repair!")
			end
		end
	end
end

------------------------------------------------------------------------
--	Accept resurrections

function PhanxBot:RESURRECT_REQUEST(sender)
	-- debug("RESURRECT_REQUEST from " .. sender)

	local _, class = UnitClass(sender)
	if class and class == "DRUID" and UnitAffectingCombat(sender) and not db.resurrectInCombat then
		return
	end

	AcceptResurrect()
	StaticPopup_Hide("RESURRECT_NO_SICKNESS")
end

------------------------------------------------------------------------
--	Accept summons

local counter = 0
function PhanxBot:CountdownSummonDelay(elapsed)
	counter = counter + elapsed
	if counter > db.summonDelay then
		self:AcceptSummon()
	end
end

function PhanxBot:StartSummonDelayTimer()
	counter = 0
	self:SetScript("OnUpdate", self.CountdownSummonDelay)
end

function PhanxBot:StopSummonDelayTimer()
	self:SetScript("OnUpdate", nil)
end

function PhanxBot:AcceptSummon()
	if GetTime() - summonTime < 120 then
		ConfirmSummon()
		StaticPopupHide("CONFIRM_SUMMON")
	else
		self:Print("Summon expired!")
	end

	self:CancelSummon()
end

function PhanxBot:CancelSummon()
	self:StopSummonDelayTimer()

	if not db.nameplates then
		self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
	self:UnregisterEvent("PLAYER_DEAD")

	summonTime = -1
	summonPending = false
end

function PhanxBot:CONFIRM_SUMMON()
	self:Print("Accepting summon in %d seconds...", SUMMON_DELAY)

	summonTime = GetTime()
	summonPending = true

	self:StartSummonCountdown()

	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_DEAD")
end

function PhanxBot:PLAYER_DEAD()
	self:CancelSummon()
end

------------------------------------------------------------------------
--	Hide unavailable skills at trainers

function PhanxBot:TRAINER_SHOW()
	SetTrainerServiceTypeFilter("unavailable", 0)
	SetTrainerServiceTypeFilter("used", 0)
end

------------------------------------------------------------------------

PhanxBot.optionsPanel = CreateFrame("Frame", nil, InterfaceOptionsFramePanelContainer)
PhanxBot.optionsPanel.name = "PhanxBot"
PhanxBot.optionsPanel:SetScript("OnShow", function(self)
	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetPoint("TOPRIGHT", -16, -16)
	title:SetJustifyH("LEFT")
	title:SetText(self.name)

	local notes = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	notes:SetHeight(32)
	notes:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	notes:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -9)
	notes:SetNonSpaceWrap(true)
	notes:SetJustifyH("LEFT")
	notes:SetJustifyV("TOP")
	notes:SetText(L["Use this panel to hide selected parts of the default UI."])

	self.CreateCheckbox = LibStub("PhanxConfig-Checkbox").CreateCheckbox
	self.CreateSlider = LibStub("PhanxConfig-Slider").CreateSlider

	local arena, duel, group, guild, loot, nameplates, repair, repairFromGuild, resurrect, resurrectInCombat, sell, summon, summonDelay, trainer

	duel = self:CreateCheckbox(L["Decline duels"])
	duel.desc = L["Decline duel requests"]
	duel:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 0, -8)
	duel:SetChecked(db.duel)
	duel.OnClick = function(self, checked)
		if checked then
			db.duel = true
			self:RegisterEvent("DUEL_REQUESTED")
		else
			db.duel = false
			self:UnregisterEvent("DUEL_REQUESTED")
		end
	end

	arena = self:CreateCheckbox(L["Decline arena teams"])
	arena.desc = L["Decline arena team invitations and petitions"]
	arena:SetPoint("TOPLEFT", duel, "BOTTOMLEFT", 0, -8)
	arena:SetChecked(db.arena)
	arena.OnClick = function(self, checked)
		if checked then
			db.arena = true
			self:RegisterEvent("ARENA_TEAM_INVITE_REQUEST")
			self:RegisterEvent("PETITION_SHOW")
		else
			db.arena = false
			self:UnregisterEvent("ARENA_TEAM_INVITE_REQUEST")
			if not db.guild then
				self:UnregisterEvent("PETITION_SHOW")
			end
		end
	end

	guild = self:CreateCheckbox(L["Decline guilds"])
	guild.desc = L["Decline guild invitations and petitions"]
	guild:SetPoint("TOPLEFT", arena, "BOTTOMLEFT", 0, -8)
	guild:SetChecked(GetAutoDeclineGuildInvites() == 1)
	guild.OnClick = function(self, checked)
		if checked then
			SetAutoDeclineGuildInvites(1)
			self:RegisterEvent("PETITION_SHOW")
		else
			GetAutoDeclineGuildInvites(0)
			if not db.arena then
				self:UnregisterEvent("PETITION_SHOW")
			end
		end
	end

	group = self:CreateCheckbox(L["Accept groups"])
	group.desc = L["Accept group invitations from friends and guildmates"]
	group:SetPoint("TOPLEFT", guild, "BOTTOMLEFT", 0, -8)
	group:SetChecked(db.group)
	group.OnClick = function(self, checked)
		if checked then
			db.group = true
			UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
			self:RegisterEvent("PARTY_INVITE_REQUEST")
		else
			db.group = false
			UIParent:RegisterEvent("PARTY_INVITE_REQUEST")
			self:UnregisterEvent("PARTY_INVITE_REQUEST")
		end
	end

	resurrect = self:CreateCheckbox(L["Accept resurrections"])
	resurrect.desc = L["Accept out-of-combat resurrections"]
	resurrect:SetPoint("TOPLEFT", group, "BOTTOMLEFT", 0, -8)
	resurrect:SetChecked(db.resurrect)
	resurrect.OnClick = function(self, checked)
		if checked then
			db.resurrect = true
			self:RegisterEvent("RESURRECT_REQUEST")
		else
			db.resurrect = false
			self:UnregisterEvent("RESURRECT_REQUEST")
		end
	end

	resurrectInCombat = self:CreateCheckbox(L["Combat resurrections"])
	resurrectInCombat.desc = L["Accept in-combat resurrections too"]
	resurrectInCombat:SetPoint("TOPLEFT", resurrect, "BOTTOMLEFT", 16, -8)
	resurrectInCombat:SetChecked(db.resurrectInCombat)
	resurrectInCombat.OnClick = function(self, checked)
		if checked then
			db.resurrectInCombat = true
		else
			db.resurrectInCombat = false
		end
	end

	summon = self:CreateCheckbox(L["Accept summons"])
	summon.desc = L["Accept summons from warlocks and meeting stones"]
	summon:SetPoint("TOPLEFT", resurrectInCombat, "BOTTOMLEFT", -16, -8)
	summon:SetChecked(db.summon)
	summon.OnClick = function(self, checked)
		if checked then
			db.summon = true
			self:RegisterEvent("CONFIRM_SUMMON")
		else
			db.summon = false
			self:UnregisterEvent("CONFIRM_SUMMON")
		end
	end

	summonDelay = self:CreateSlider(L["Summon delay"], 0, 60, 5)
	summonDelay.desc = L["Wait this many seconds before accepting summons"]
	summonDelay:SetPoint("TOPLEFT", summon, "BOTTOMLEFT", 16, -8)
	summonDelay:SetValue(db.summonDelay)
	summonDelay.OnValueChanged = function(self, value)
		db.summonDelay = math.floor(value + 0.5)
		return db.summonDelay
	end

	repair = self:CreateCheckbox(L["Repair equipment"])
	repair.desc = L["Repair all equipment when interacting with a vendor"]
	repair:SetPoint("TOPLEFT", notes, "BOTTOM", 8, -8)
	repair:SetChecked(db.repair)
	repair.OnClick = function(self, checked)
		if checked then
			db.repair = true
			self:RegisterEvent("MERCHANT_SHOW")
		else
			db.repair = false
			if not db.sell then
				self:UnregisterEvent("MERCHANT_SHOW")
			end
		end
	end

	repairFromGuild = self:CreateCheckbox(L["Use guild funds"])
	repairFromGuild.desc = L["Use guild funds to repair when available"]
	repairFromGuild:SetPoint("TOPLEFT", repair, "BOTTOMLEFT", 16, -8)
	repairFromGuild:SetChecked(db.repairFromGuild)
	repairFromGuild.OnClick = function(self, checked)
		if checked then
			db.repairFromGuild = true
		else
			db.repairFromGuild = false
		end
	end

	sell = self:CreateCheckbox(L["Sell junk"])
	sell.desc = L["Sell junk items when interacting with a vendor"]
	sell:SetPoint("TOPLEFT", repairFromGuild, "BOTTOMLEFT", -16, -8)
	sell:SetChecked(db.sell)
	sell.OnClick = function(self, checked)
		if checked then
			db.sell = true
			self:RegisterEvent("MERCHANT_SHOW")
		else
			db.sell = false
			if not db.repair then
				self:UnregisterEvent("MERCHANT_SHOW")
			end
		end
	end

	loot = self:CreateCheckbox(L["Loot BoP while solo"])
	loot.desc = L["Loot bind-on-pickup items without confirmation while not in a group"]
	loot:SetPoint("TOPLEFT", sell, "BOTTOMLEFT", 0, -8 - sell:GetHeight() - 8)
	loot:SetChecked(db.loot)
	loot.OnClick = function(self, checked)
		if checked then
			db.loot = true
			self:RegisterEvent("LOOT_BIND_CONFIRM")
		else
			db.summon = false
			self:UnregisterEvent("LOOT_BIND_CONFIRM")
		end
	end

	nameplates = self:CreateCheckbox(L["Toggle nameplates"])
	nameplates.desc = L["Show nameplates while in combat, and hide them while out of combat"]
	nameplates:SetPoint("TOPLEFT", loot, "BOTTOMLEFT", 0, -8)
	nameplates:SetChecked(db.nameplates)
	nameplates.OnClick = function(self, checked)
		if checked then
			db.nameplates = true
			self:RegisterEvent("PLAYER_REGEN_DISABLED")
			self:RegisterEvent("PLAYER_REGEN_ENABLED")
		else
			db.nameplates = false
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
			self:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
	end

	trainer = self:CreateCheckbox(L["Filter trainers"])
	trainer.desc = L["Hide unavailable skills by default when interacting with trainers"]
	trainer:SetPoint("TOPLEFT", nameplates, "BOTTOMLEFT", 0, -8)
	trainer:SetChecked(db.trainer)
	trainer.OnClick = function(self, checked)
		if checked then
			db.trainer = true
			self:RegisterEvent("TRAINER_SHOW")
		else
			db.trainer = false
			self:UnregisterEvent("TRAINER_SHOW")
		end
	end

	self:SetScript("OnShow", nil)
end)

InterfaceOptions_AddCategory(PhanxBot.optionsPanel)

SLASH_PHANXBOT1 = "/bot"
SLASH_PHANXBOT2 = "/pbot"
SlashCmdList.PHANXBOT = function() InterfaceOptionsFrame_OpenToCategory(PhanxBot.optionsPanel) end

------------------------------------------------------------------------