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
-- Klaxxi
	--L["Grant me your assistance, Bloodseeker. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Dissector. [Klaxxi Enhancement]"] = ""
	--L["Grant me your assistance, Iyyokuk. [Klaxxi Enhancement]"] = ""
	--L["Grant me your assistance, Locust. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Malik. [Klaxxi Enhancement]"] = ""
	--L["Grant me your assistance, Manipulator. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Prime. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Wind-Reaver. [Klaxxi Enhancement]"] = ""
	--L["Please fly me to the Terrace of Gurthan"] = ""
-- Tillers
	--L["What kind of gifts do you like?"] = ""
-- Pandaria
	L["I am ready to go."] = "Ich bin bereit zu gehen."
	--L["Please fly me to the Terrace of Gurthan"] = ""
	L["Send me to Dawn's Blossom."] = "Schickt mich nach Morgenblüte."
-- Northrend
	L["I need a bat to intercept the Alliance reinforcements."] = "Ich brauche eine Reitfledermaus, um die Verstärkung der Allianz abzufangen."
	L["I am ready to fly to Sholazar Basin."] = "Ich bin bereit, ins Sholazarbecken zu fliegen."
-- Outland
	--L["Absolutely!  Send me to the Skyguard Outpost."] = ""
	L["I'm on a bombing mission for Forward Command To'arch.  I need a wyvern destroyer!"] = "Ich habe einen Bomberauftrag von Vorpostenkommandant To'arch. Ich brauche einen Wyverzerstörer!"
	L["Lend me a Windrider.  I'm going to Spinebreaker Post!"] = "Gebt mir ein Windreiter. Ich werde zum Rückenbrecherposten fliegen!"
	L["Send me to the Abyssal Shelf!"] = "Schickt mich zur abyssischen Untiefe!"
	L["Send me to Thrallmar!"] = "Schickt mich nach Thrallmar!"
	--L["Yes, I'd love a ride to Blackwind Landing."] = ""
-- Isle of Quel'Danas
	--L["I need to intercept the Dawnblade reinforcements."] = ""
	--L["Speaking of action, I've been ordered to undertake an air strike."] = ""

-- UI
	L["Accept groups"] = "Gruppen annehmen"
	L["Accept group inviations from friends and guildmates."] = "Gruppeneinladungen von Freunde und Gildenmitglieder automatisch annehmen."
	L["Accept resurrections"] = "Wiederbelebungen annehmen"
	L["Accept resurrections out of combat."] = "Wiederbelebungen außerhalb des Kampfes automatisch annehmen."
	L["...in combat"] = "...auch im Kampf"
	L["Also accept resurrections in combat."] = "Wiederbelebungen auch im Kampf automatisch annehmen."
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
-- Klaxxi
	--L["Grant me your assistance, Bloodseeker. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Dissector. [Klaxxi Enhancement]"] = ""
	--L["Grant me your assistance, Iyyokuk. [Klaxxi Enhancement]"] = ""
	--L["Grant me your assistance, Locust. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Malik. [Klaxxi Enhancement]"] = ""
	--L["Grant me your assistance, Manipulator. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Prime. [Klaxxi Augmentation]"] = ""
	--L["Grant me your assistance, Wind-Reaver. [Klaxxi Enhancement]"] = ""
	--L["Please fly me to the Terrace of Gurthan"] = ""
-- Tillers
	--L["What kind of gifts do you like?"] = ""
-- Pandaria
	--L["Please fly me to the Terrace of Gurthan"] = ""
-- Northrend
	--L["I need a bat to intercept the Alliance reinforcements."] = ""
-- Outland
	--L["Absolutely!  Send me to the Skyguard Outpost."] = ""
	--L["I'm on a bombing mission for Forward Command To'arch.  I need a wyvern destroyer!"] = ""
	--L["Lend me a Windrider.  I'm going to Spinebreaker Post!"] = ""
	--L["Send me to the Abyssal Shelf!"] = ""
	--L["Send me to Thrallmar!"] = ""
	--L["Yes, I'd love a ride to Blackwind Landing."] = ""
-- Isle of Quel'Danas
	--L["I need to intercept the Dawnblade reinforcements."] = ""
	--L["Speaking of action, I've been ordered to undertake an air strike."] = ""

-- UI
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