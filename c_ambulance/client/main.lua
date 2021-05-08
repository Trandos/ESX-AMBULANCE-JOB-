Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local FirstSpawn, PlayerLoaded = true, false

IsDead = false
ESX = nil
Nombreinter = 0
ReaFaite = false

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer
	PlayerLoaded = true
	if ESX.PlayerData.job.name == 'ambulance' then
		TriggerServerEvent("player:serviceOn", "ambulance")
		TriggerServerEvent("player:serviceOn", "mort")
	end
	if ESX.PlayerData.job.name == 'vigneron' then
		TriggerServerEvent("player:serviceOn", "vigne")
	end
	if ESX.PlayerData.job.name == 'lscustoms' then
		TriggerServerEvent("player:serviceOn", "lscustoms")
	end
end)

AddEventHandler('playerDropped', function(source, reason)
	TriggerServerEvent("player:serviceOff", "ambulance")
	TriggerServerEvent("player:serviceOff", "mort")
end)

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Normal()
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end

	PlayerLoaded = true
	PlayerData = ESX.GetPlayerData()
	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	ESX.PlayerData.job = job
end)

AddEventHandler('playerSpawned', function()
	IsDead = false
	choix = true
	SetTimecycleModifier('')

	if FirstSpawn then
		exports.spawnmanager:setAutoSpawn(false) -- Respawn deaktivieren
		FirstSpawn = false

		ESX.TriggerServerCallback('esx_ambulancejob:getDeathStatus', function(isDead)
			if isDead and Config.AntiCombatLog then
				while not PlayerLoaded do
					Citizen.Wait(1000)
				end
				while choix do
					if IsControlPressed(0, 18) then
						Citizen.Wait(250)
						SetEntityHealth(GetPlayerPed(-1), 0)
						choix = false
					end
					Citizen.Wait(50)
				end
			end
		end)
	end
end)

local poscircuitlsmc = {
	{x = -464.244, y = -338.676, z = 34.500},
	{x = -246.996,  y = 6331.173,  z = 34.28}
}

Citizen.CreateThread(function()
    for k in pairs(poscircuitlsmc) do
	local blip = AddBlipForCoord(poscircuitlsmc[k].x, poscircuitlsmc[k].y, poscircuitlsmc[k].z)
	SetBlipSprite(blip, 61)
	SetBlipScale(blip, 0.6)
	SetBlipColour(blip, 6)
	SetBlipAsShortRange(blip, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("EMS")
    EndTextCommandSetBlipName(blip)
    end
end)

-- Deaktivieren Sie die meisten Eingänge, wenn sie tot sind
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if IsDead then
			DisableAllControlActions(0)
			EnableControlAction(0, Keys['ENTER'], true)
			EnableControlAction(0, Keys['G'], true)
			EnableControlAction(0, Keys['T'], true)
			EnableControlAction(0, Keys['E'], true)
		end
	end
end)

function OnPlayerDeath()
	
	IsDead = true
	ESX.UI.Menu.CloseAll()
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', true)

	StartDeathTimer()
	StartDistressSignal()
	SetTimecycleModifier('li')
	PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", 0)
	--DisplayRadar(false)

	--StartScreenEffect('DeathFailOut', 0, false)

	--exports['progressBars']:startUI(241000, "Coma...")
	ESX.LoadingPrompt("Du bist im Koma.", 20)

------------------------------------------ ZOMBIE ------------------------------------------

	--exports['progressBars']:startUI(60000, "Aurevoir...")
	--Citizen.Wait(60000)
	--TriggerServerEvent("clippy:deconnection1")
	
end

RegisterNetEvent('esx_ambulancejob:useItem')
AddEventHandler('esx_ambulancejob:useItem', function(itemName)
	ESX.UI.Menu.CloseAll()

	if itemName == 'medikit' then
		local lib, anim = 'anim@heists@narcotics@funding@gang_idle', 'gang_chatting_idle01' -- TODO better animations
		local playerPed = PlayerPedId()

		ESX.Streaming.RequestAnimDict(lib, function()
			TaskPlayAnim(playerPed, lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)

			--Citizen.Wait(500)
			exports["a_loadingbar"]:StartDelayedFunction("Vous vous soignez...", 11000, function()
			while IsEntityPlayingAnim(playerPed, lib, anim, 3) do
				Citizen.Wait(0)
				--DisableAllControlActions(0)
			end
			TriggerEvent('esx_ambulancejob:heal', 'big', true)
			ESX.ShowNotification(_U('used_medikit'))
			end)
		end)

	elseif itemName == 'bandage' then
		local lib, anim = 'anim@heists@narcotics@funding@gang_idle', 'gang_chatting_idle01' -- TODO better animations
		local playerPed = PlayerPedId()

		ESX.Streaming.RequestAnimDict(lib, function()
			TaskPlayAnim(playerPed, lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)

			--Citizen.Wait(500)
			exports["a_loadingbar"]:StartDelayedFunction("Vous vous soignez...", 11000, function()
			while IsEntityPlayingAnim(playerPed, lib, anim, 3) do
				Citizen.Wait(0)
				--DisableAllControlActions(0)
			end

			TriggerEvent('esx_ambulancejob:heal', 'small', true)
			ESX.ShowNotification(_U('used_bandage'))
			end)
		end)
	end
end)

function StartDistressSignal()
	Citizen.CreateThread(function()
		local timer = Config.BleedoutTimer

		while timer > 0 and IsDead do
			Citizen.Wait(2)
			timer = timer - 30

			ESX.ShowNotification("~r~Koma.\n~s~Möchten Sie einen Krankenwagen kontaktieren??")
			ESX.ShowNotification("Akzeptieren : ~g~G")

			if IsControlPressed(1, Keys['G']) then
				--SendDistressSignal()
				--ESX.ShowHelpNotification("Nachricht gesendet")
				ESX.LoadingPrompt("Nachricht gesendet", 20)
				Citizen.Wait(6500)
				ESX.LoadingPrompt("Du bist im Koma.", 20)
				--RemoveLoadingPrompt()
				local plyPos = GetEntityCoords(GetPlayerPed(-1), true)
				TriggerServerEvent('esx_addons_gcphone:startCall', 'ambulance',_U('distress_message'), {x=plyPos.x,y=plyPos.y,z=plyPos.z})

				Citizen.CreateThread(function()
					Citizen.Wait(1000 * 60 * 5)
					if IsDead then
						StartDistressSignal()
					end
				end)

				break
			end
		end
	end)
end


function SendDistressSignal()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	ESX.ShowNotification(_U('distress_sent'))
	TriggerServerEvent('esx_addons_gcphone:send', 'ambulance', _U('distress_message'), false, {
		x = coords.x,
		y = coords.y,
		z = coords.z
	})
	local ped = GetPlayerPed(PlayerId())
	local coords = GetEntityCoords(ped, false)
	

	local name = GetPlayerName(PlayerId())

	local x, y, z = table.unpack(GetEntityCoords(ped, true))
	
	TriggerEvent("AppelemsGetCoords")
	DebugEMSRespawn(coords)
end

RegisterNetEvent('esx_ambulancejob:notif')
AddEventHandler('esx_ambulancejob:notif', function()
	Nombreinter = Nombreinter - 1
	if Nombreinter < 0 then
		Nombreinter = 0
	end
	ReaFaite = true
	--ESX.ShowAdvancedNotification('EMS INFO', 'EMS CENTRAL', 'Wiederbelebung durchgeführt. \ N ~ g ~ 150 $ ~ w ~ Zum Unternehmenssafe hinzugefügt. \ N ~ g ~ '.. Nombreinter ..' Intervention läuft.', 'CHAR_MP_MORS_MUTUAL', 3)
	ESX.ShowNotification("~g~Wiederbelebung abgeschlossen\n+ ~g~150$ ~s~Firma.")
end)

function DrawGenericTextThisFrame()
	SetTextFont(4)
	SetTextScale(0.0, 0.4)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
end

function secondsToClock(seconds)
	local seconds, hours, mins, secs = tonumber(seconds), 0, 0, 0

	if seconds <= 0 then
		return 0, 0
	else
		local hours = string.format("%02.f", math.floor(seconds / 3600))
		local mins = string.format("%02.f", math.floor(seconds / 60 - (hours * 60)))
		local secs = string.format("%02.f", math.floor(seconds - hours * 3600 - mins * 60))

		return mins, secs
	end
end

function StartDeathTimer()
	local canPayFine = false

	if Config.EarlyRespawnFine then
		ESX.TriggerServerCallback('esx_ambulancejob:checkBalance', function(canPay)
			canPayFine = canPay
		end)
	end

	local earlySpawnTimer = ESX.Math.Round(Config.EarlyRespawnTimer / 1000)
	local bleedoutTimer = ESX.Math.Round(Config.BleedoutTimer / 1000)

	Citizen.CreateThread(function()
		-- early respawn timer
		while earlySpawnTimer > 0 and IsDead do
			Citizen.Wait(1000)

			if earlySpawnTimer > 0 then
				earlySpawnTimer = earlySpawnTimer - 1
			end
		end

		-- bleedout timer
		while bleedoutTimer > 0 and IsDead do
			Citizen.Wait(1000)

			if bleedoutTimer > 0 then
				bleedoutTimer = bleedoutTimer - 1
			end
		end
	end)

	Citizen.CreateThread(function()
		local text, timeHeld

		-- early respawn timer
		while earlySpawnTimer > 0 and IsDead do
			Citizen.Wait(0)
			text = _U('respawn_available_in', secondsToClock(earlySpawnTimer))

			--exports['progressBars']:startUI(2000, "Inconscient...")

			DrawGenericTextThisFrame()

			SetTextEntry("STRING")
			AddTextComponentString(text)
			DrawText(0.5, 0.960)
		end

		-- bleedout timer
		while bleedoutTimer > 0 and IsDead do
			Citizen.Wait(0)
			text = _U('respawn_bleedout_in', secondsToClock(bleedoutTimer))

			if not Config.EarlyRespawnFine then
				text = "Appuyez sur ~g~E"

				if IsControlPressed(1, Keys['E']) then
					RemoveItemsAfterRPDeath()
					break
				end
			elseif Config.EarlyRespawnFine and canPayFine then
				--text = text .. _U('respawn_bleedout_fine', ESX.Math.GroupDigits(Config.EarlyRespawnFineAmount))
				ESX.ShowNotification("Drücken Sie auf ~g~E~s~ um das Gerät zu benutzen ~r~X~s~ (500$)")

				if IsControlPressed(1, Keys['E']) then
					TriggerServerEvent('esx_ambulancejob:payFine')
					RemoveItemsAfterRPDeath()
					break
				end
			end

			if IsControlPressed(1, Keys['E']) then
				timeHeld = timeHeld + 1
			else
				timeHeld = 0
			end

			DrawGenericTextThisFrame()

			SetTextEntry("STRING")
			AddTextComponentString(text)
			DrawText(0.5, 0.955)
		end
			
		if bleedoutTimer < 1 and IsDead then
			RemoveItemsAfterRPDeath()
		end
	end)
end


function DebugEMSRespawn(coords)
	Wait(1000)
	local ped = GetPlayerPed(-1)
	SetEntityHealth(ped, 150)
	ESX.Game.Teleport(ped, coords, cb)
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(50)
			while IsDead do
				SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0)
				Wait(500)
			end
			ResetPedRagdollTimer(ped)
			return
		end
	end)
end

-- Effekte, wenn der Player von Einheit X wiederbelebt wird

function Normal()
	--Citizen.CreateThread(function()
		local playerPed = GetPlayerPed(-1)
		ClearTimecycleModifier()
		ResetScenarioTypesEnabled()
		SetPedMotionBlur(playerPed, false)
	--end)
end

-- Wiederbelebung durch Einheit X.

function RemoveItemsAfterRPDeath()
	local playerPed = PlayerPedId()
	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)
		while not IsScreenFadedOut() do
			Citizen.Wait(10)
		end

		local pos = GetEntityCoords(GetPlayerPed(-1), true)

		if pos.y > 1600 then
			print("BC")
			respawnlocation = {x = -266.373, y = 6318.053, z = 32.426}
		else
			print("LS")
			respawnlocation = {x = -457.81750488281, y = -280.06494140625, z = 34.914649963379}
		end

			ESX.SetPlayerData('lastPosition', respawnlocation)
			TriggerServerEvent('esx:updateLastPosition', respawnlocation)
			RespawnPed(playerPed, respawnlocation, 0.0)
			ESX.TriggerServerCallback('esx_ambulancejob:removeItemsAfterRPDeath', function() 
				ESX.ShowNotification('~g~Médecin\n~s~Tous vos effets ~g~illegaux~s~ on été ~g~saisis')
			end)
			DoScreenFadeIn(800)
			Citizen.Wait(10)
			SetEntityHealth(GetPlayerPed(-1), 125)
    		ClearPedTasksImmediately(playerPed)
    		SetTimecycleModifier("spectator5") -- Ich weiß nicht, wie es sich anfühlt
    		SetPedMotionBlur(playerPed, true)
    		RequestAnimSet("move_injured_generic")
    		while not HasAnimSetLoaded("move_injured_generic") do
    			Citizen.Wait(0)
    		end
    		SetPedMovementClipset(playerPed, "move_injured_generic", true)
    		PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", 0)
    		--SetCamEffect(2)
    		--PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", 0)
    		--ESX.ShowAdvancedNotification('REANIMATION X', 'Reanimation von Einheit X ',' Sie wurden von Einheit X wiederbelebt.', 'CHAR_CALL911', 1)
    		ESX.DrawMissionText("Sie wurden wiederbelebt.", 6000)
    		DisplayRadar(true)
    		local ped = GetPlayerPed(PlayerId())
    		local coords = GetEntityCoords(ped, false)
    		local name = GetPlayerName(PlayerId())
    		local x, y, z = table.unpack(GetEntityCoords(ped, true))
    		Citizen.Wait(60*1000) -- Auswirkungen der Wiederbelebung für 1 Minute (60 Sekunden)
			Normal()
			
	end)
end

function RespawnPed(ped, coords)
	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.heading, true, false)
	SetPlayerInvincible(ped, false)
	TriggerEvent('playerSpawned', coords.x, coords.y, coords.z, coords.heading)
	ClearPedBloodDamage(ped)

	ESX.UI.Menu.CloseAll()
end

function DebugEMSRespawn(coords)
	Wait(1000)
	local ped = GetPlayerPed(-1)
	SetEntityHealth(ped, 150)
	ESX.Game.Teleport(ped, coords, cb)
	Citizen.CreateThread(function()
		while true do
			Citizen.Wait(50)
			while IsDead do
				SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0)
				Wait(500)
			end
			ResetPedRagdollTimer(ped)
			return
		end
	end)
end

-- Effekte, wenn der Player von Einheit X wiederbelebt wird

function Normal()
	--Citizen.CreateThread(function()
		local playerPed = GetPlayerPed(-1)
		ClearTimecycleModifier()
		ResetScenarioTypesEnabled()
		SetPedMotionBlur(playerPed, false)
	--end)
end

-- Wiederbelebung durch Einheit X.

-- function RemoveItemsAfterRPDeath()
-- 	--Nombreinter = Nombreinter - 1
-- 	local playerPed = PlayerPedId()
-- 	local coords = GetEntityCoords(playerPed)
-- 	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)

-- 	Citizen.CreateThread(function()
-- 		DoScreenFadeOut(800)

-- 		while not IsScreenFadedOut() do
-- 			Citizen.Wait(10)
-- 		end

-- 		local formattedCoords = {
-- 			x = ESX.Math.Round(coords.x, 1),
-- 			y = ESX.Math.Round(coords.y, 1),
-- 			z = ESX.Math.Round(coords.z, 1)
-- 		}

-- 		ESX.SetPlayerData('lastPosition', formattedCoords)

-- 		TriggerServerEvent('esx:updateLastPosition', formattedCoords)

-- 		RespawnPed(playerPed, formattedCoords, 0.0)

-- 		--StopScreenEffect('DeathFailOut')
-- 		DoScreenFadeIn(800)
-- 		Citizen.Wait(10)
-- 		ClearPedTasksImmediately(playerPed)
-- 		SetTimecycleModifier("spectator5") -- Je sait pas se que ça fait lel
-- 		SetPedMotionBlur(playerPed, true)
-- 		RequestAnimSet("move_injured_generic")
-- 			while not HasAnimSetLoaded("move_injured_generic") do
-- 				Citizen.Wait(0)
-- 			end
-- 		SetPedMovementClipset(playerPed, "move_injured_generic", true)
-- 		PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", 0)
-- 		--SetCamEffect(2)
-- 		--PlaySoundFrontend(-1, "1st_Person_Transition", "PLAYER_SWITCH_CUSTOM_SOUNDSET", 0)
-- 		--ESX.ShowAdvancedNotification('REANIMATION X', 'Unité X réanimation', 'Vous avez été réanimé par l\'unité X.', 'CHAR_CALL911', 1)
-- 		ESX.DrawMissionText("Vous avez été réanimé par ~g~l'unité X.", 6000)
-- 		DisplayRadar(true)
-- 		local ped = GetPlayerPed(PlayerId())
-- 		local coords = GetEntityCoords(ped, false)
-- 		local name = GetPlayerName(PlayerId())
-- 		local x, y, z = table.unpack(GetEntityCoords(ped, true))
-- 		Citizen.Wait(60*1000) -- Effets de la réanmation pendant 1 minute ( 60 seconde )
-- 		Normal()

-- 	end)
-- end

function RespawnPed(ped, coords, heading)

	SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false, true)
	NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
	SetPlayerInvincible(ped, false)
	TriggerEvent('playerSpawned', coords.x, coords.y, coords.z)
	ClearPedBloodDamage(ped)

	ESX.UI.Menu.CloseAll()
end

RegisterNetEvent('esx_ambulancejob:NotificationBlipsX2')
AddEventHandler('esx_ambulancejob:NotificationBlipsX2', function(blipId, x, y, z)
	Nombreinter = Nombreinter - 1
	if Nombreinter < 0 then
		Nombreinter = 0
	end
	--ESX.ShowAdvancedNotification('EMS INFO', 'Unité X information', 'Une personne à été réanimer par l\'unité X.\n~g~Il reste '..Nombreinter..' intervention en cours.', 'CHAR_CALL911', 1)
	-- ESX.ShowAdvancedNotification("Central", "~b~Appel d'urgence: 912", "~b~Identité: ~s~Central\n~b~Infos:\n~s~Personne réanimé par l\'unité X.", 'CHAR_CALL911', 7)
	PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", 0)
	local TimerUniteX = 1500
	local BlipsUniteX = AddBlipForCoord(x, y, z)


	SetBlipSprite(BlipsUniteX, 515)
	SetBlipScale(BlipsUniteX, 0.8)
	SetBlipColour(BlipsUniteX, 2)
	SetBlipAlpha(BlipsUniteX, alpha)
	SetBlipAsShortRange(BlipsUniteX, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentSubstringPlayerName('Réanimation par unité X')
	EndTextCommandSetBlipName(BlipsUniteX)


	while TimerUniteX ~= 0 do
		Citizen.Wait(10)
		TimerUniteX = TimerUniteX - 1
		--print('Blips du timer unité x : '..TimerUniteX) --( Juste un débug )
		SetBlipAlpha(BlipsUniteX, TimerUniteX)

		if TimerUniteX == 0 then
			RemoveBlip(BlipsUniteX)
			PlaySoundFrontend(-1, "DELETE", "HUD_DEATHMATCH_SOUNDSET", 0)
			return
		end
	end
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = 'Ambulance',
		number     = 'ambulance',
		base64Icon = 'data:image/png;base64,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'
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	OnPlayerDeath()
end)

RegisterNetEvent('esx_ambulancejob:revive')
AddEventHandler('esx_ambulancejob:revive', function()
	Nombreinter = Nombreinter - 1
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(50)
		end

		local formattedCoords = {
			x = ESX.Math.Round(coords.x, 1),
			y = ESX.Math.Round(coords.y, 1),
			z = ESX.Math.Round(coords.z, 1)
		}

		ESX.SetPlayerData('lastPosition', formattedCoords)

		TriggerServerEvent('esx:updateLastPosition', formattedCoords)
		

		RespawnPed(playerPed, formattedCoords, 0.0)
		SetEntityHealth(playerPed, 125)

		--StopScreenEffect('DeathFailOut')
		RemoveLoadingPrompt()
		DoScreenFadeIn(800)
		
	end)
end)



RegisterNetEvent('esx_ambulancejob:revive2')
AddEventHandler('esx_ambulancejob:revive2', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)

	TriggerServerEvent('esx_ambulancejob:setDeathStatus', false)

	Citizen.CreateThread(function()
		DoScreenFadeOut(800)

		while not IsScreenFadedOut() do
			Citizen.Wait(50)
		end

		local formattedCoords = {
			x = ESX.Math.Round(coords.x, 1),
			y = ESX.Math.Round(coords.y, 1),
			z = ESX.Math.Round(coords.z, 1)
		}

		ESX.SetPlayerData('lastPosition', formattedCoords)

		TriggerServerEvent('esx:updateLastPosition', formattedCoords)

		RespawnPed(playerPed, formattedCoords, 0.0)

		--StopScreenEffect('DeathFailOut')
		RemoveLoadingPrompt()
		DoScreenFadeIn(800)

		ESX.ShowAdvancedNotification('Admin INFO', 'Admin~g~REVIVE', 'Sie wurden von einem Admin wiederbelebt.', 'CHAR_DEVIN', 8)
	end)
end)

-- Load unloaded IPLs
if Config.LoadIpl then
	Citizen.CreateThread(function()
		RequestIpl('Coroner_Int_on') -- Morgue
	end)
end



-- BLIP


function createBlip(id)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)

	if not DoesBlipExist(blip) then -- Fügen Sie blip hinzu und erstellen Sie eine Kopfanzeige auf dem Player
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 1)
		ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip-Anzeige
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped))) -- update rotation
		SetBlipNameToPlayerName(blip, id) -- update blip name
		SetBlipScale(blip, 0.85) -- set scale
		SetBlipColour(blip, 69)
		SetBlipShrink(blip, true)
		SetBlipShowCone(blip, true)
		ShowFriendIndicatorOnBlip(blip, true)

		table.insert(blipsEMS, blip) -- Füge blip zum Array hinzu, damit wir es später entfernen können
	end
end

RegisterNetEvent('EMS:updateBlip')
AddEventHandler('EMS:updateBlip', function()

	-- Refresh all blips
	--for k, existingBlip in pairs(blipsEMS) do
	--	RemoveBlip(existingBlip)
	--end

	-- Clean the blip table
	blipsEMS = {}

	-- Ist der Spieler ein Polizist? In diesem Fall zeigen Sie alle Punkte für andere Polizisten
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
		ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)
			for i=1, #players, 1 do
				if players[i].job.name == 'ambulance' then
					local id = GetPlayerFromServerId(players[i].source)
					if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
						-- createBlip(id)
					end
				end
			end
		end)
	end

end)

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-----------------------------KO---------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

local knockedOut = false
local wait = 30
local count = 60

Citizen.CreateThread(function()
	while true do
		Wait(1)
		local myPed = GetPlayerPed(-1)
		if IsPedInMeleeCombat(myPed) then
			if GetEntityHealth(myPed) <= 115 then
				SetPlayerInvincible(PlayerId(), true)
				SetPedToRagdoll(myPed, 1000, 1000, 0, 0, 0, 0)
				--exports['progressBars']:startUI(10000, "Inconscient...")
				SetTimecycleModifier('li')
				ESX.LoadingPrompt("Inconscient...", 20)
				wait = 30
				knockedOut = true
				--SetEntityHealth(myPed, 116)
			end
		end
		if knockedOut == true then
			SetPlayerInvincible(PlayerId(), true)
			DisablePlayerFiring(PlayerId(), true)
			SetPedToRagdoll(myPed, 1000, 1000, 0, 0, 0, 0)
			ResetPedRagdollTimer(myPed)
			
			if wait >= 0 then
				count = count - 1
				if count == 0 then
					count = 60
					wait = wait - 1
					SetEntityHealth(myPed, GetEntityHealth(myPed)+1)
				end
			else
				SetPlayerInvincible(PlayerId(), false)
				knockedOut = false
				Citizen.Wait(650)
				RemoveLoadingPrompt()
				SetTimecycleModifier('')
				--SetCamEffect(2)
			end
		end
	end
end)




----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------Blesser = Boiter--------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------

local hurt = false
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if GetEntityHealth(GetPlayerPed(-1)) <= 149 then
			setHurt()
			--ESX.LoadingPrompt("Vous êtes blessé", 3)
			--ESX.DrawMissionText("~r~Vous êtes blessé.", 2000)
        elseif hurt and GetEntityHealth(GetPlayerPed(-1)) > 150 then
			setNotHurt()
			RemoveLoadingPrompt()
        end
    end
end)

function setHurt()
    hurt = true
    RequestAnimSet("move_m@injured")
	SetPedMovementClipset(GetPlayerPed(-1), "move_m@injured", true)
	--SetCurrentPedWeapon(GetPlayerPed(-1), GetHashKey("WEAPON_UNARMED"),true)
	--DisableControlAction(0, 37, true)
	--DisableControlAction(0, 21, true)
	--DisableControlAction(0, 22, true)
end

function setNotHurt()
    hurt = false
    ResetPedMovementClipset(GetPlayerPed(-1))
    ResetPedWeaponMovementClipset(GetPlayerPed(-1))
    ResetPedStrafeClipset(GetPlayerPed(-1))
end

--[[ Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
			if IsControlPressed(1, 192) and GetEntityHealth(GetPlayerPed(-1)) <= 149 then 
			ESX.ShowNotification("~r~Blessé.~s~\nVous êtes dans l'incapacité d'utiliser une arme.")
		end
    end
end) ]]

--[[ Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
			if IsControlPressed(1, 216) and GetEntityHealth(GetPlayerPed(-1)) <= 149 then 
			ESX.ShowNotification("~r~Blessé.~s~\nVous êtes dans l'incapacité de sauter.")
        end
    end
end) ]]

---------------------------------- npcjob ------------------------------------------
function DrawSub(msg, time)
	ClearPrints()
	SetTextEntry_2("STRING")
	AddTextComponentString(msg)
	DrawSubtitleTimed(time, 1)
  end
  
  function ShowLoadingPromt(msg, time, type)
	Citizen.CreateThread(function()
	  Citizen.Wait(0)
	  N_0xaba17d7ce615adbf("STRING")
	  AddTextComponentString(msg)
	  N_0xbd12f8228410d9b4(type)
	  Citizen.Wait(time)
	  N_0x10d373323e5b9c0d()
	end)
  end
  
  function GetRandomWalkingNPC()
  
	local search = {}
	local peds   = ESX.Game.GetPeds()
  
	for i=1, #peds, 1 do
	  if IsPedHuman(peds[i]) and IsPedWalking(peds[i]) and not IsPedAPlayer(peds[i]) then
		table.insert(search, peds[i])
	  end
	end
  
	if #search > 0 then
	  return search[GetRandomIntInRange(1, #search)]
	end
  
  
	for i=1, 250, 1 do
  
	  local ped = GetRandomPedAtCoord(0.0,  0.0,  0.0,  math.huge + 0.0,  math.huge + 0.0,  math.huge + 0.0,  26)
  
	  if DoesEntityExist(ped) and IsPedHuman(ped) and IsPedWalking(ped) and not IsPedAPlayer(ped) then
		table.insert(search, ped)
	  end
  
	end
  
	if #search > 0 then
	  return search[GetRandomIntInRange(1, #search)]
	end
  
  end
  
  function ClearCurrentMission()
  
	if DoesBlipExist(CurrentCustomerBlip) then
	  RemoveBlip(CurrentCustomerBlip)
	end
  
	if DoesBlipExist(DestinationBlip) then
	  RemoveBlip(DestinationBlip)
	end
  
	CurrentCustomer           = nil
	CurrentCustomerBlip       = nil
	DestinationBlip           = nil
	IsNearCustomer            = false
	CustomerIsEnteringVehicle = false
	CustomerEnteredVehicle    = false
	TargetCoords              = nil
  
  end
  
  function StartAmbulanceJob()
  
	ShowLoadingPromt(_U('taking_service') .. 'Ambulance', 5000, 3)
	ClearCurrentMission()
  
	OnJob = true
  
  end
  
  function StopAmbulanceJob()
  
	local playerPed = GetPlayerPed(-1)
  
	if IsPedInAnyVehicle(playerPed, false) and CurrentCustomer ~= nil then
	  local vehicle = GetVehiclePedIsIn(playerPed,  false)
	  TaskLeaveVehicle(CurrentCustomer,  vehicle,  0)
  
	  if CustomerEnteredVehicle then
		TaskGoStraightToCoord(CurrentCustomer,  TargetCoords.x,  TargetCoords.y,  TargetCoords.z,  1.0,  -1,  0.0,  0.0)
	  end
  
	end
  
	ClearCurrentMission()
  
	OnJob = false
  
	DrawSub(_U('mission_complete'), 5000)
  
  end
------------------------------------------------------------------------------------
------------------------------- npcjob -------------------------------------
-- Taxi Job
Citizen.CreateThread(function()

	while true do
  
	  Citizen.Wait(0)
  
	  local playerPed = GetPlayerPed(-1)
  
	  if OnJob then
  
		if CurrentCustomer == nil then
  
		  DrawSub(_U('drive_search_pass'), 5000)
  
		  if IsPedInAnyVehicle(playerPed,  false) and GetEntitySpeed(playerPed) > 0 then
  
			local waitUntil = GetGameTimer() + GetRandomIntInRange(30000,  45000)
  
			while OnJob and waitUntil > GetGameTimer() do
			  Citizen.Wait(0)
			end
  
			if OnJob and IsPedInAnyVehicle(playerPed,  false) and GetEntitySpeed(playerPed) > 0 then
  
			  CurrentCustomer = GetRandomWalkingNPC()
  
			  if CurrentCustomer ~= nil then
  
				CurrentCustomerBlip = AddBlipForEntity(CurrentCustomer)
  
				SetBlipAsFriendly(CurrentCustomerBlip, 1)
				SetBlipColour(CurrentCustomerBlip, 2)
				SetBlipCategory(CurrentCustomerBlip, 3)
				SetBlipRoute(CurrentCustomerBlip,  true)
  
				SetEntityAsMissionEntity(CurrentCustomer,  true, false)
				ClearPedTasksImmediately(CurrentCustomer)
				SetBlockingOfNonTemporaryEvents(CurrentCustomer, 1)
  
				local standTime = GetRandomIntInRange(60000,  180000)
  
				TaskStandStill(CurrentCustomer, standTime)
  
				ESX.ShowNotification(_U('customer_found'))
  
			  end
  
			end
  
		  end
  
		else
  
		  if IsPedFatallyInjured(CurrentCustomer) then
  
			ESX.ShowNotification(_U('client_unconcious'))
  
			if DoesBlipExist(CurrentCustomerBlip) then
			  RemoveBlip(CurrentCustomerBlip)
			end
  
			if DoesBlipExist(DestinationBlip) then
			  RemoveBlip(DestinationBlip)
			end
  
			SetEntityAsMissionEntity(CurrentCustomer,  false, true)
  
			CurrentCustomer           = nil
			CurrentCustomerBlip       = nil
			DestinationBlip           = nil
			IsNearCustomer            = false
			CustomerIsEnteringVehicle = false
			CustomerEnteredVehicle    = false
			TargetCoords              = nil
  
		  end
  
		  if IsPedInAnyVehicle(playerPed,  false) then
  
			local vehicle          = GetVehiclePedIsIn(playerPed,  false)
			local playerCoords     = GetEntityCoords(playerPed)
			local customerCoords   = GetEntityCoords(CurrentCustomer)
			local customerDistance = GetDistanceBetweenCoords(playerCoords.x,  playerCoords.y,  playerCoords.z,  customerCoords.x,  customerCoords.y,  customerCoords.z)
  
			if IsPedSittingInVehicle(CurrentCustomer,  vehicle) then
  
			  if CustomerEnteredVehicle then
  
				local targetDistance = GetDistanceBetweenCoords(playerCoords.x,  playerCoords.y,  playerCoords.z,  TargetCoords.x,  TargetCoords.y,  TargetCoords.z)
  
				if targetDistance <= 10.0 then
  
				  TaskLeaveVehicle(CurrentCustomer,  vehicle,  0)
  
				  ESX.ShowNotification(_U('arrive_dest'))
  
				  TaskGoStraightToCoord(CurrentCustomer,  TargetCoords.x,  TargetCoords.y,  TargetCoords.z,  1.0,  -1,  0.0,  0.0)
				  SetEntityAsMissionEntity(CurrentCustomer,  false, true)
  
				  TriggerServerEvent('esx_ambulancejob:success')
  
				  RemoveBlip(DestinationBlip)
  
				  local scope = function(customer)
					ESX.SetTimeout(60000, function()
					  DeletePed(customer)
					end)
				  end
  
				  scope(CurrentCustomer)
  
				  CurrentCustomer           = nil
				  CurrentCustomerBlip       = nil
				  DestinationBlip           = nil
				  IsNearCustomer            = false
				  CustomerIsEnteringVehicle = false
				  CustomerEnteredVehicle    = false
				  TargetCoords              = nil
  
				end
  
				if TargetCoords ~= nil then
				  DrawMarker(1, TargetCoords.x, TargetCoords.y, TargetCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 4.0, 4.0, 2.0, 178, 236, 93, 155, 0, 0, 2, 0, 0, 0, 0)
				end
  
			  else
  
				RemoveBlip(CurrentCustomerBlip)
  
				CurrentCustomerBlip = nil
  
				TargetCoords = Config.JobLocations[GetRandomIntInRange(1,  #Config.JobLocations)]
  
				local street = table.pack(GetStreetNameAtCoord(TargetCoords.x, TargetCoords.y, TargetCoords.z))
				local msg    = nil
  
				if street[2] ~= 0 and street[2] ~= nil then
				  msg = string.format(_U('take_me_to_near', GetStreetNameFromHashKey(street[1]),GetStreetNameFromHashKey(street[2])))
				else
				  msg = string.format(_U('take_me_to', GetStreetNameFromHashKey(street[1])))
				end
  
				ESX.ShowNotification(msg)
  
				DestinationBlip = AddBlipForCoord(TargetCoords.x, TargetCoords.y, TargetCoords.z)
  
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString("Destination")
				EndTextCommandSetBlipName(blip)
  
				SetBlipRoute(DestinationBlip,  true)
  
				CustomerEnteredVehicle = true
  
			  end
  
			else
  
			  DrawMarker(1, customerCoords.x, customerCoords.y, customerCoords.z - 1.0, 0, 0, 0, 0, 0, 0, 4.0, 4.0, 2.0, 178, 236, 93, 155, 0, 0, 2, 0, 0, 0, 0)
  
			  if not CustomerEnteredVehicle then
  
				if customerDistance <= 30.0 then
  
				  if not IsNearCustomer then
					ESX.ShowNotification(_U('close_to_client'))
					IsNearCustomer = true
				  end
  
				end
  
				if customerDistance <= 100.0 then
  
				  if not CustomerIsEnteringVehicle then
  
					ClearPedTasksImmediately(CurrentCustomer)
  
					local seat = 2
  
					for i=4, 0, 1 do
					  if IsVehicleSeatFree(vehicle,  seat) then
						seat = i
						break
					  end
					end
  
					TaskEnterVehicle(CurrentCustomer,  vehicle,  -1,  seat,  2.0,  1)
  
					CustomerIsEnteringVehicle = true
  
				  end
  
				end
  
			  end
  
			end
  
		  else
  
			DrawSub(_U('return_to_veh'), 5000)
  
		  end
  
		end
  
	  end
  
	end
  end)
  ---------------------------------------------------------------------------