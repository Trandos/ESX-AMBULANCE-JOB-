Config                            = {}

Config.ChanceDoenca = 0.5 -- Prozentsatz 0-100% Arztes

Config.DrawDistance               = 100.0

Config.Marker                     = { type = 25, x = 1.5, y = 1.5, z = 0.5, r = 102, g = 0, b = 102, a = 100, rotate = false }

Config.ReviveReward               = 2000  -- Belohnung wiederbeleben, auf 0 setzen, wenn Sie nicht möchten, dass sie aktiviert wird
Config.AntiCombatLog              = true -- Anti-Kampf-Protokollierung aktivieren?
Config.LoadIpl                    = false -- Deaktivieren Sie diese Option, wenn Sie fivem-ipl oder andere IPL-Loader verwenden

Config.Locale                     = 'fr'

local second = 1000
local minute = 60 * second

Config.EarlyRespawnTimer          = 1 * minute  -- Zeit bis zum Respawn ist verfügbar
Config.BleedoutTimer              = 1 * minute -- Zeit bis der Spieler ausblutet

Config.EnablePlayerManagement     = true

Config.RemoveWeaponsAfterRPDeath  = true
Config.RemoveCashAfterRPDeath     = true
Config.RemoveItemsAfterRPDeath    = false

-- Lassen Sie den Spieler für das frühzeitige Respawn bezahlen, nur wenn er es sich leisten kann
Config.EarlyRespawnFine           = true
Config.EarlyRespawnFineAmount     = 500

Config.RespawnPoint = { coords = vector3(-445.69940185547,-333.57595825195,34.497142791748), heading = 86.01 }

Config.NPCJobEarnings = {min = 200, max = 400}

Config.Hospitals = {

	CentralLosSantos = {

		RespawnLS = {
			vector3(-445.69940185547,-333.57595825195,34.497142791748)
		},

		Blip = {
			coords = vector3(437.01,308.07,18.55),
			sprite = 61,
			scale  = 0.9,
			color  = 2
		},

		AmbulanceActions = {
			vector3(-429.65393066406,-321.25640869141,34.910774230957),
			Marker = { type = 3, x = 1.0, y = 1.0, z = 1.0, r = 100, g = 50, b = 100, a = 100, rotate = true }
		},

		Pharmacies = {
			vector3(-437.81796264648,-323.02526855469,34.910778045654),
			Marker = { type = 3, x = 1.0, y = 1.0, z = 1.0, r = 100, g = 50, b = 100, a = 100, rotate = true }
		},

		boss = {
			vector3(-435.52294921875,-321.80169677734,34.910816192627),
			Marker = { type = 22, x = 1.0, y = 1.0, z = 1.0, r = 100, g = 50, b = 100, a = 100, rotate = true }
		},
		
		Vehicles = {
			{  
				Spawner = vector3(-453.48226928711,-340.23913574219,34.363540649414),
				InsideShop = vector3(295.49, -605.61, 43.32),
				Marker = { type = 36, x = 1.0, y = 1.0, z = 1.0, r = 100, g = 50, b = 200, a = 100, rotate = true },
				SpawnPoints = {
					{ coords = vector3(-463.86538696289,-338.35659790039,34.500942230225), heading = 114.49, radius = 4.0 }
				}
			}	
		},
		
		Helicopters = {
			{
				Spawner = vector3(482.92, 338.11, 262.39), 
				InsideShop = vector3(365.17, -567.47, 39.25), heading = 73.76,
				Marker = { type = 34, x = 1.5, y = 1.5, z = 1.5, r = 100, g = 150, b = 150, a = 100, rotate = true },
				SpawnPoints = {
					{ coords = vector3(-463.39004516602,-335.70916748047,34.50093460083), heading = 245.84, radius = 10.0 }
				}
			}
		}


	}
};

Config.AuthorizedVehicles = {

	ambulance = {
		{ model = 'Ambulance', label = 'Ambulance', price = 1},
		{ model = 'Ambulance2', label = 'Ambulance 2', price = 1},
		{ model = 'Emscar', label = 'Ford Victoria', price = 1},
		--{ model = 'emscar2', label = 'Dodge', price = 1}
	},

	doctor = {
		{ model = 'Ambulance', label = 'Ambulance', price = 1},
		{ model = 'Ambulance2', label = 'Ambulance 2', price = 1},
		{ model = 'Emscar', label = 'Ford Victoria', price = 1},
		--{ model = 'emscar2', label = 'Dodge', price = 1}
	},

	chief_doctor = {
		{ model = 'Ambulance', label = 'Ambulance', price = 1},
		{ model = 'Ambulance2', label = 'Ambulance 2', price = 1},
		{ model = 'Emscar', label = 'Ford Victoria', price = 1},
		--{ model = 'emscar2', label = 'Dodge', price = 1}
	},

	boss = {
		{ model = 'Ambulance', label = 'Ambulance', price = 1},
		{ model = 'Ambulance2', label = 'Ambulance 2', price = 1},
		{ model = 'emscar', label = 'Ford Victoria', price = 1},
		--{ model = 'emscar2', label = 'Dodge', price = 1}
	}

}

Config.AuthorizedHelicopters = {

	ambulance = {},

	doctor = {},

	chief_doctor = {
		{ model = 'supervolito', label = 'Maverick', price = 1 }
	},

	boss = {
		{ model = 'supervolito', label = 'Maverick', price = 1 }
	}

}

Config.JobLocations = {
	--{x = 1163.50, y = -1536.22, z = 39.00},
	--{x = 290.18, y = -1440.89, z = 29.56},
	--{x = -497.59, y = -336.16, z = 34.10},
	{x = -464.244, y = -338.676, z = 33.600}
} 