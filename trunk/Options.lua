--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
	Copyright (c) 2008-2012 Phanx. All rights reserved.
	See the accompanying LICENSE file for more information.
----------------------------------------------------------------------]]

local PHANXBOT, PhanxBotNS = ...

local optionsPanel = LibStub("PhanxConfig-OptionsPanel").CreateOptionsPanel(PHANXBOT, nil, function(self)
	local L = PhanxBotNS.L
	local db = PhanxBotDB

	local PhanxBot = PhanxBotNS.core
	PhanxBot.optionsPanel = self

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

	local options = {
		{
			key = "acceptGroups",
			name = L["Accept groups"],
			desc = L["Accept group inviations from friends and guildmates."],
		},
		{
			key = "acceptResurrections",
			name = L["Accept resurrections"],
			desc = L["Accept resurrections out of combat."],
		},
		{
			key = "acceptResurrectionsInCombat",
			name = L["...in combat"],
			desc = L["Also accept resurrections in combat."],
			parent = "acceptResurrections",
		},
		{
			key = "acceptSummons",
			name = L["Accept summons"],
			desc = L["Accept summons from meeting stones and warlocks."],
		},
		{
			key = "summonDelay",
			name = L["Delay"],
			desc = L["Wait this many seconds before accepting summons."],
			type = "range", min = 0, max = 60, step = 5,
			parent = "acceptSummons",
		},
		{
			key = "confirmDisenchant",
			name = L["Confirm disenchant rolls"],
		},
		{
			key = "confirmGreed",
			name = L["Confirm greed rolls"],
		},
		{
			key = "confirmNeed",
			name = L["Confirm need rolls"],
		},
		{
			key = "declineArenaTeams",
			name = L["Decline arena teams"],
			desc = L["Decline invitations and petitions for arena teams."],
		},
		{
			key = "declineDuels",
			name = L["Decline duels"],
			desc = L["Decline duel requests."],
		},
		{
			key = "declineGuilds",
			name = L["Decline guilds"],
			desc = L["Decline invitations and petitions for guilds."],
			get = function() return GetAutoDeclineGuildInvites() == 1 end,
			set = function(value) SetAutoDeclineGuildInvites(value and 1 or 0) end,
		},
		{
			key = "lootBoP",
			name = L["Loot BoP items"],
			desc = L["Loot bind-on-pickup items without confirmation while solo."],
		},
		{
			key = "lootBoPInGroup",
			name = L["...in groups"],
			desc = L["Also loot bind-on-pickup items without confirmation while in a group."],
			parent = "lootBoP",
		},
		{
			key = "repair",
			name = L["Repair equipment"],
			desc = L["Repair all equipment when interacting with a repair vendor."],
		},
		{
			key = "repairFromGuild",
			name = L["...with guild bank money"],
			desc = L["Repair with money from the guild bank when available."],
			parent = "repair",
		},
		{
			key = "sellJunk",
			name = L["Sell junk"],
			desc = L["Sell gray-quality items when interacting with a vendor."],
		},
		{
			key = "skipGossip",
			name = L["Skip gossip"],
			desc = L["Skip NPC gossip options if there's only one choice."],
		},
		{
			key = "filterTrainers",
			name = L["Filter trainers"],
			desc = L["Hide unavailable and already known skills at trainers by default."],
		},
		{
			key = "showNameplatesInCombat",
			name = L["Show nameplates in combat"],
			desc = L["Toggle enemy nameplates on when entering combat, and off when leaving combat."],
		},
	}
	self.options = options

	local function SetOption(self, value)
		if self.option.key then
			db[self.option.key] = value
		elseif self.option.set then
			self.option.set(value)
		end
		PhanxBot:UnregisterAllEvents()
		PhanxBot:PLAYER_LOGIN()
	end

	for i = 1, #options do
		local option = options[i]

		local widget
		if not option.type then
			widget = self:CreateCheckbox(option.name)
			widget.desc = option.desc
			widget.OnClick = SetOption
		elseif option.type == "range" then
			widget = self:CreateSlider(option.name, option.min, option.max, option.step, option.percent)
			widget.desc = option.desc
			widget.OnValueChanged = SetOption
		end
		widget.option = option
		option.widget = widget

		local y = -8
		if i > 1 and options[i-1].type == "range" then
			y = -16
		end
		if i == 1 then
			widget:SetPoint("TOPLEFT", notes, "BOTTOMLEFT", 0, y)
		elseif i == 12 then
			widget:SetPoint("TOPLEFT", notes, "BOTTOM", 8, y)
		elseif option.parent == options[i-1].key then
			widget:SetPoint("TOPLEFT", options[i-1].widget, "BOTTOMLEFT", 20, y)
		elseif options[i-1].parent and not option.parent then
			widget:SetPoint("TOPLEFT", options[i-1].widget, "BOTTOMLEFT", -20, y)
		else
			widget:SetPoint("TOPLEFT", options[i-1].widget, "BOTTOMLEFT", 0, y)
		end
	end

	self.refresh = function()
		for i = 1, #options do
			local option = options[i]

			local value
			if options[i].get then
				value = options[i].get()
			else
				value = db[options[i].key]
			end

			local widget = options[i].widget
			if widget.SetValue then
				widget:SetValue(value)
			elseif widget.SetChecked then
				widget:SetChecked(value)
			end
		end
	end
end)

SLASH_PHANXBOT1 = "/bot"
SLASH_PHANXBOT2 = "/pbot"
SlashCmdList.PHANXBOT = function()
	InterfaceOptionsFrame_OpenToCategory(optionsPanel)
end