--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
	Copyright 2008-2018 Phanx <addons@phanx.net>
	All rights reserved. Permission is granted to reuse code from
	this addon in other projects, as long as my name is not used.
----------------------------------------------------------------------]]

local ADDON, Addon = ...
local LOCALE = GetLocale()

local L = {}
Addon.L = setmetatable(L, { __index = function(t, k)
	local v = tostring(k)
	t[k] = v
	return v end
})

------------------------------------------------------------------------

if LOCALE == "deDE" then
	L["Accept groups"] = "Gruppen annehmen"
	L["Accept group inviations from friends and guildmates."] = "Gruppeneinladungen von Freunde und Gildenmitglieder automatisch annehmen."
	L["Accept resurrections"] = "Wiederbelebungen annehmen"
	L["Accept resurrections out of combat."] = "Wiederbelebungen außerhalb des Kampfes automatisch annehmen."
	L["...in combat"] = "...auch im Kampf"
	L["Also accept resurrections in combat."] = "Wiederbelebungen auch im Kampf automatisch annehmen."
	L["Accept summons"] = "Beschwörungen annehmen"
	L["Accept summons from meeting stones and warlocks."] = "Beschwörungen von Hexenmeister und Versammlungssteine automatisch annehmen."
	L["Automate quests"] = "Quests automatisieren"
	L["Automatically accept and turn in quests."] = "Quests automatisch annehmen und abschließen."
	L["Delay"] = "Wartezeit"
	L["Wait this many seconds before accepting summons."] = "Festlegen, wie viele Sekunden vor der Annahme der Beschwörung zu warten."
	L["Confirm disenchant rolls"] = "Entzauberungswürfe bestätigen"
	L["Confirm greed rolls"] = "Würfe für Gier bestätigen"
	L["Confirm need rolls"] = "Würfe für Bedarf bestätigen"
	L["Decline duels"] = "Duelle ablehnen"
	L["Decline duel requests."] = "Alle Duellherausforderungen automatisch ablehnen."
	L["Decline guilds"] = "Gilden ablehnen"
	L["Decline invitations and petitions for guilds."] = "Alle Gildenanfragen und -Satzungen automatisch ablehnen."
	L["Loot BoP items"] = "BoP-Gegenstände plündern"
	L["Loot bind-on-pickup items without confirmation while solo."] = "Alle BoP-Gegendstände ohne Bestätigung automatisch plündern, wenn Ihr in keiner Gruppe seid."
	L["...in groups"] = "...in Gruppen"
	L["Also loot bind-on-pickup items without confirmation while in a group."] = "Auch BoP-Gegendstände ohne Bestätigung plündern, wenn Ihr in eine Gruppe seid."
	L["Repair equipment"] = "Gegenstände reparieren"
	L["Repair all equipment when interacting with a repair vendor."] = "Alle Gegenstände bei Interaktion mit einem Händler automatisch reparieren."
	L["...with guild bank money"] = "...bei Gildengeld"
	L["Repair with money from the guild bank when available."] = "Bei Gildengeld repaieren, wenn möglich."
	L["Sell junk"] = "Müll verkaufen"
	L["Sell gray-quality items when interacting with a vendor."] = "Alle grauen Gegenstände bei Interaktion mit einem Händler verkaufen."
	L["Skip gossip"] = "Tratsch übergehen"
	L["Skip NPC gossip options if there's only one choice."] = "NPC-Tratsch übergehen, wenn es nur eine Option gibt."
	L["Filter trainers"] = "Lehrer filtern"
	L["Hide unavailable and already known skills at trainers by default."] = "Nicht verfügbare und bereits bekannte Fertigkeiten bei Lehrer standardmäßig ausblenden."
	L["Show nameplates in combat"] = "Plaketten im Kampf einblenden"
	L["Toggle enemy nameplates on when entering combat, and off when leaving combat."] = "Gegnerplaketten am Anfang des Kampfes einblenden, und am Ende des Kampfes ausblenden."
return end
