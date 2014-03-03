--[[--------------------------------------------------------------------
	PhanxBot
	Reduces interface tedium by doing stuff for you.
	Copyright (c) 2008-2014 Phanx. All rights reserved.
	See the accompanying LICENSE file for more information.
----------------------------------------------------------------------]]

local L, ADDON, Addon = {}, ...
local LOCALE = GetLocale()

------------------------------------------------------------------------

if LOCALE == "deDE" then

	L["Accept groups"] = "Gruppen annehmen"
	L["Accept group inviations from friends and guildmates."] = "Gruppeneinladungen von Freunde und Gildenmitglieder automatisch annehmen."
	L["Accept resurrections"] = "Wiederbelebungen annehmen"
	L["Accept resurrections out of combat."] = "Wiederbelebungen außerhalb des Kampfes automatisch annehmen."
	L["...in combat"] = "...im Kampf"
	L["Also accept resurrections in combat."] = "Wiederbelebungen im Kampf auch automatisch annehmen."
	L["Accept summons"] = "Beschwörungen annehmen"
	L["Accept summons from meeting stones and warlocks."] = "Beschwörungen von Hexenmeister und Versammlungssteine automatisch annehmen."
	L["Delay"] = "Wartezeit"
	L["Wait this many seconds before accepting summons."] = "Festlegen, wie viele Sekunden vor der Annahme der Beschwörung zu warten."
	L["Confirm disenchant rolls"] = "Entzauberungswürfe bestätigen"
	L["Confirm greed rolls"] = "Würfe für Gier bestätigen"
	L["Confirm need rolls"] = "Würfe für Bedarf bestätigen"
	L["Decline arena teams"] = "Arenateams ablehnen"
	L["Decline invitations and petitions for arena teams."] = "Alle Arenateam-Einladungen und -Satzungen automatisch ablehnen."
	L["Decline duels"] = "Duelle ablehnen"
	L["Decline duel requests."] = "Alle Duellherausforderungen automatisch ablehnen."
	L["Decline guilds"] = "Gilden ablehnen"
	L["Decline invitations and petitions for guilds."] = "Alle Gildenanfragen und -Satzungen automatisch ablehnen."
	L["Loot BoP items"] = "BoP-Gegenstände plündern"
	L["Loot bind-on-pickup items without confirmation while solo."] = "Alle BoP-Gegendstände ohne Bestätigung automatisch plündern, wenn Ihr in keiner Gruppe seid."
	L["...in groups"] = "...in Gruppen"
	L["Also loot bind-on-pickup items without confirmation while in a group."] = "Auch BoP-Gegendstände ohne Bestätigung plündern, wenn Ihr in eine Gruppe seid."
	L["Repair equipment"] = "Gegenstände reparieren"
	L["Repair all equipment when interacting with a repair vendor."] = "Alle Gegenstände auf Interaktion mit einem Händler automatisch reparieren."
	L["...with guild bank money"] = "...bei Gildengeld"
	L["Repair with money from the guild bank when available."] = "Bei Gildengeld repaieren, wenn möglich."
	L["Sell junk"] = "Müll verkaufen"
	L["Sell gray-quality items when interacting with a vendor."] = "Alle grauen Gegenstände auf die Interaktion mit einem Händler verkaufen."
	L["Skip gossip"] = "Tratsch übergehen"
	L["Skip NPC gossip options if there's only one choice."] = "NPC-Tratsch übergehen, wenn es nur eine Option gibt."
	L["Filter trainers"] = "Lehrer filtern"
	L["Hide unavailable and already known skills at trainers by default."] = "Nicht verfügbar oder bereits bekannt Fertigkeiten bei Lehrer standardmäßig ausblenden."
	L["Show nameplates in combat"] = "Plaketten im Kampf einblenden"
	L["Toggle enemy nameplates on when entering combat, and off when leaving combat."] = "Plaketten für Gegner einblenden am Anfang des Kampfes und ausblenden am Ende des Kampfes."

------------------------------------------------------------------------

elseif LOCALE == "xxXX" then

	--L["Accept groups"] = ""
	--L["Accept group inviations from friends and guildmates."] = ""
	--L["Accept resurrections"] = ""
	--L["Accept resurrections out of combat."] = ""
	--L["...in combat"] = ""
	--L["Also accept resurrections in combat."] = ""
	--L["Accept summons"] = ""
	--L["Accept summons from meeting stones and warlocks."] = ""
	--L["Delay"] = ""
	--L["Wait this many seconds before accepting summons."] = ""
	--L["Confirm disenchant rolls"] = ""
	--L["Confirm greed rolls"] = ""
	--L["Confirm need rolls"] = ""
	--L["Decline arena teams"] = ""
	--L["Decline invitations and petitions for arena teams."] = ""
	--L["Decline duels"] = ""
	--L["Decline duel requests."] = ""
	--L["Decline guilds"] = ""
	--L["Decline invitations and petitions for guilds."] = ""
	--L["Loot BoP items"] = ""
	--L["Loot bind-on-pickup items without confirmation while solo."] = ""
	--L["...in groups"] = ""
	--L["Also loot bind-on-pickup items without confirmation while in a group."] = ""
	--L["Repair equipment"] = ""
	--L["Repair all equipment when interacting with a repair vendor."] = ""
	--L["...with guild bank money"] = ""
	--L["Repair with money from the guild bank when available."] = ""
	--L["Sell junk"] = ""
	--L["Sell gray-quality items when interacting with a vendor."] = ""
	--L["Skip gossip"] = ""
	--L["Skip NPC gossip options if there's only one choice."] = ""
	--L["Filter trainers"] = ""
	--L["Hide unavailable and already known skills at trainers by default."] = ""
	--L["Show nameplates in combat"] = ""
	--L["Toggle enemy nameplates on when entering combat, and off when leaving combat."] = ""

------------------------------------------------------------------------
end

Addon.L = setmetatable(L, { __index = function(t, k)
	local v = tostring(k)
	t[k] = v
	return v end
})