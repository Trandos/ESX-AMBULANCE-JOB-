local CurrentAction, CurrentActionMsg, CurrentActionData = nil, '', {}
local HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum
local IsBusy = false
local spawnedVehicles, isInShopMenu = {}, false
local enService = false

function OpenAmbulanceActionsMenu()
	local elements = {
		{label = _U('cloakroom'), value = 'cloakroom'}
	}

	if Config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'boss' then
		table.insert(elements, {label = _U('boss_actions'), value = 'boss_actions'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ambulance_actions', {
		css      = 'head',
		title    = _U('ambulance'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.value == 'cloakroom' then
			OpenCloakroomMenu()
		elseif data.current.value == 'boss_actions' then
			TriggerEvent('esx_society:openBossMenu', 'ambulance', function(data, menu)
				menu.close()
			end, {wash = false})
		end
	end, function(data, menu)
		menu.close()
	end)
end

LoadModel = function(model)
	while not HasModelLoaded(model) do
		RequestModel(model)
		
		Citizen.Wait(1)
	end
end

function OpenMobileAmbulanceActionsMenu()
	TriggerEvent("EMS:updateBlip")
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'mobile_ambulance_actions', {
		css      = 'head',
		title    = _U('ambulance'),
		align    = 'top-left',
		elements = {
			{label = 'Anrufbearbeitung <span style="color:;"> >', value = 'gestion_appels'},
			{label = 'Bürgerinteraktion <span style="color:;"> >', value = 'citizen_interaction'},
			{ label = 'Geben Sie eine Rechnung <span style="color:;"> >',   value = 'billing' },
			{label = '<span style="color:rgb(2, 117, 214);">EMS Verfügbar',     value = 'ems_ouvert'},
			{label = '<span style="color:rgb(2, 117, 214);">EMS Nicht verfügbar',     value = 'ems_ferme'}
		}
	}, function(data, menu)
		if data.current.value == 'billing' then

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'billing', {
				css      = 'head',
				title = ('Geben Sie den Betrag der EMS-Rechnung ein')
			}, function(data, menu)

				local amount = tonumber(data.value)
				if amount == nil then
					ESX.ShowNotification('~r~Falscher Betrag')
				else
					menu.close()
					local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
					if closestPlayer == -1 or closestDistance > 3.0 then
						ESX.ShowNotification('Kein Spieler in der Nähe')
					else
						TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_ambulance', 'Ambulance', amount)
						ESX.ShowNotification('~g~Rechnung versandt.')
					end

				end

			end, function(data, menu)
				menu.close()
			end)

		elseif data.current.value == 'ems_ouvert' then
			TriggerServerEvent('AnnounceEMSOuvert')
		elseif data.current.value == 'ems_ferme' then
			TriggerServerEvent('AnnounceEMSFerme')
		
		elseif data.current.value == 'gestion_appels' then
			local elements = {
				{label = 'Brechen Sie den letzten Anruf ab', value = 'cancelcall'}
			}

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gestion_appels', {
				css      = 'head',
				title    = 'Gestion des appels',
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local action = data2.current.value

				if action == 'cancelcall' then
					TriggerEvent('call:cancelCall')
				end
			end, function(data2, menu2)
				menu2.close()
			end)

		elseif data.current.value == 'citizen_interaction' then
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				css      = 'head',
				title    = _U('ems_menu_title'),
				align    = 'top-left',
				elements = {
					{label = _U('ems_menu_revive'), value = 'revive'},
					{label = _U('ems_menu_small'), value = 'small'},
					{label = _U('ems_menu_big'), value = 'big'},
					{label = _U('ems_menu_putincar'), value = 'put_in_vehicle'},
					{label = 'Einen Rollstuhl rausholen', value = 'wheelchair'},
					{label = 'Entfernen Sie einen Rollstuhl', value = 'wheelchairsuppr'}
				}
			}, function(data, menu)
				if IsBusy then return end

				if data.current.value == 'wheelchair' then
					LoadModel('prop_wheelchair_01')
					local wheelchair = CreateObject(GetHashKey('prop_wheelchair_01'), GetEntityCoords(PlayerPedId()), true)
				elseif data.current.value == 'wheelchairsuppr' then
					local wheelchair = GetClosestObjectOfType(GetEntityCoords(PlayerPedId()), 10.0, GetHashKey('prop_wheelchair_01'))

					if DoesEntityExist(wheelchair) then
						DeleteEntity(wheelchair)
					end
				end

				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

				if closestPlayer == -1 or closestDistance > 2.5 then
					ESX.ShowNotification(_U('no_players'))
				else

					if data.current.value == 'revive' then

						IsBusy = true

						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)

								if IsPedDeadOrDying(closestPlayerPed, 1) then
									local playerPed = PlayerPedId()

									ESX.ShowNotification(_U('revive_inprogress'))

									local lib, anim = 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest'


									for i=1, 15, 1 do
										Citizen.Wait(900)
								
										ESX.Streaming.RequestAnimDict(lib, function()
											TaskPlayAnim(PlayerPedId(), lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
										end)
									end

									TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('esx_ambulancejob:revive', GetPlayerServerId(closestPlayer))
									RemoveAnimDict('mini@cpr@char_a@cpr_str')
									RemoveAnimDict('cpr_pumpchest')

									-- Show revive award?
									if Config.ReviveReward > 0 then
										ESX.ShowNotification(_U('revive_complete_award', GetPlayerName(closestPlayer), Config.ReviveReward))
									else
										ESX.ShowNotification(_U('revive_complete', GetPlayerName(closestPlayer)))
									end
								else
									ESX.ShowNotification(_U('player_not_unconscious'))
								end
							else
								ESX.ShowNotification(_U('not_enough_medikit'))
							end

							IsBusy = false

						end, 'medikit')

					elseif data.current.value == 'small' then

						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = PlayerPedId()

									IsBusy = true
									--ESX.ShowNotification(_U('heal_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									--Citizen.Wait(10000)
									exports["a_loadingbar"]:StartDelayedFunction("Du heilst...", 10000, function()
									ClearPedTasks(playerPed)

									TriggerServerEvent('esx_ambulancejob:removeItem', 'bandage')
									TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'small')
									ESX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
									IsBusy = false
									end)
								else
									ESX.ShowNotification(_U('player_not_conscious'))
								end
							else
								ESX.ShowNotification(_U('not_enough_bandage'))
							end
						end, 'bandage')

					elseif data.current.value == 'big' then

						ESX.TriggerServerCallback('esx_ambulancejob:getItemAmount', function(quantity)
							if quantity > 0 then
								local closestPlayerPed = GetPlayerPed(closestPlayer)
								local health = GetEntityHealth(closestPlayerPed)

								if health > 0 then
									local playerPed = PlayerPedId()

									IsBusy = true
									--ESX.ShowNotification(_U('heal_inprogress'))
									TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
									--Citizen.Wait(10000)
									exports["a_loadingbar"]:StartDelayedFunction("Du heilst...", 10000, function()
									ClearPedTasks(playerPed)

									TriggerServerEvent('esx_ambulancejob:removeItem', 'medikit')
									TriggerServerEvent('esx_ambulancejob:heal', GetPlayerServerId(closestPlayer), 'big')
									ESX.ShowNotification(_U('heal_complete', GetPlayerName(closestPlayer)))
									IsBusy = false
									end)
								else
									ESX.ShowNotification(_U('player_not_conscious'))
								end
							else
								ESX.ShowNotification(_U('not_enough_medikit'))
							end
						end, 'medikit')

					elseif data.current.value == 'put_in_vehicle' then
						TriggerServerEvent('esx_ambulancejob:putInVehicle', GetPlayerServerId(closestPlayer))
					end
				end
			end, function(data, menu)
				menu.close()
			end)
		end

	end, function(data, menu)
		menu.close()
	end)
end

function FastTravel(coords, heading)
	local playerPed = PlayerPedId()

	DoScreenFadeOut(800)

	while not IsScreenFadedOut() do
		Citizen.Wait(500)
	end

	ESX.Game.Teleport(playerPed, coords, function()
		DoScreenFadeIn(800)

		if heading then
			SetEntityHeading(playerPed, heading)
		end
	end)
end

-- Markierungen und Markierungslogik zeichnen
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())
		local letSleep, isInMarker, hasExited = true, false, false
		local currentHospital, currentPart, currentPartNum

		for hospitalNum,hospital in pairs(Config.Hospitals) do

			-- Ambulance Actions
			for k,v in ipairs(hospital.AmbulanceActions) do
				local distance = GetDistanceBetweenCoords(playerCoords, v, true)

				if distance < Config.DrawDistance then
					--DrawMarker(25, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 255, 17, Config.Marker.a, true, true, 2, Config.Marker.rotate, nil, nil, false)
					DrawMarker(25, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.25, 1.25, 1.0001, 0, 128, 0, 200, 0, 0, 0, 0)
					letSleep = false
				end

				if distance < Config.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'AmbulanceActions', k
				end
			end

			-- Pharmacies
			for k,v in ipairs(hospital.Pharmacies) do
				local distance = GetDistanceBetweenCoords(playerCoords, v, true)

				if distance < Config.DrawDistance then
					--DrawMarker(25, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 255, 17, Config.Marker.a, true, true, 2, Config.Marker.rotate, nil, nil, false)
					DrawMarker(25, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.25, 1.25, 1.0001, 0, 128, 0, 200, 0, 0, 0, 0)
					letSleep = false
				end

				if distance < Config.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Pharmacy', k
				end
			end

			-- Vehicle Spawners
			for k,v in ipairs(hospital.Vehicles) do
				local distance = GetDistanceBetweenCoords(playerCoords, v.Spawner, true)

				if distance < Config.DrawDistance then
					DrawMarker(v.Marker.type, v.Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
					letSleep = false
				end

				if distance < v.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Vehicles', k
				end
			end

			-- Helicopter Spawners
			for k,v in ipairs(hospital.Helicopters) do
				local distance = GetDistanceBetweenCoords(playerCoords, v.Spawner, true)

				if distance < Config.DrawDistance then
					DrawMarker(v.Marker.type, v.Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
					letSleep = false
				end

				if distance < v.Marker.x then
					isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'Helicopters', k
				end
			end

--			 Fast Travels
--			for k,v in ipairs(hospital.FastTravels) do
--				local distance = GetDistanceBetweenCoords(playerCoords, v.From, true)
--
--				if distance < Config.DrawDistance then
--					DrawMarker(20, v, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 0, 255, 17, 255, true, true, 2, false, nil, --nil, false)
--					letSleep = false
--				end
--
--
--				if distance < v.Marker.x then
--					FastTravel(v.To.coords, v.To.heading)
--				end
--			end

			---- Fast Travels (Prompt)
			--for k,v in ipairs(hospital.FastTravelsPrompt) do
			--	local distance = GetDistanceBetweenCoords(playerCoords, v.From, true)
--
			--	if distance < Config.DrawDistance then
			--		DrawMarker(v.Marker.type, v.From, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, --v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, v.Marker.rotate, nil, nil, false)
			--		letSleep = false
			--	end
--
			--	if distance < v.Marker.x then
			--		isInMarker, currentHospital, currentPart, currentPartNum = true, hospitalNum, 'FastTravelsPrompt', k
			--	end
			--end

		end

		-- Logic for exiting & entering markers
		if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then

			if
				(LastHospital ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
				(LastHospital ~= currentHospital or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
			then
				TriggerEvent('esx_ambulancejob:hasExitedMarker', LastHospital, LastPart, LastPartNum)
				hasExited = true
			end

			HasAlreadyEnteredMarker, LastHospital, LastPart, LastPartNum = true, currentHospital, currentPart, currentPartNum

			TriggerEvent('esx_ambulancejob:hasEnteredMarker', currentHospital, currentPart, currentPartNum)

		end

		if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_ambulancejob:hasExitedMarker', LastHospital, LastPart, LastPartNum)
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('esx_ambulancejob:hasEnteredMarker', function(hospital, part, partNum)
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
		if part == 'AmbulanceActions' then
			CurrentAction = part
			CurrentActionMsg = _U('actions_prompt')
			CurrentActionData = {}
		elseif part == 'Pharmacy' then
			CurrentAction = part
			CurrentActionMsg = _U('open_pharmacy')
			CurrentActionData = {}
		elseif part == 'Vehicles' then
			CurrentAction = part
			CurrentActionMsg = _U('garage_prompt')
			CurrentActionData = {hospital = hospital, partNum = partNum}
		elseif part == 'Helicopters' then
			CurrentAction = part
			CurrentActionMsg = _U('helicopter_prompt')
			CurrentActionData = {hospital = hospital, partNum = partNum}
		elseif part == 'FastTravelsPrompt' then
			local travelItem = Config.Hospitals[hospital][part][partNum]

			CurrentAction = part
			CurrentActionMsg = travelItem.Prompt
			CurrentActionData = {to = travelItem.To.coords, heading = travelItem.To.heading}
		end
	end
end)

AddEventHandler('esx_ambulancejob:hasExitedMarker', function(hospital, part, partNum)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

	CurrentAction = nil
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, Keys['E']) then

				if CurrentAction == 'AmbulanceActions' then
					OpenAmbulanceActionsMenu()
				elseif CurrentAction == 'Pharmacy' then
					OpenPharmacyMenu()
				elseif CurrentAction == 'Vehicles' then
					OpenVehicleList()
				elseif CurrentAction == 'Helicopters' then
					OpenHelicopterSpawnerMenu(CurrentActionData.hospital, CurrentActionData.partNum)
				elseif CurrentAction == 'FastTravelsPrompt' then
					FastTravel(CurrentActionData.to, CurrentActionData.heading)
				end

				CurrentAction = nil

			end

		elseif ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == 'ambulance' and not IsDead then
			if IsControlJustReleased(0, Keys['F6']) then
				OpenMobileAmbulanceActionsMenu()
			end
			if IsControlPressed(0, Keys['DELETE']) then -------------------------------------------------------------
				if OnJob then
				  StopAmbulanceJob()
				else
				  	if PlayerData.job ~= nil and PlayerData.job.name == 'ambulance' then
						local playerPed = GetPlayerPed(-1)
						if IsPedInAnyVehicle(playerPed,  false) then
					  		local vehicle = GetVehiclePedIsIn(playerPed,  false)
					 		if PlayerData.job.grade >= 3 then
								StartAmbulanceJob()
					  		else
								if GetEntityModel(vehicle) == GetHashKey('20ramambo') then
									StartAmbulanceJob()
								elseif GetEntityModel(vehicle) == GetHashKey('qrv') then
									StartAmbulanceJob()
								elseif GetEntityModel(vehicle) == GetHashKey('dodgeems') then
									StartAmbulanceJob()
								else
									ESX.ShowNotification("Sie müssen in einem Krankenwagen sein, um eine Mission zu starten")
								end
					 		end
						else
							if PlayerData.job.grade >= 3 then
								ESX.ShowNotification("Sie müssen in einem Krankenwagen sein, um eine Mission zu starten")
							else
								ESX.ShowNotification("Vous devez être dans une ~g~Ambulance ~s~pour lancer une mission")
							end
						end
				 	end
				end  
				Citizen.Wait(5000)
			end ----------------------------------------------------------------------------------------------
		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('esx_ambulancejob:putInVehicle')
AddEventHandler('esx_ambulancejob:putInVehicle', function()
	local playerPed = PlayerPedId()
	local coords    = GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords, 5.0) then
		local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

			for i=maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle, i) then
					freeSeat = i
					break
				end
			end

			if freeSeat then
				TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
			end
		end
	end
end)

function OpenCloakroomMenu()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		css      = 'head',
		title    = _U('cloakroom'),
		align    = 'top-left',
		elements = {
			{label = _U('ems_clothes_civil'), value = 'citizen_wear'},
			{label = _U('ems_clothes_ems'), value = 'ambulance_wear'},
		}
	}, function(data, menu)
		if data.current.value == 'citizen_wear' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
			enService = false
			TriggerEvent("EMS:PriseDeService", false)
		elseif data.current.value == 'ambulance_wear' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					local clothesSkin = {
						['tshirt_1'] = 87, ['tshirt_2'] = 0,
						['torso_1'] = 250, ['torso_2'] = 1,
						['arms'] = 85,
						['pants_1'] = 96, ['pants_2'] = 1,
						['shoes_1'] = 12, ['shoes_2'] = 6,
						['bproof_1'] = 13,
						['helmet_1'] = 122, ['helmet_2'] = 1,
						["decals_1"] = 58, ["decals_2"] = 0,
						['chain_1'] = 5, ['chain_2'] = 0
					}
					TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
				elseif skin.sex == 1 then
					local clothesSkin = {
						['tshirt_1'] = 15, ['tshirt_2'] = 0,
						['torso_1'] = 258, ['torso_2'] = 1,
						['decals_1'] = 66, ['decals_2'] = 0,
						['arms'] = 106,
						['pants_1'] = 99, ['pants_2'] = 1,
						['shoes_1'] = 27, ['shoes_2'] = 0,
						['helmet_1'] = 121, ['helmet_2'] = 1,
						['bproof_1'] = 14, ['bproof_2'] = 0,
						['chain_1'] = 6, ['chain_2'] = 1
					}
					TriggerEvent('skinchanger:loadClothes', skin, clothesSkin)
				end
			end)
			enService = true
			TriggerEvent("EMS:PriseDeService", true)
		end

		menu.close()
	end, function(data, menu)
		menu.close()
	end)
end

local posdeleteveham = {
	{x = -264.057, y = 6341.100, z = 32.42},
	{x = 351.20755004883, y = -588.56945800781, z = 74.165664672852},
	{x = -430.716, y = -363.056, z = 24.530}
}

Citizen.CreateThread(function()
    local attente = 150
    while true do
        Wait(attente)

        for k in pairs(posdeleteveham) do

            local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
            local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, posdeleteveham[k].x, posdeleteveham[k].y, posdeleteveham[k].z)

			if dist <= 5.0 then
				attente = 1
				if ESX.PlayerData.job.name == 'ambulance' then 
					if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
						ESX.ShowHelpNotification("Drücken Sie auf ~INPUT_CONTEXT~ um das Fahrzeug zureinigen")
						if IsControlJustPressed(1,51) then 
							RangerVeh(vehicle)
						end
						break
					else
						attente = 150
					end
				end
			end
        end
    end
end)

function RangerVeh(vehicle)
    local playerPed = GetPlayerPed(-1)
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local props = ESX.Game.GetVehicleProperties(vehicle)
    local current = GetPlayersLastVehicle(GetPlayerPed(-1), true)
    local engineHealth = GetVehicleEngineHealth(current)

    if IsPedInAnyVehicle(GetPlayerPed(-1), true) then 
        if engineHealth < 600 then
            ESX.ShowNotification("~r~Ihr Fahrzeug ist zu beschädigt, Sie können es nicht aufbewahren.")
        else
            ESX.Game.DeleteVehicle(vehicle)
            TriggerServerEvent('esx_vehiclelock:deletekeyjobs', 'no', plate)
            ESX.ShowNotification("~g~Gespeichertes Fahrzeug.")
        end
	end
end

function spawnCar(car)
	local car = GetHashKey(car)
	
    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(0)
    end
	local vehicle = CreateVehicle(car, -430.716, -363.056, 24.230, 20.0, true, false)
	SetVehicleNumberPlateText(vehicle, "EMS")
	SetEntityAsMissionEntity(vehicle, true, true)
	local plate = GetVehicleNumberPlateText(vehicle)
	TriggerServerEvent('esx_vehiclelock:givekey', 'no', plate) 
end

function spawnCarNorth(car)
	local car = GetHashKey(car)
	
    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(0)
    end

	local vehicle = CreateVehicle(car, -246.238, 6340.731, 32.42-0.50, 224.3, true, false)
	SetVehicleNumberPlateText(vehicle, "EMS")
	SetEntityAsMissionEntity(vehicle, true, true)
	local plate = GetVehicleNumberPlateText(vehicle)
	TriggerServerEvent('esx_vehiclelock:givekey', 'no', plate) 
end

local posnorthcar = { 
	vector3(-254.388, 6340.048, 32.42)
}

Citizen.CreateThread(function()
	while true do 
		Wait(1)
		for k in pairs(posnorthcar) do 

			local plyCoords = GetEntityCoords(GetPlayerPed(-1), false)
			local dist = Vdist(plyCoords.x, plyCoords.y, plyCoords.z, posnorthcar[k].x, posnorthcar[k].y, posnorthcar[k].z)
			
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
				if dist <= 10.0 then 
					DrawMarker(25, posnorthcar[k].x, posnorthcar[k].y, posnorthcar[k].z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.25, 1.25, 1.0001, 0, 128, 0, 200, 0, 0, 0, 0)
					if dist <= 1.5 then 
						ESX.ShowHelpNotification("Drücken Sie auf ~INPUT_CONTEXT~ um die Garage zu öffnen")
						if IsControlJustPressed(1, 51) then 
							OpenVehicleListNorth()
						end
					end
				end
			end
		end
	end
end)




function OpenVehicleListNorth()
    local elems = {
		{label = ("Ambulance"),     value = 'spawn_ambulance'},
		{label = ("Bett"),     value = 'spawn_bed'},
		{label = ("Ford Explorer"),     value = 'spawn_explorer'},
		{label = ("Dodge Charger"),     value = 'spawn_charger'},
    }

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vocal',
    {
        css = 'head',
        title  = 'Liste des véhicules disponibles',
        align = 'top-left',
        elements = elems
    },

    function(data, menu)
        if data.current.value == 'spawn_ambulance' then 
			spawnCarNorth('20ramambo')
			menu.close()
		elseif data.current.value == 'spawn_bed' then
			spawnCarNorth('stretcher')
			menu.close()
        elseif data.current.value == 'spawn_explorer' then
			spawnCarNorth('qrv')
			menu.close()
        elseif data.current.value == 'spawn_charger' then 
			spawnCarNorth('dodgeems')
			menu.close()
        end
    end,
        
    function(data, menu)
        menu.close()
	end)
end

function OpenVehicleList()
    local elems = {
		{label = ("Ambulance"),     value = 'spawn_ambulance'},
		{label = ("Lit"),     value = 'spawn_bed'},
		{label = ("Ford Explorer"),     value = 'spawn_explorer'},
		{label = ("Dodge Charger"),     value = 'spawn_charger'},
    }

    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vocal',
    {
        css = 'head',
        title  = 'Liste des véhicules disponibles',
        align = 'top-left',
        elements = elems
    },

    function(data, menu)
        if data.current.value == 'spawn_ambulance' then 
			spawnCar('20ramambo')
			menu.close()
		elseif data.current.value == 'spawn_bed' then
			spawnCar('stretcher')
			menu.close()
        elseif data.current.value == 'spawn_explorer' then
			spawnCar('qrv')
			menu.close()
        elseif data.current.value == 'spawn_charger' then 
			spawnCar('dodgeems')
			menu.close()
        end
    end,
        
    function(data, menu)
        menu.close()
	end)
end

function StoreNearbyVehicle(playerCoords)
	local vehicles, vehiclePlates = ESX.Game.GetVehiclesInArea(playerCoords, 30.0), {}

	if #vehicles > 0 then
		for k,v in ipairs(vehicles) do

			-- Stellen Sie sicher, dass das Fahrzeug, das wir speichern, leer ist. Andernfalls wird es nicht gelöscht
			if GetVehicleNumberOfPassengers(v) == 0 and IsVehicleSeatFree(v, -1) then
				table.insert(vehiclePlates, {
					vehicle = v,
					plate = ESX.Math.Trim(GetVehicleNumberPlateText(v))
				})
			end
		end
	else
		ESX.ShowNotification(_U('garage_store_nearby'))
		return
	end

	ESX.TriggerServerCallback('esx_ambulancejob:storeNearbyVehicle', function(storeSuccess, foundNum)
		if storeSuccess then
			local vehicleId = vehiclePlates[foundNum]
			local attempts = 0
			ESX.Game.DeleteVehicle(vehicleId.vehicle)
			IsBusy = true

			Citizen.CreateThread(function()
				while IsBusy do
					Citizen.Wait(0)
					drawLoadingText(_U('garage_storing'), 255, 255, 255, 255)
				end
			end)

			-- Problemumgehung für Fahrzeuge, die nicht gelöscht werden, wenn sich andere Spieler in der Nähe befinden.
			while DoesEntityExist(vehicleId.vehicle) do
				Citizen.Wait(500)
				attempts = attempts + 1

				-- Gib auf
				if attempts > 30 then
					break
				end

				vehicles = ESX.Game.GetVehiclesInArea(playerCoords, 30.0)
				if #vehicles > 0 then
					for k,v in ipairs(vehicles) do
						if ESX.Math.Trim(GetVehicleNumberPlateText(v)) == vehicleId.plate then
							ESX.Game.DeleteVehicle(v)
							break
						end
					end
				end
			end

			IsBusy = false
			ESX.ShowNotification(_U('garage_has_stored'))
		else
			ESX.ShowNotification(_U('garage_has_notstored'))
		end
	end, vehiclePlates)
end

function GetAvailableVehicleSpawnPoint(hospital, part, partNum)
	local spawnPoints = Config.Hospitals[hospital][part][partNum].SpawnPoints
	local found, foundSpawnPoint = false, nil

	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i].coords, spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end

	if found then
		return true, foundSpawnPoint
	else
		ESX.ShowNotification(_U('garage_blocked'))
		return false
	end
end

function OpenHelicopterSpawnerMenu(hospital, partNum)
	local playerCoords = GetEntityCoords(PlayerPedId())
	ESX.PlayerData = ESX.GetPlayerData()
	local elements = {
		{label = _U('helicopter_garage'), action = 'garage'},
		{label = _U('helicopter_store'), action = 'store_garage'},
		{label = _U('helicopter_buy'), action = 'buy_helicopter'}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'helicopter_spawner', {
		css      = 'head',
		title    = _U('helicopter_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.action == 'buy_helicopter' then
			local shopCoords = Config.Hospitals[hospital].Helicopters[partNum].InsideShop
			local shopElements = {}

			local authorizedHelicopters = Config.AuthorizedHelicopters[ESX.PlayerData.job.grade_name]

			if #authorizedHelicopters > 0 then
				for k,helicopter in ipairs(authorizedHelicopters) do
					table.insert(shopElements, {
						label = ('%s - <span style="color:green;">%s</span>'):format(helicopter.label, _U('shop_item', ESX.Math.GroupDigits(helicopter.price))),
						name  = helicopter.label,
						model = helicopter.model,
						price = helicopter.price,
						type  = 'helicopter'
					})
				end
			else
				ESX.ShowNotification(_U('helicopter_notauthorized'))
				return
			end

			OpenShopMenu(shopElements, playerCoords, shopCoords)
		elseif data.current.action == 'garage' then
			local garage = {}

			ESX.TriggerServerCallback('esx_vehicleshop:retrieveJobVehicles', function(jobVehicles)
				if #jobVehicles > 0 then
					for k,v in ipairs(jobVehicles) do
						local props = json.decode(v.vehicle)
						local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(props.model))
						local label = ('%s - <span style="color:darkgoldenrod;">%s</span>: '):format(vehicleName, props.plate)

						if v.stored then
							label = label .. ('<span style="color:green;">%s</span>'):format(_U('garage_stored'))
						else
							label = label .. ('<span style="color:darkred;">%s</span>'):format(_U('garage_notstored'))
						end

						table.insert(garage, {
							label = label,
							stored = v.stored,
							model = props.model,
							vehicleProps = props
						})
					end

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'helicopter_garage', {
						css      = 'head',
						title    = _U('helicopter_garage_title'),
						align    = 'top-left',
						elements = garage
					}, function(data2, menu2)
						if data2.current.stored then
							local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(hospital, 'Helicopters', partNum)

							if foundSpawn then
								menu2.close()

								ESX.Game.SpawnVehicle(data2.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
									ESX.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)

									TriggerServerEvent('esx_vehicleshop:setJobVehicleState', data2.current.vehicleProps.plate, false)
									ESX.ShowNotification(_U('garage_released'))
								end)
							end
						else
							ESX.ShowNotification(_U('garage_notavailable'))
						end
					end, function(data2, menu2)
						menu2.close()
					end)

				else
					ESX.ShowNotification(_U('garage_empty'))
				end
			end, 'helicopter')

		elseif data.current.action == 'store_garage' then
			StoreNearbyVehicle(playerCoords)
		end

	end, function(data, menu)
		menu.close()
	end)

end

function OpenShopMenu(elements, restoreCoords, shopCoords)
	local playerPed = PlayerPedId()
	isInShopMenu = true

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop', {
		css      = 'head',
		title    = _U('vehicleshop_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_shop_confirm', {
			css      = 'head',
			title    = _U('vehicleshop_confirm', data.current.name, data.current.price),
			align    = 'top-left',
			elements = {
				{ label = _U('confirm_no'), value = 'no' },
				{ label = _U('confirm_yes'), value = 'yes' }
			}
		}, function(data2, menu2)

			if data2.current.value == 'yes' then
				local newPlate = exports['esx_vehicleshop']:GeneratePlate()
				local vehicle  = GetVehiclePedIsIn(playerPed, false)
				local props    = ESX.Game.GetVehicleProperties(vehicle)
				props.plate    = newPlate

				ESX.TriggerServerCallback('esx_ambulancejob:buyJobVehicle', function (bought)
					if bought then
						ESX.ShowNotification(_U('vehicleshop_bought', data.current.name, ESX.Math.GroupDigits(data.current.price)))

						isInShopMenu = false
						ESX.UI.Menu.CloseAll()
				
						DeleteSpawnedVehicles()
						FreezeEntityPosition(playerPed, false)
						SetEntityVisible(playerPed, true)
				
						ESX.Game.Teleport(playerPed, restoreCoords)
					else
						ESX.ShowNotification(_U('vehicleshop_money'))
						menu2.close()
					end
				end, props, data.current.type)
			else
				menu2.close()
			end

		end, function(data2, menu2)
			menu2.close()
		end)

		end, function(data, menu)
		isInShopMenu = false
		ESX.UI.Menu.CloseAll()

		DeleteSpawnedVehicles()
		FreezeEntityPosition(playerPed, false)
		SetEntityVisible(playerPed, true)

		ESX.Game.Teleport(playerPed, restoreCoords)
	end, function(data, menu)
		DeleteSpawnedVehicles()

		WaitForVehicleToLoad(data.current.model)
		ESX.Game.SpawnLocalVehicle(data.current.model, shopCoords, 0.0, function(vehicle)
			table.insert(spawnedVehicles, vehicle)
			TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
			FreezeEntityPosition(vehicle, true)
		end)
	end)

	WaitForVehicleToLoad(elements[1].model)
	ESX.Game.SpawnLocalVehicle(elements[1].model, shopCoords, 0.0, function(vehicle)
		table.insert(spawnedVehicles, vehicle)
		TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
		FreezeEntityPosition(vehicle, true)
	end)
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if isInShopMenu then
			DisableControlAction(0, 75, true)  -- Ausgangsfahrzeug deaktivieren
			DisableControlAction(27, 75, true) -- Ausgangsfahrzeug deaktivieren
		else
			Citizen.Wait(500)
		end
	end
end)

function DeleteSpawnedVehicles()
	while #spawnedVehicles > 0 do
		local vehicle = spawnedVehicles[1]
		ESX.Game.DeleteVehicle(vehicle)
		table.remove(spawnedVehicles, 1)
	end
end

function WaitForVehicleToLoad(modelHash)
	modelHash = (type(modelHash) == 'number' and modelHash or GetHashKey(modelHash))

	if not HasModelLoaded(modelHash) then
		RequestModel(modelHash)

		while not HasModelLoaded(modelHash) do
			Citizen.Wait(0)

			DisableControlAction(0, Keys['TOP'], true)
			DisableControlAction(0, Keys['DOWN'], true)
			DisableControlAction(0, Keys['LEFT'], true)
			DisableControlAction(0, Keys['RIGHT'], true)
			DisableControlAction(0, 176, true) -- ENTER key
			DisableControlAction(0, Keys['BACKSPACE'], true)

			drawLoadingText(_U('vehicleshop_awaiting_model'), 255, 255, 255, 255)
		end
	end
end

function drawLoadingText(text, red, green, blue, alpha)
	SetTextFont(4)
	SetTextScale(0.0, 0.5)
	SetTextColour(red, green, blue, alpha)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)

	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.5, 0.5)
end

function OpenPharmacyMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'pharmacy', {
		css      = 'head',
		title    = _U('pharmacy_menu_title'),
		align    = 'top-left',
		elements = {
			{label = _U('pharmacy_take', _U('medikit')), value = 'medikit'},
			{label = _U('pharmacy_take', _U('bandage')), value = 'bandage'},
			{label = _U('pharmacy_take', _U('doliprane')), value = 'comprimidos'}
		}
	}, function(data, menu)
		TriggerServerEvent('esx_ambulancejob:giveItem', data.current.value)
	end, function(data, menu)
		menu.close()
	end)
end

function WarpPedInClosestVehicle(ped)
	local coords = GetEntityCoords(ped)

	local vehicle, distance = ESX.Game.GetClosestVehicle(coords)

	if distance ~= -1 and distance <= 5.0 then
		local maxSeats, freeSeat = GetVehicleMaxNumberOfPassengers(vehicle)

		for i=maxSeats - 1, 0, -1 do
			if IsVehicleSeatFree(vehicle, i) then
				freeSeat = i
				break
			end
		end

		if freeSeat then
			TaskWarpPedIntoVehicle(ped, vehicle, freeSeat)
		end
	else
		ESX.ShowNotification(_U('no_vehicles'))
	end
end

RegisterNetEvent('esx_ambulancejob:heal')
AddEventHandler('esx_ambulancejob:heal', function(healType, quiet)
	local playerPed = PlayerPedId()
	local maxHealth = GetEntityMaxHealth(playerPed)

	if healType == 'small' then
		local health = GetEntityHealth(playerPed)
		local newHealth = math.min(maxHealth, math.floor(health + maxHealth / 8))
		SetEntityHealth(playerPed, newHealth)
	elseif healType == 'big' then
		SetEntityHealth(playerPed, maxHealth)
	end

	if not quiet then
		ESX.ShowNotification(_U('healed'))
	end
end)

