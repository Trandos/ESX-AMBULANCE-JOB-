ESX 			    			= nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent("esx_doencas:healing")
AddEventHandler("esx_doencas:healing",function(target)
	TriggerClientEvent("esx_doencas:healingPlayer",source,target)
	TriggerClientEvent("esx_doencas:getHealed",target)
end)

TriggerEvent('es:addGroupCommand', 'doenca', "superadmin", function(source, args, user)
	TriggerClientEvent('esx_doencas:doenca',args[1])
end, function(source, args, user)
	TriggerClientEvent('chatMessage', source, "SYSTEM", {255, 0, 0}, "Unzureichende Berechtigungen!")
end, {help = "Zu einem Benutzer teleportieren", params = {{name = "userid", help = "Die ID des Spielers"}}})

ESX.RegisterUsableItem('comprimidos', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	local inemOn = CountInem()
	while inemOn == nil do
		Wait(100)
	end
	-- if inemOn <= 1 then
	xPlayer.removeInventoryItem('comprimidos', 1)
	TriggerClientEvent("esx_doencas:getHealedComp",source)
	-- else
	-- 	if xPlayer.job.name == 'ambulance' then
	-- 	xPlayer.removeInventoryItem('comprimidos', 1)
	-- 	TriggerClientEvent("esx_doencas:getHealedComp",source)
	-- 	else
	-- 	TriggerClientEvent('esx:showNotification', source,"You can't take this because there is an EMS in the city!")
	-- 	end
	-- end
end)

function CountInem()

	local xPlayers = ESX.GetPlayers()

	local CopsConnected = 0

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if xPlayer.job.name == 'ambulance' then
			CopsConnected = CopsConnected + 1
		end
	end

	return CopsConnected
end