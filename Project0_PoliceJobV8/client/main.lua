local CurrentActionData, handcuffTimer, dragStatus, blipsCops, currentTask = {}, {}, {}, {}, {}
local HasAlreadyEnteredMarker, isDead, isHandcuffed, hasAlreadyJoined, playerInService = false, false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg
dragStatus.isDragged, isInShopMenu = false, false
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)


function Message()

	Citizen.CreateThread(function()

    while messagenotfinish do

    		Citizen.Wait(1)



			DisplayOnscreenKeyboard(1, "FMMC_MPM_NA", "", "", "", "", "", 30)

		    while (UpdateOnscreenKeyboard() == 0) do

		        DisableAllControlActions(0);

		       Citizen.Wait(1)

		    end

		    if (GetOnscreenKeyboardResult()) then

		        local result = GetOnscreenKeyboardResult()

		        messagenotfinish = false

		       TriggerServerEvent('esx_policejob:annonce',result)

		        

		    end





		end

	end)

	

end

function cleanPlayer(playerPed)
	SetPedArmour(playerPed, 0)
	ClearPedBloodDamage(playerPed)
	ResetPedVisibleDamage(playerPed)
	ClearPedLastWeaponDamage(playerPed)
	ResetPedMovementClipset(playerPed, 0)
end

function setUniform(uniform, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject

		if skin.sex == 0 then
			uniformObject = Config.Uniforms[uniform].male
		else
			uniformObject = Config.Uniforms[uniform].female
		end

		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)

			if uniform == 'bullet_wear' then
				SetPedArmour(playerPed, 100)
			end
		else
			ESX.ShowNotification(_U('no_outfit'))
		end
	end)
end

function OpenCloakroomMenu()
	local playerPed = PlayerPedId()
	local grade = ESX.PlayerData.job.grade_name

	local elements = {
		{label = _U('citizen_wear'), value = 'citizen_wear'},
		{label = _U('bullet_wear'), uniform = 'bullet_wear'},
		{label = _U('gilet_wear'), uniform = 'gilet_wear'},
		{label = _U('police_wear'), uniform = grade}
	}

	if Config.EnableCustomPeds then
		for k,v in ipairs(Config.CustomPeds.shared) do
			table.insert(elements, {label = v.label, value = 'freemode_ped', maleModel = v.maleModel, femaleModel = v.femaleModel})
		end

		for k,v in ipairs(Config.CustomPeds[grade]) do
			table.insert(elements, {label = v.label, value = 'freemode_ped', maleModel = v.maleModel, femaleModel = v.femaleModel})
		end
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('cloakroom'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		cleanPlayer(playerPed)

		if data.current.value == 'citizen_wear' then
			if Config.EnableNonFreemodePeds then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					local isMale = skin.sex == 0

					TriggerEvent('skinchanger:loadDefaultModel', isMale, function()
						ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
							TriggerEvent('skinchanger:loadSkin', skin)
							TriggerEvent('esx:restoreLoadout')
						end)
					end)

				end)
			else
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
					TriggerEvent('skinchanger:loadSkin', skin)
				end)
			end

			if Config.EnableESXService then
				ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
					if isInService then
						playerInService = false

						local notification = {
							title    = _U('service_anonunce'),
							subject  = '',
							msg      = _U('service_out_announce', GetPlayerName(PlayerId())),
							iconType = 1
						}

						TriggerServerEvent('esx_service:notifyAllInService', notification, 'police')

						TriggerServerEvent('esx_service:disableService', 'police')
						TriggerEvent('esx_policejob:updateBlip')
						ESX.ShowNotification(_U('service_out'))
					end
				end, 'police')
			end
		end

		if Config.EnableESXService and data.current.value ~= 'citizen_wear' then
			local awaitService

			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if not isInService then

					ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
						if not canTakeService then
							ESX.ShowNotification(_U('service_max', inServiceCount, maxInService))
						else
							awaitService = true
							playerInService = true

							local notification = {
								title    = _U('service_anonunce'),
								subject  = '',
								msg      = _U('service_in_announce', GetPlayerName(PlayerId())),
								iconType = 1
							}

							TriggerServerEvent('esx_service:notifyAllInService', notification, 'police')
							TriggerEvent('esx_policejob:updateBlip')
							ESX.ShowNotification(_U('service_in'))
						end
					end, 'police')

				else
					awaitService = true
				end
			end, 'police')

			while awaitService == nil do
				Citizen.Wait(5)
			end

			-- if we couldn't enter service don't let the player get changed
			if not awaitService then
				return
			end
		end

		if data.current.uniform then
			setUniform(data.current.uniform, playerPed)
		elseif data.current.value == 'freemode_ped' then
			local modelHash

			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
				if skin.sex == 0 then
					modelHash = GetHashKey(data.current.maleModel)
				else
					modelHash = GetHashKey(data.current.femaleModel)
				end

				ESX.Streaming.RequestModel(modelHash, function()
					SetPlayerModel(PlayerId(), modelHash)
					SetModelAsNoLongerNeeded(modelHash)
					SetPedDefaultComponentVariation(PlayerPedId())

					TriggerEvent('esx:restoreLoadout')
				end)
			end)
		end
	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenArmoryMenu(station)
	local elements = {
		--{label = _U('buy_weapons'), value = 'buy_weapons'}
	}

	if Config.EnableArmoryManagement then
		--table.insert(elements, {label = _U('get_weapon'),     value = 'get_weapon'})
		--table.insert(elements, {label = _U('put_weapon'),     value = 'put_weapon'})
		table.insert(elements, {label = _U('remove_object'),  value = 'get_stock'})
		table.insert(elements, {label = _U('deposit_object'), value = 'put_stock'})
	end

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory', {
		title    = _U('armory'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)

		if data.current.value == 'get_weapon' then
			OpenGetWeaponMenu()
		elseif data.current.value == 'put_weapon' then
			OpenPutWeaponMenu()
		elseif data.current.value == 'buy_weapons' then
			OpenBuyWeaponsMenu()
		elseif data.current.value == 'put_stock' then
			OpenPutStocksMenu()
		elseif data.current.value == 'get_stock' then
			OpenGetStocksMenu()
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	end)
end

function OpenVehicleSpawnerMenu(type, station, part, partNum)
	local playerCoords = GetEntityCoords(PlayerPedId())
	PlayerData = ESX.GetPlayerData()
	local elements = {
		{label = _U('garage_storeditem'), action = 'garage'},
		{label = _U('garage_storeitem'), action = 'store_garage'},
		{label = _U('garage'), action = 'vehicle_menu'}
	}

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle', {
		css      = 'sppolice',
		title    = _U('garage_title'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.action == 'buy_vehicle' then
			local shopElements, shopCoords = {}

			if type == 'car' then
				shopCoords = Config.sppoliceStations[station].Vehicles[partNum].InsideShop
				local authorizedVehicles = Config.AuthorizedVehicles[PlayerData.job.grade_name]

				if #Config.AuthorizedVehicles['Shared'] > 0 then
					for k,vehicle in ipairs(Config.AuthorizedVehicles['Shared']) do
						table.insert(shopElements, {
							label = ('%s - <span style="color:green;">%s</span>'):format(vehicle.label, _U('shop_item', ESX.Math.GroupDigits(vehicle.price))),
							name  = vehicle.label,
							model = vehicle.model,
							price = vehicle.price,
							type  = 'car'
						})
					end
				end

				if #authorizedVehicles > 0 then
					for k,vehicle in ipairs(authorizedVehicles) do
						table.insert(shopElements, {
							label = ('%s - <span style="color:green;">%s</span>'):format(vehicle.label, _U('shop_item', ESX.Math.GroupDigits(vehicle.price))),
							name  = vehicle.label,
							model = vehicle.model,
							price = vehicle.price,
							type  = 'car'
						})
					end
				else
					if #Config.AuthorizedVehicles['Shared'] == 0 then
						return
					end
				end
			elseif type == 'helicopter' then
				shopCoords = Config.sppoliceStations[station].Helicopters[partNum].InsideShop
				local authorizedHelicopters = Config.AuthorizedHelicopters[PlayerData.job.grade_name]

				if #authorizedHelicopters > 0 then
					for k,vehicle in ipairs(authorizedHelicopters) do
						table.insert(shopElements, {
							label = ('%s - <span style="color:green;">%s</span>'):format(vehicle.label, _U('shop_item', ESX.Math.GroupDigits(vehicle.price))),
							name  = vehicle.label,
							model = vehicle.model,
							price = vehicle.price,
							livery = vehicle.livery or nil,
							type  = 'helicopter'
						})
					end
				else
					ESX.ShowNotification(_U('helicopter_notauthorized'))
					return
				end
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

					ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_garage', {
						css      = 'sppolice',
						title    = _U('garage_title'),
						align    = 'top-left',
						elements = garage
					}, function(data2, menu2)
						if data2.current.stored then
							local foundSpawn, spawnPoint = GetAvailableVehicleSpawnPoint(station, part, partNum)
							if foundSpawn then
								menu2.close()

								ESX.Game.SpawnVehicle(data2.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
									ESX.Game.SetVehicleProperties(vehicle, data2.current.vehicleProps)
									SetVehicleEnginePowerMultiplier(vehicle, 2.0 * 15.0)

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
			end, type)
		elseif data.current.action == 'menu_vehicle_spawner' then
			StoreNearbyVehicle(playerCoords)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenPoliceActionsMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'police_actions', {
		title    = 'Policia',
		align    = 'top-left',
		elements = {
			{label = '<span style="color:#A349D6;">✔️ Estado del agente', value = 'status'},
			{label = _U('citizen_interaction'), value = 'citizen_interaction'},
			{label = _U('vehicle_interaction'), value = 'vehicle_interaction'},
			{label = '<span style="color:#A349D6;">⚠️ Solicitar refuerzos', value = 'renfort'},
			{label = '<span style="color:#A349D6;">🚓 Radar móvil', value = 'rd_mobile'},
			{label = '<span style="color:#A349D6;">🐶 Menú AK49', value = 'dog'},
			{label = '<span style="color:#A349D6;">⛓ Meter en prision', 	value = 'jail_menu'},
			{label = _U('object_spawner'), 	value = 'object_spawner'},
			{label = '<span style="color:#A349D6;">💬 Anunciar', 	value = 'announce'},

	}}, function(data, menu)

			if data.current.value == 'option' then
				TriggerEvent('pis:spawnTow')	
				menu.close()
			end

			if data.current.value == 'dog' then
				TriggerEvent('esx_policedog:openMenu')	
				menu.close()
			end

			if data.current.value == 'jail_menu' then
				TriggerEvent("esx-qalle-jail:openJailMenu")
			end

			if data.current.value == 'rd_mobile' then
            	TriggerEvent('police:POLICE_radar')
			end

			if data.current.value == 'announce' then

				messagenotfinish = true
			
			  Message()
			
			end

			if data.current.value == 'lspd' then
				TriggerEvent('esx_braceletgps:acitvergps')	
				menu.close()
			end
			

		if data.current.value == 'polo_menu' then
			local elements = {
				{label = '---------------- Interacciones de vehículos ----------------', value = 'none'},
				{label = '| <span style="color:#ffc800;">La persona te seguirá|', value = 'option3'},
				{label = '| <span style="color:#1ED4BE;">La persona cambiará de lugar|', value = 'option2'},
				{label = '| <span style="color:#CBDA17;">Ponlo de nuevo en el asiento del conductor|', value = 'option8'},
				{label = '| <span style="color:#D3823F;">Buscar el coche|', value = 'option11'},
				{label = '| <span style="color:#6FEE11;">Que nadie se vaya|', value = 'option9'},
				{label = '---------------- Intéractions Ciudadanos ----------------', value = 'none'},
				{label = '| <span style="color:#9E11EE;">Prueba de alcohol|', value = 'optio13'},
				{label = '| <span style="color:#EE11B5;">Mira ese uso de drogas|', value = 'optio14'},
				{label = '| <span style="color:#EE1111;">Cuida tu consumo de drogas|', value = 'option6'},
				{label = '| <span style="color:#2CA3EC;">Demenota a la persona|', value = 'optio17'},
				{label = '| <span style="color:#E87B85;">Sostenga al sospechoso/a|', value = 'optio16'},
				{label = '| <span style="color:#EE2211;">¡Llame a un agente para que la meta en la cárcel!|', value = 'optio15'}
			}

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'polo_menu', {
				title    = _U('polo_menu'),
				align    = 'top-left',
				elements = elements
			}, function(data, menu)
			
			if data.current.value == 'option2' then
				TriggerEvent('pis:mimic')	
				menu.close()
			end

			if data.current.value == 'option3' then
				TriggerEvent('pis:follow')	
				menu.close()
			end

			if data.current.value == 'option6' then
				TriggerEvent('ldt:cop')	
				menu.close()
        	end

			if data.current.value == 'option8' then
				TriggerEvent('po:unmimic')	
				menu.close()
			end

			if data.current.value == 'option9' then
				TriggerEvent('po:follow')	
				menu.close()
			end

			if data.current.value == 'option11' then
				TriggerEvent('pis:search')	
				menu.close()
			end

        	if data.current.value == 'option13' then
				TriggerEvent('pis:drug')	
				menu.close()
			end

			if data.current.value == 'optio14' then
				TriggerEvent('pis:breath')	
				menu.close()
			end

			if data.current.value == 'optio15' then
				TriggerEvent('pis:arr:pt')	
				menu.close()
			end

			if data.current.value == 'optio16' then
				TriggerEvent('pis:arr:grab')	
				menu.close()
			end

			if data.current.value == 'optio17' then
				TriggerEvent('pis:arr:handcuff')	
				menu.close()
			end

	end, function(data, menu)
		menu.close()
	end)
end

		if data.current.value == 'polo_menu2' then
			local elements = {
				{label = '<span style="color:yellow;"> | <span style="color:#965AD7;">Objetivo 1<span style="color:yellow;"> |', value = 'optio1'},
				{label = '<span style="color:yellow;"> | <span style="color:#965AD7;">Empezar a entrenar<span style="color:yellow;"> |', value = 'optio2'},
				{label = '<span style="color:yellow;"> | <span style="color:#965AD7;">Compañero de equipo marino<span style="color:yellow;"> |', value = 'optio3'},
				{label = '<span style="color:yellow;"> | <span style="color:#965AD7;">Asegurar el perímetro<span style="color:yellow;"> |', value = 'optio4'},
				{label = '<span style="color:yellow;"> | <span style="color:#965AD7;">Despide a tu compañero de equipo<span style="color:yellow;"> |', value = 'optio5'}
			}

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'polo_menu2', {
				title    = _U('polo_menu2'),
				align    = 'top-left',
				elements = elements
			}, function(data, menu)

			if data.current.value == 'optio1' then
				TriggerEvent('pis:crazy:spawn')	
				menu.close()
			end

			if data.current.value == 'optio2' then
				TriggerEvent('pis:shots')	
				menu.close()
			end

			if data.current.value == 'optio3' then
				TriggerEvent('pis:weapon:spawn')	
				menu.close()
			end

			if data.current.value == 'optio4' then
				TriggerEvent('pis:weapon')	
				menu.close()
			end

			if data.current.value == 'optio5' then
				TriggerEvent('pis:code4')	
				menu.close()
			end
	end, function(data, menu)
		menu.close()
	end)
end

		if data.current.value == 'polo_menu4' then
			local elements = {
			{label = '<span style="color:#08732A;">📣 Annonce : CODIGO VERDE',     value = 'police_annonce1'},
			{label = '<span style="color:#F49503;">📣 Annonce : CODIGO NARANJA',     value = 'police_annonce2'},
			{label = '<span style="color:#F40E03;">📣 Annonce : CODIGO ROJO',     value = 'police_ouvert'}
		}

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'polo_menu4', {
				title    = 'Passer une annonce',
				align    = 'top-left',
				elements = elements
			}, function(data, menu)

		if data.current.value == 'police_ouvert' then
			TriggerServerEvent('AnnouncePoliceOuvert')
		end
		if data.current.value == 'police_annonce1' then
			TriggerServerEvent('AnnouncePoliceAnnonce1')
		end
		if data.current.value == 'police_annonce2' then
			TriggerServerEvent('AnnouncePoliceAnnonce2')
		end

	end, function(data, menu)
		menu.close()
	end)
end

		if data.current.value == 'polo_menu3' then
			local elements = {
				{label = '<span style="color:#A349D6;">🔊 Hablar radio', value = 'cas1'},
				{label = '<span style="color:#A349D6;">👋 Saludar', value = 'cas3'},
				{label = '<span style="color:#A349D6;">🔧 Mira el motor', value = 'cas4'},
				{label = '<span style="color:#A349D6;">📝 Bloc de notas', value = 'cas5'}
			}

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'polo_menu3', {
				title    = 'Animations',
				align    = 'top-left',
				elements = elements
			}, function(data, menu)

			if data.current.value == 'cas1' then
				TriggerEvent('radio')	
				menu.close()
			end

			if data.current.value == 'cas3' then
				TriggerEvent('pis:hello')	
				menu.close()
        	end

			if data.current.value == 'cas4' then
				TriggerEvent('search')	
				menu.close()
			end

			if data.current.value == 'cas5' then
				TriggerEvent('ticket')	
				menu.close()
			end
	end, function(data, menu)
		menu.close()
	end)
end

		if data.current.value == 'polo_menu5' then
			local elements = {
			{label = '<span style="color:#66ff00;">Saque el escudo de la policía', value = 'spawn_bouclier'},
			{label = '<span style="color:red;">Escudo de policía Ranger', value = 'remove_bouclier'},
			{label = '<span style="color:#66ff00;">Saca el escudo de swat', value = 'spawn_bouclier2'},
			{label = '<span style="color:red;">Escudo de Swat', value = 'remove_bouclier2'}
		  }

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'polo_menu5', {
				title    = _U('polo_menu5'),
				align    = 'top-left',
				elements = elements
			}, function(data, menu)

        if data.current.value == 'spawn_bouclier' then
            EnableShield()
        elseif data.current.value == 'remove_bouclier' then
            DisableShield()
		elseif data.current.value == 'spawn_bouclier2' then
            EnableShield2()
        elseif data.current.value == 'remove_bouclier2' then
            DisableShield2()
		end
	end, function(data, menu)
		menu.close()
	end)
end

local shieldActive = false
local shieldEntity = nil
local hadPistol = false
local shieldActive2 = false
local shieldEntity2 = nil
local hadPistol2 = false

local animDict = "combat@gestures@gang@pistol_1h@beckon"
local animName = "0"
local animDict2 = "combat@gestures@gang@pistol_1h@beckon"
local animName2 = "0"

local prop = "prop_riot_shield"
local pistol = GetHashKey("WEAPON_PISTOL")

local prop2 = "prop_ballistic_shield"
local pistol2 = GetHashKey("WEAPON_PISTOL")

function EnableShield()
    shieldActive = true
    local ped = GetPlayerPed(-1)
    local pedPos = GetEntityCoords(ped, false)

    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
    end

    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, (2 + 16 + 32), 0.0, 0, 0, 0)

    RequestModel(GetHashKey(prop))
    while not HasModelLoaded(GetHashKey(prop)) do
        Citizen.Wait(100)
    end

    local shield = CreateObject(GetHashKey(prop), pedPos.x, pedPos.y, pedPos.z, 1, 1, 1)
    shieldEntity = shield
    AttachEntityToEntity(shieldEntity, ped, GetEntityBoneIndexByName(ped, "IK_L_Hand"), 0.0, -0.05, -0.10, -30.0, 180.0, 40.0, 0, 0, 1, 0, 0, 1)
    SetWeaponAnimationOverride(ped, GetHashKey("Gang1H"))

    if HasPedGotWeapon(ped, pistol, 0) or GetSelectedPedWeapon(ped) == pistol then
        SetCurrentPedWeapon(ped, pistol, 1)
        hadPistol = true
    else
        --GiveWeaponToPed(ped, pistol, 300, 0, 1)
        SetCurrentPedWeapon(ped, pistol, 1)
        hadPistol = false
    end
    SetEnableHandcuffs(ped, true)
end

function EnableShield2()
    shieldActive2 = true
    local ped = GetPlayerPed(-1)
    local pedPos = GetEntityCoords(ped, false)

    RequestAnimDict(animDict2)
    while not HasAnimDictLoaded(animDict2) do
        Citizen.Wait(100)
    end

    TaskPlayAnim(ped, animDict2, animName2, 8.0, -8.0, -1, (2 + 16 + 32), 0.0, 0, 0, 0)

    RequestModel(GetHashKey(prop2))
    while not HasModelLoaded(GetHashKey(prop2)) do
        Citizen.Wait(100)
    end

    local shield = CreateObject(GetHashKey(prop2), pedPos.x, pedPos.y, pedPos.z, 1, 1, 1)
    shieldEntity2 = shield
    AttachEntityToEntity(shieldEntity2, ped, GetEntityBoneIndexByName(ped, "IK_L_Hand"), 0.0, -0.05, -0.10, -30.0, 180.0, 40.0, 0, 0, 1, 0, 0, 1)
    SetWeaponAnimationOverride(ped, GetHashKey("Gang1H"))

    if HasPedGotWeapon(ped, pistol2, 0) or GetSelectedPedWeapon(ped) == pistol2 then
        SetCurrentPedWeapon(ped, pistol2, 1)
        hadPistol2 = true
    else
        --GiveWeaponToPed(ped, pistol, 300, 0, 1)
        SetCurrentPedWeapon(ped, pistol2, 1)
        hadPistol2 = false
    end
    SetEnableHandcuffs(ped, true)
end

function DisableShield()
    local ped = GetPlayerPed(-1)
    DeleteEntity(shieldEntity)
    ClearPedTasksImmediately(ped)
    SetWeaponAnimationOverride(ped, GetHashKey("Default"))

    if not hadPistol then
        RemoveWeaponFromPed(ped, pistol)
    end
    SetEnableHandcuffs(ped, false)
    hadPistol = false
    shieldActive = false
end

Citizen.CreateThread(function()
    while true do
        if shieldActive then
            local ped = GetPlayerPed(-1)
            if not IsEntityPlayingAnim(ped, animDict, animName, 1) then
                RequestAnimDict(animDict)
                while not HasAnimDictLoaded(animDict) do
                    Citizen.Wait(100)
                end

                TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, (2 + 16 + 32), 0.0, 0, 0, 0)
            end
        end
        Citizen.Wait(500)
    end
end)

function DisableShield2()
    local ped = GetPlayerPed(-1)
    DeleteEntity(shieldEntity2)
    ClearPedTasksImmediately(ped)
    SetWeaponAnimationOverride(ped, GetHashKey("Default"))

    if not hadPistol2 then
        RemoveWeaponFromPed(ped, pistol2)
    end
    SetEnableHandcuffs(ped, false)
    hadPistol2 = false
    shieldActive2 = false
end

Citizen.CreateThread(function()
    while true do
        if shieldActive2 then
            local ped = GetPlayerPed(-1)
            if not IsEntityPlayingAnim(ped, animDict2, animName2, 1) then
                RequestAnimDict(animDict2)
                while not HasAnimDictLoaded(animDict2) do
                    Citizen.Wait(100)
                end

                TaskPlayAnim(ped, animDict2, animName2, 8.0, -8.0, -1, (2 + 16 + 32), 0.0, 0, 0, 0)
            end
        end
        Citizen.Wait(500)
    end
end)

        if data.current.value == 'gang_menu' then 
      local elements  = {}

      local elements = {
        {label = '<span style="color:green;">Motín de seguridad', value = 'spawn'}, 
        {label = '<span style="color:green;">de seguridad', value = 'spawn2'},  
    	{label = '<span style="color:green;">Camion de seguridad', value = 'spawn3'},  
    	{label = '<span style="color:green;">Bicicleta de seguridad', value = 'spawn4'},
    	--{label = '<span style="color:green;">Sécurité Hélico (1)', value = 'spawn5'},
       -- {label = '🔫 Donne des armes', value = 'giveweapons'},
        {label = '<span style="color:orange;">🗡️ Ataca al jugador más cercano', value = 'playerattack'},    
        {label = '<span style="color:orange;">🔊  Sígame', value = 'follow'},
        {label = '<span style="color:red;">🗑️ Eliminar', value = 'delete'},
      }
      
      ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'gang_menu', {
        css      = 'ballas',
        title    = '🚔 Escorte Policiere 🚔',
        align    = 'top-left',
        elements = elements
      }, function(data2, menu2)

        local action = data2.current.value

        if action == 'spawn' then
          SpawnVehicle1()
        elseif action == 'spawn2' then
          SpawnVehicle2() 
        elseif action == 'spawn3' then
          SpawnVehicle3()  
        elseif action == 'spawn4' then
          SpawnVehicle4()
        elseif action == 'spawn5' then
          SpawnVehicle5()
        elseif action  == 'giveweapons' then
          GiveWeaponToPed(chasePed, config.weapon1, 250, false, true)
          GiveWeaponToPed(chasePed2, config.weapon2, 250, false, true)
          GiveWeaponToPed(chasePed3, config.weapon3, 250, false, true)
          GiveWeaponToPed(chasePed4, config.weapon4, 250, false, true)
        elseif action == 'playerattack' then
          closestPlayer = ESX.Game.GetClosestPlayer()
          target = GetPlayerPed(closestPlayer)
          TaskShootAtEntity(chasePed, target, 60, 0xD6FF6D61);
          TaskCombatPed(chasePed, target, 0, 16)
          SetEntityAsMissionEntity(chasePed, true, true)
          SetPedHearingRange(chasePed, 15.0)
          SetPedSeeingRange(chasePed, 15.0)
          SetPedAlertness(chasePed, 15.0)
          SetPedFleeAttributes(chasePed, 0, 0)
          SetPedCombatAttributes(chasePed, 46, true)
          SetPedFleeAttributes(chasePed, 0, 0)
          TaskShootAtEntity(chasePed2, target, 60, 0xD6FF6D61);
          TaskCombatPed(chasePed2, target, 0, 16)
          SetEntityAsMissionEntity(chasePed2, true, true)
          SetPedHearingRange(chasePed2, 15.0)
          SetPedSeeingRange(chasePed2, 15.0)
          SetPedAlertness(chasePed2, 15.0)
          SetPedFleeAttributes(chasePed2, 0, 0)
          SetPedCombatAttributes(chasePed2, 46, true)
          SetPedFleeAttributes(chasePed2, 0, 0) 
          TaskShootAtEntity(chasePed3, target, 60, 0xD6FF6D61);
          TaskCombatPed(chasePed3, target, 0, 16)
          SetEntityAsMissionEntity(chasePed3, true, true)
          SetPedHearingRange(chasePed3, 15.0)
          SetPedSeeingRange(chasePed3, 15.0)
          SetPedAlertness(chasePed3, 15.0)
          SetPedFleeAttributes(chasePed3, 0, 0)
          SetPedCombatAttributes(chasePed3, 46, true)
          SetPedFleeAttributes(chasePed3, 0, 0)  
          TaskShootAtEntity(chasePed4, target, 60, 0xD6FF6D61);
          TaskCombatPed(chasePed4, target, 0, 16)
          SetEntityAsMissionEntity(chasePed4, true, true)
          SetPedHearingRange(chasePed4, 15.0)
          SetPedSeeingRange(chasePed4, 15.0)
          SetPedAlertness(chasePed4, 15.0)
          SetPedFleeAttributes(chasePed4, 0, 0)
          SetPedCombatAttributes(chasePed4, 46, true)
          SetPedFleeAttributes(chasePed4, 0, 0)   
        elseif action  == 'fix' then
          SetVehicleFixed(chaseVehicle)
          SetVehicleFixed(chaseVehicle2)
          SetVehicleUndriveable(chaseVehicle, false)
          SetVehicleUndriveable(chaseVehicle2, false)
        elseif action ==  'delete' then
          DeleteVehicle(chaseVehicle)
          DeletePed(chasePed)
          DeleteVehicle(chaseVehicle2)
          DeletePed(chasePed2)
          DeleteVehicle(chaseVehicle3)
          DeletePed(chasePed3)
          DeleteVehicle(chaseVehicle4)
          DeletePed(chasePed4)
          DeleteVehicle(chaseVehicle5)
          DeletePed(chasePed5)
        elseif action ==  'follow' then
          local playerPed = PlayerPedId()
          TaskVehicleFollow(chasePed, chaseVehicle, playerPed, 50.0, 1, 5)
          TaskVehicleFollow(chasePed2, chaseVehicle2, playerPed, 50.0, 1, 5)
          TaskVehicleFollow(chasePed3, chaseVehicle3, playerPed, 50.0, 1, 5)
          TaskVehicleFollow(chasePed4, chaseVehicle4, playerPed, 50.0, 1, 5)
          TaskVehicleFollow(chasePed5, chaseVehicle5, playerPed, 50.0, 1, 5)
          PlayAmbientSpeech1(chasePed, "Chat_Resp", "SPEECH_PARAMS_FORCE", 1)
          PlayAmbientSpeech1(chasePed2, "Chat_Resp", "SPEECH_PARAMS_FORCE", 1)
          PlayAmbientSpeech1(chasePed3, "Chat_Resp", "SPEECH_PARAMS_FORCE", 1)
          PlayAmbientSpeech1(chasePed4, "Chat_Resp", "SPEECH_PARAMS_FORCE", 1)
          PlayAmbientSpeech1(chasePed5, "Chat_Resp", "SPEECH_PARAMS_FORCE", 1)
        elseif action ==  'exit' then
          menu.close()
            end

          end,
          function(data2, menu2)
            menu2.close()
          end
        )
      end

		if data.current.value == 'citizen_interaction' then
			local elements = {
				{label = _U('id_card'), value = 'identity_card'},
				{label = _U('search'), value = 'body_search'},
				{label = _U('handcuff'), value = 'handcuff'},
				{label = _U('drag'), value = 'drag'},
				{label = _U('put_in_vehicle'), value = 'put_in_vehicle'},
				{label = _U('out_the_vehicle'), value = 'out_the_vehicle'},
				{label = _U('fine'), value = 'fine'},
				{label = _U('unpaid_bills'), value = 'unpaid_bills'}
			}

			if Config.EnableLicenses then
				table.insert(elements, {label = _U('license_check'), value = 'license'})
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				title    = 'Interacción Ciudadana',
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)

				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
				if closestPlayer ~= -1 and closestDistance <= 3.0 then
					local action = data2.current.value

					if action == 'identity_card' then
						OpenIdentityCardMenu(closestPlayer)
					elseif action == 'body_search' then
						TriggerServerEvent('esx_policejob:message', GetPlayerServerId(closestPlayer), _U('being_searched'))
						OpenBodySearchMenu(closestPlayer)
					elseif action == 'handcuff' then
						TriggerServerEvent('esx_policejob:handcuff', GetPlayerServerId(closestPlayer))
					elseif action == 'drag' then
						TriggerServerEvent('esx_policejob:drag', GetPlayerServerId(closestPlayer))
					elseif action == 'put_in_vehicle' then
						TriggerServerEvent('esx_policejob:putInVehicle', GetPlayerServerId(closestPlayer))
					elseif action == 'out_the_vehicle' then
						TriggerServerEvent('esx_policejob:OutVehicle', GetPlayerServerId(closestPlayer))
					elseif action == 'fine' then
						OpenFineMenu(closestPlayer)
					elseif action == 'license' then
						ShowPlayerLicense(closestPlayer)
					elseif action == 'unpaid_bills' then
						OpenUnpaidBillsMenu(closestPlayer)
					end
				else
					ESX.ShowNotification(_U('no_players_nearby'))
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'status' then
			local elements  = {}

			local elements = {
				{label = '<span style="color:green;">Dentro<span style="color:white;"> De servicio ', value = 'prise'},
				{label = '<span style="color:green;">Pausa<span style="color:white;"> Servicio  ', value = 'pause'},
				{label = '<span style="color:green;">Esperando<span style="color:gray;">, Esperando asignacion ', value = 'standby'},
				{label = '<span style="color:red;">Fin<span style="color:white;"> Fin del servicio ', value = 'fin'},
				{label = '<span style="color:orange;">Control<span style="color:gray;"> Control / rutinario ', value = 'control'},
				{label = '<span style="color:orange;">Rechazar<span style="color:gray;"> Ordenes / golpear o correr', value = 'refus'},
				{label = '<span style="color:orange;">Crimen<span style="color:gray;"> En progreso / seguimiento en progreso ', value = 'crime'}
			}

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'status', {
				css      = 'police',
				title    = 'Estado del Agente',
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local action = data2.current.value

				if action == 'prise' then
					local info = 'prise'
					TriggerServerEvent('police:PriseEtFinservice', info)
				elseif action == 'fin' then
					local info = 'fin'
					TriggerServerEvent('police:PriseEtFinservice', info)
				elseif action == 'pause' then
					local info = 'pause'
					TriggerServerEvent('police:PriseEtFinservice', info)
				elseif action == 'standby' then
					local info = 'standby'
					TriggerServerEvent('police:PriseEtFinservice', info)
				elseif action == 'control' then
					local info = 'control'
					TriggerServerEvent('police:PriseEtFinservice', info)
				elseif action == 'refus' then
					local info = 'refus'
					TriggerServerEvent('police:PriseEtFinservice', info)
				elseif action == 'crime' then
					local info = 'crime'
					TriggerServerEvent('police:PriseEtFinservice', info)
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'camenu' then	
			local elements  = {}

			local elements = {
				{label = '🎥 : Store Camera 1', value = 'cam1'},
				{label = '🎥 : Store Camera 2', value = 'cam2'},
				{label = '🎥 : Store Camera 3', value = 'cam3'},
				{label = '🎥 : Store Camera 4', value = 'cam4'},
				{label = '🎥 : Store Camera 5', value = 'cam5'},
				{label = '🎥 : Store Camera 6', value = 'cam6'},
				{label = '🎥 : Store Camera 7', value = 'cam7'},
				{label = '🎥 : Store Camera 8', value = 'cam8'},
				{label = '🎥 : Store Camera 9', value = 'cam9'},
				{label = '🎥 : Store Camera 10', value = 'cam10'},
				{label = '🎥 : Store Camera 11', value = 'cam11'},
				{label = '🎥 : Store Camera 12', value = 'cam12'},
				{label = '🎥 : Store Camera 13', value = 'cam13'},				
				{label = '🎥 : Store Camera 14', value = 'cam14'},
				{label = '🎥 : Store Camera 15', value = 'cam15'},
				{label = '🎥 : Store Camera 16', value = 'cam16'},
				{label = '🎥 : Store Camera 17', value = 'cam17'},
				{label = '🎥 : Store Camera 18', value = 'cam18'},
				{label = '🎥 : Camera Power', value = 'cam19'},
				{label = '🎥 : Camera Jail Front', value = 'cam20'},
				{label = '🎥 : Camera Jail Prisoner Drop Off', value = 'cam21'},
				{label = '🎥 : Camera Jewelry Store', value = 'cam22'},
				{label = '🎥 : Camera Paleto Bank Outside', value = 'cam23'},
				{label = '🎥 : Camera Main Bank 1', value = 'cam24'},
				{label = '🎥 : Camera Ballas', value = 'cam25'},
				{label = '🎥 : Camera Famillies', value = 'cam26'},
				{label = '🎥 : Camera Vagos', value = 'cam27'},
				{label = '🎥 : Cardealer Outside', value = 'cam28'},	
				{label = '🎥 : Cardealer interior', value = 'cam29'},	
				{label = '🎥 : Pôle emploie Interior', value = 'cam30'},	
				{label = '🎥 : Bennys interior', value = 'cam31'},	
				{label = '🎥 : Bennys Outside', value = 'cam32'},	
				{label = '🎥 : Unicorn Intérior', value = 'cam33'},	
				{label = '🎥 : Unicorn Outside', value = 'cam34'},	
				{label = '🎥 : Central Parking', value = 'cam35'},	
				{label = '🎥 : Armurie Intérior', value = 'cam36'},	
				{label = '🎥 : Armurie Outside', value = 'cam37'},	
				{label = '🎥 : EMS Outside', value = 'cam38'},	
				{label = '🎥 : EMS interior', value = 'cam39'},	
				{label = '🎥 : Police Outside', value = 'cam40'},	
				{label = '🎥 : Police Intérior', value = 'cam41'},	
				{label = '🎥 : Parking Police', value = 'cam42'},			
				{label = '🎥 : Funfair', value = 'cam43'},
				{label = '🎥 : Funfair 2', value = 'cam44'},
				{label = '🎥 : Bahamas Outside', value = 'cam45'},
				{label = '🎥 : Bahamas Intérior', value = 'cam46'},
				{label = '🎥 : Mirror Park 1', value = 'cam47'},
				{label = '🎥 : Mirror Park 2', value = 'cam48'},
				{label = '🎥 : Mirror Park 3', value = 'cam49'},
			}
			
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'camenu', {
                css      = 'police',
				title    = '🎥 Caméra Menu',
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local action = data2.current.value

				if action == 'cam1' then
					TriggerEvent('cctv:camera', 1)
				elseif action == 'cam2' then
					TriggerEvent('cctv:camera', 2)
				elseif action == 'cam3' then
					TriggerEvent('cctv:camera', 3)
				elseif action == 'cam4' then
					TriggerEvent('cctv:camera', 4)
				elseif action == 'cam5' then
					TriggerEvent('cctv:camera', 5)
				elseif action == 'cam6' then
					TriggerEvent('cctv:camera', 6)
				elseif action == 'cam7' then
					TriggerEvent('cctv:camera', 7)
				elseif action == 'cam8' then
					TriggerEvent('cctv:camera', 8)
				elseif action == 'cam9' then
					TriggerEvent('cctv:camera', 9)
				elseif action == 'cam10' then
					TriggerEvent('cctv:camera', 10)
				elseif action == 'cam11' then
					TriggerEvent('cctv:camera', 11)
				elseif action == 'cam12' then
					TriggerEvent('cctv:camera', 12)
				elseif action == 'cam13' then
					TriggerEvent('cctv:camera', 13)
				elseif action == 'cam14' then
					TriggerEvent('cctv:camera', 14)
				elseif action == 'cam15' then
					TriggerEvent('cctv:camera', 15)
				elseif action == 'cam16' then
					TriggerEvent('cctv:camera', 16)
				elseif action == 'cam17' then
					TriggerEvent('cctv:camera', 17)
				elseif action == 'cam18' then
					TriggerEvent('cctv:camera', 18)
				elseif action == 'cam19' then
					TriggerEvent('cctv:camera', 19)
				elseif action == 'cam20' then
					TriggerEvent('cctv:camera', 20)
				elseif action == 'cam21' then
					TriggerEvent('cctv:camera', 21)
				elseif action == 'cam22' then
					TriggerEvent('cctv:camera', 22)
				elseif action == 'cam23' then
					TriggerEvent('cctv:camera', 23)
				elseif action == 'cam24' then
					TriggerEvent('cctv:camera', 24)
				elseif action == 'cam25' then
					TriggerEvent('cctv:camera', 25)
				elseif action == 'cam26' then
					TriggerEvent('cctv:camera', 26)  	
				elseif action == 'cam27' then
					TriggerEvent('cctv:camera', 27) 
				elseif action == 'cam28' then
					TriggerEvent('cctv:camera', 28) 
				elseif action == 'cam29' then
					TriggerEvent('cctv:camera', 29) 
				elseif action == 'cam30' then
					TriggerEvent('cctv:camera', 30) 
				elseif action == 'cam31' then
					TriggerEvent('cctv:camera', 31) 
				elseif action == 'cam32' then
					TriggerEvent('cctv:camera', 32) 
				elseif action == 'cam33' then
					TriggerEvent('cctv:camera', 33) 
				elseif action == 'cam34' then
					TriggerEvent('cctv:camera', 34)
				elseif action == 'cam35' then
					TriggerEvent('cctv:camera', 35)
				elseif action == 'cam36' then
					TriggerEvent('cctv:camera', 36) 
				elseif action == 'cam37' then
					TriggerEvent('cctv:camera', 37) 
				elseif action == 'cam38' then
					TriggerEvent('cctv:camera', 38) 
				elseif action == 'cam39' then
					TriggerEvent('cctv:camera', 39) 
				elseif action == 'cam40' then
					TriggerEvent('cctv:camera', 40) 
				elseif action == 'cam41' then
					TriggerEvent('cctv:camera', 41) 
				elseif action == 'cam42' then
					TriggerEvent('cctv:camera', 42) 
				elseif action == 'cam43' then
					TriggerEvent('cctv:camera', 43) 
				elseif action == 'cam44' then
					TriggerEvent('cctv:camera', 44)
				elseif action == 'cam45' then
					TriggerEvent('cctv:camera', 45)	
				elseif action == 'cam46' then
					TriggerEvent('cctv:camera', 46)	
				elseif action == 'cam47' then
					TriggerEvent('cctv:camera', 47)	
				elseif action == 'cam48' then
					TriggerEvent('cctv:camera', 48)	
				elseif action == 'cam49' then
					TriggerEvent('cctv:camera', 49)				
				elseif action ==  'exit' then
					menu.close()					
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'vehicle_interaction' then
			local elements  = {}
			local playerPed = PlayerPedId()
			local vehicle = ESX.Game.GetVehicleInDirection()

			if DoesEntityExist(vehicle) then
				table.insert(elements, {label = _U('vehicle_info'), value = 'vehicle_infos'})
				table.insert(elements, {label = _U('pick_lock'), value = 'hijack_vehicle'})
				table.insert(elements, {label = _U('impound'), value = 'impound'})
			end

			table.insert(elements, {label = _U('search_database'), value = 'search_database'})

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_interaction', {
				title    = 'Interacción Vehículo',
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local coords  = GetEntityCoords(playerPed)
				vehicle = ESX.Game.GetVehicleInDirection()
				action  = data2.current.value

				if action == 'search_database' then
					LookupVehicle()
				elseif DoesEntityExist(vehicle) then
					if action == 'vehicle_infos' then
						local vehicleData = ESX.Game.GetVehicleProperties(vehicle)
						OpenVehicleInfosMenu(vehicleData)
					elseif action == 'hijack_vehicle' then
						if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
							TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
							Citizen.Wait(20000)
							ClearPedTasksImmediately(playerPed)

							SetVehicleDoorsLocked(vehicle, 1)
							SetVehicleDoorsLockedForAllPlayers(vehicle, false)
							ESX.ShowNotification(_U('vehicle_unlocked'))
						end
					elseif action == 'impound' then
						-- is the script busy?
						if currentTask.busy then
							return
						end

						ESX.ShowHelpNotification(_U('impound_prompt'))
						TaskStartScenarioInPlace(playerPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)

						currentTask.busy = true
						currentTask.task = ESX.SetTimeout(10000, function()
							ClearPedTasks(playerPed)
							ImpoundVehicle(vehicle)
							Citizen.Wait(100) -- sleep the entire script to let stuff sink back to reality
						end)

						-- keep track of that vehicle!
						Citizen.CreateThread(function()
							while currentTask.busy do
								Citizen.Wait(1000)

								vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 3.0, 0, 71)
								if not DoesEntityExist(vehicle) and currentTask.busy then
									ESX.ShowNotification(_U('impound_canceled_moved'))
									ESX.ClearTimeout(currentTask.task)
									ClearPedTasks(playerPed)
									currentTask.busy = false
									break
								end
							end
						end)
					end
				else
					ESX.ShowNotification(_U('no_vehicles_nearby'))
				end

			end, function(data2, menu2)
				menu2.close()
			end)


		elseif data.current.value == 'ppa' then

        ESX.UI.Menu.Open(
          'default', GetCurrentResourceName(), 'ppa',
          {
            title    = ('PPA'),
            align    = 'top-left',
            elements = {
              {label = ('Attribuer le PPA'), value = 'give_ppa'},
              --{label = ('Destituer le PPA'),    value = 'remove_ppa'},
            },
          },
          function(data2, menu2)
		  local player, distance = ESX.Game.GetClosestPlayer()

              if data2.current.value == 'give_ppa' then
			    if distance ~= -1 and distance <= 3.0 then
				
				TriggerServerEvent('esx_license:addLicense', GetPlayerServerId(player), 'weapon', function ()
				end)
				ESX.ShowNotification('Vous avez donner le PPA')
              else
			    ESX.ShowNotification('Personne à proximité')
			  end
			end

              if data2.current.value == 'remove_ppa' then
				if distance ~= -1 and distance <= 3.0 then
				
				TriggerServerEvent('esx_license:removeLicense', GetPlayerServerId(player), 'weapon', function ()
				end)
				ESX.ShowNotification('Vous avez retirer le PPA')
              else
			    ESX.ShowNotification('Personne à proximité')
			  end
			end
			  
		  end,

          function(data2, menu2)
            menu2.close()
          end
        )

		elseif data.current.value == 'renfort' then
			local elements  = {}
			local playerPed = PlayerPedId()

			table.insert(elements, {label = ('<span style="color:08732A;">Pequeña prioridas'), value = 'petite_demande'})
			table.insert(elements, {label = ('<span style="color:#A36C0B;">Alta prioridad'), value = 'demande_importante'})
			table.insert(elements, {label = ('<span style="color:#940909;">¡Todas las unidades solicitadas!'), value = 'omgad'})


			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'renfort', {
				css      = 'police',
				title    = ('Solicitar Refuerzos'),
				align    = 'top-left',
				elements = elements
			}, function(data2, menu2)
				local coords  = GetEntityCoords(playerPed)
				vehicle = ESX.Game.GetVehicleInDirection()
				action  = data2.current.value
				local name = GetPlayerName(PlayerId())

				if action == 'petite_demande' then
					local raison = 'petit'
					TriggerServerEvent('renfort', coords, raison)
				elseif action == 'demande_importante' then
					local raison = 'importante'
					TriggerServerEvent('renfort', coords, raison)
				elseif action == 'omgad' then
					local raison = 'omgad'
					TriggerServerEvent('renfort', coords, raison)
				end

			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'object_spawner' then
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
				title    = _U('traffic_interaction'),
				align    = 'top-left',
				elements = {
					{label = _U('cone'), model = 'prop_roadcone02a'},
					{label = _U('barrier'), model = 'prop_barrier_work05'},
					{label = _U('spikestrips'), model = 'p_ld_stinger_s'},
					{label = _U('box'), model = 'prop_boxpile_07d'},
					{label = _U('cash'), model = 'hei_prop_cash_crate_half_full'}
			}}, function(data2, menu2)
				local playerPed = PlayerPedId()
				local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
				local objectCoords = (coords + forward * 1.0)

				ESX.Game.SpawnObject(data2.current.model, objectCoords, function(obj)
					SetEntityHeading(obj, GetEntityHeading(playerPed))
					PlaceObjectOnGroundProperly(obj)
				end)
			end, function(data2, menu2)
				menu2.close()
			end)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenIdentityCardMenu(player)
	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
		local elements = {}
		local nameLabel = _U('name', data.name)
		local jobLabel, sexLabel, dobLabel, heightLabel, idLabel

		if data.job.grade_label and  data.job.grade_label ~= '' then
			jobLabel = _U('job', data.job.label .. ' - ' .. data.job.grade_label)
		else
			jobLabel = _U('job', data.job.label)
		end

		if Config.EnableESXIdentity then
			nameLabel = _U('name', data.firstname .. ' ' .. data.lastname)

			if data.sex then
				if string.lower(data.sex) == 'm' then
					sexLabel = _U('sex', _U('male'))
				else
					sexLabel = _U('sex', _U('female'))
				end
			else
				sexLabel = _U('sex', _U('unknown'))
			end

			if data.dob then
				dobLabel = _U('dob', data.dob)
			else
				dobLabel = _U('dob', _U('unknown'))
			end

			if data.height then
				heightLabel = _U('height', data.height)
			else
				heightLabel = _U('height', _U('unknown'))
			end

			if data.name then
				idLabel = _U('id', data.name)
			else
				idLabel = _U('id', _U('unknown'))
			end
		end

		local elements = {
			{label = nameLabel},
			{label = jobLabel}
		}

		if Config.EnableESXIdentity then
			table.insert(elements, {label = sexLabel})
			table.insert(elements, {label = dobLabel})
			table.insert(elements, {label = heightLabel})
			table.insert(elements, {label = idLabel})
		end

		if data.drunk then
			table.insert(elements, {label = _U('bac', data.drunk)})
		end

		if data.licenses then
			table.insert(elements, {label = _U('license_label')})

			for i=1, #data.licenses, 1 do
				table.insert(elements, {label = data.licenses[i].label})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'citizen_interaction', {
			css      = 'police',
			title    = _U('citizen_interaction'),
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)
	end, GetPlayerServerId(player))
end

function OpenBodySearchMenu(player)
	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(data)
		local elements = {}

		for i=1, #data.accounts, 1 do
			if data.accounts[i].name == 'black_money' and data.accounts[i].money > 0 then
				table.insert(elements, {
					label    = _U('confiscate_dirty', ESX.Math.Round(data.accounts[i].money)),
					value    = 'black_money',
					itemType = 'item_account',
					amount   = data.accounts[i].money
				})

				break
			end
		end

		table.insert(elements, {label = _U('guns_label')})

		for i=1, #data.weapons, 1 do
			table.insert(elements, {
				label    = _U('confiscate_weapon', ESX.GetWeaponLabel(data.weapons[i].name), data.weapons[i].ammo),
				value    = data.weapons[i].name,
				itemType = 'item_weapon',
				amount   = data.weapons[i].ammo
			})
		end

		table.insert(elements, {label = _U('inventory_label')})

		for i=1, #data.inventory, 1 do
			if data.inventory[i].count > 0 then
				table.insert(elements, {
					label    = _U('confiscate_inv', data.inventory[i].count, data.inventory[i].label),
					value    = data.inventory[i].name,
					itemType = 'item_standard',
					amount   = data.inventory[i].count
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'body_search', {
			css      = 'police',
			title    = _U('search'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			if data.current.value then
				TriggerServerEvent('esx_policejob:confiscatePlayerItem', GetPlayerServerId(player), data.current.itemType, data.current.value, data.current.amount)
				OpenBodySearchMenu(player)
			end
		end, function(data, menu)
			menu.close()
		end)
	end, GetPlayerServerId(player))
end

function OpenFineMenu(player)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine', {
		title    = _U('fine'),
		align    = 'top-left',
		elements = {
			{label = _U('traffic_offense'), value = 0},
			{label = _U('minor_offense'),   value = 1},
			{label = _U('average_offense'), value = 2},
			{label = _U('major_offense'),   value = 3}
	}}, function(data, menu)
		OpenFineCategoryMenu(player, data.current.value)
	end, function(data, menu)
		menu.close()
	end)
end

function OpenFineCategoryMenu(player, category)
	ESX.TriggerServerCallback('esx_policejob:getFineList', function(fines)
		local elements = {}

		for k,fine in ipairs(fines) do
			table.insert(elements, {
				label     = ('%s <span style="color:green;">%s</span>'):format(fine.label, _U('armory_item', ESX.Math.GroupDigits(fine.amount))),
				value     = fine.id,
				amount    = fine.amount,
				fineLabel = fine.label
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fine_category', {
			title    = _U('fine'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			if Config.EnablePlayerManagement then
				TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), 'society_police', _U('fine_total', data.current.fineLabel), data.current.amount)
			else
				TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(player), '', _U('fine_total', data.current.fineLabel), data.current.amount)
			end

			ESX.SetTimeout(300, function()
				OpenFineCategoryMenu(player, category)
			end)
		end, function(data, menu)
			menu.close()
		end)
	end, category)
end

function LookupVehicle()
	ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'lookup_vehicle', {
		title = _U('search_database_title'),
	}, function(data, menu)
		local length = string.len(data.value)
		if not data.value or length < 2 or length > 8 then
			ESX.ShowNotification(_U('search_database_error_invalid'))
		else
			ESX.TriggerServerCallback('esx_policejob:getVehicleInfos', function(retrivedInfo)
				local elements = {{label = _U('plate', retrivedInfo.plate)}}
				menu.close()

				if not retrivedInfo.owner then
					table.insert(elements, {label = _U('owner_unknown')})
				else
					table.insert(elements, {label = _U('owner', retrivedInfo.owner)})
				end

				ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos', {
					title    = _U('vehicle_info'),
					align    = 'top-left',
					elements = elements
				}, nil, function(data2, menu2)
					menu2.close()
				end)
			end, data.value)

		end
	end, function(data, menu)
		menu.close()
	end)
end

function ShowPlayerLicense(player)
	local elements = {}

	ESX.TriggerServerCallback('esx_policejob:getOtherPlayerData', function(playerData)
		if playerData.licenses then
			for i=1, #playerData.licenses, 1 do
				if playerData.licenses[i].label and playerData.licenses[i].type then
					table.insert(elements, {
						label = playerData.licenses[i].label,
						type = playerData.licenses[i].type
					})
				end
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'manage_license', {
			title    = _U('license_revoke'),
			align    = 'top-left',
			elements = elements,
		}, function(data, menu)
			ESX.ShowNotification(_U('licence_you_revoked', data.current.label, playerData.name))
			TriggerServerEvent('esx_policejob:message', GetPlayerServerId(player), _U('license_revoked', data.current.label))

			TriggerServerEvent('esx_license:removeLicense', GetPlayerServerId(player), data.current.type)

			ESX.SetTimeout(300, function()
				ShowPlayerLicense(player)
			end)
		end, function(data, menu)
			menu.close()
		end)

	end, GetPlayerServerId(player))
end

function OpenUnpaidBillsMenu(player)
	local elements = {}

	ESX.TriggerServerCallback('esx_billing:getTargetBills', function(bills)
		for k,bill in ipairs(bills) do
			table.insert(elements, {
				label = ('%s - <span style="color:red;">%s</span>'):format(bill.label, _U('armory_item', ESX.Math.GroupDigits(bill.amount))),
				billId = bill.id
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'billing', {
			title    = _U('unpaid_bills'),
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)
	end, GetPlayerServerId(player))
end

function OpenVehicleInfosMenu(vehicleData)
	ESX.TriggerServerCallback('esx_policejob:getVehicleInfos', function(retrivedInfo)
		local elements = {{label = _U('plate', retrivedInfo.plate)}}

		if not retrivedInfo.owner then
			table.insert(elements, {label = _U('owner_unknown')})
		else
			table.insert(elements, {label = _U('owner', retrivedInfo.owner)})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_infos', {
			title    = _U('vehicle_info'),
			align    = 'top-left',
			elements = elements
		}, nil, function(data, menu)
			menu.close()
		end)
	end, vehicleData.plate)
end

function OpenGetWeaponMenu()
	ESX.TriggerServerCallback('esx_policejob:getArmoryWeapons', function(weapons)
		local elements = {}

		for i=1, #weapons, 1 do
			if weapons[i].count > 0 then
				table.insert(elements, {
					label = 'x' .. weapons[i].count .. ' ' .. ESX.GetWeaponLabel(weapons[i].name),
					value = weapons[i].name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_get_weapon', {
			title    = _U('get_weapon_menu'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			menu.close()

			ESX.TriggerServerCallback('esx_policejob:removeArmoryWeapon', function()
				OpenGetWeaponMenu()
			end, data.current.value)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function OpenPutWeaponMenu()
	local elements   = {}
	local playerPed  = PlayerPedId()
	local weaponList = ESX.GetWeaponList()

	for i=1, #weaponList, 1 do
		local weaponHash = GetHashKey(weaponList[i].name)

		if HasPedGotWeapon(playerPed, weaponHash, false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
			table.insert(elements, {
				label = weaponList[i].label,
				value = weaponList[i].name
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_put_weapon', {
		title    = _U('put_weapon_menu'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		menu.close()

		ESX.TriggerServerCallback('esx_policejob:addArmoryWeapon', function()
			OpenPutWeaponMenu()
		end, data.current.value, true)
	end, function(data, menu)
		menu.close()
	end)
end

function OpenBuyWeaponsMenu()
	local elements = {}
	local playerPed = PlayerPedId()

	for k,v in ipairs(Config.AuthorizedWeapons[ESX.PlayerData.job.grade_name]) do
		local weaponNum, weapon = ESX.GetWeapon(v.weapon)
		local components, label = {}
		local hasWeapon = HasPedGotWeapon(playerPed, GetHashKey(v.weapon), false)

		if v.components then
			for i=1, #v.components do
				if v.components[i] then
					local component = weapon.components[i]
					local hasComponent = HasPedGotWeaponComponent(playerPed, GetHashKey(v.weapon), component.hash)

					if hasComponent then
						label = ('%s: <span style="color:green;">%s</span>'):format(component.label, _U('armory_owned'))
					else
						if v.components[i] > 0 then
							label = ('%s: <span style="color:green;">%s</span>'):format(component.label, _U('armory_item', ESX.Math.GroupDigits(v.components[i])))
						else
							label = ('%s: <span style="color:green;">%s</span>'):format(component.label, _U('armory_free'))
						end
					end

					table.insert(components, {
						label = label,
						componentLabel = component.label,
						hash = component.hash,
						name = component.name,
						price = v.components[i],
						hasComponent = hasComponent,
						componentNum = i
					})
				end
			end
		end

		if hasWeapon and v.components then
			label = ('%s: <span style="color:green;">></span>'):format(weapon.label)
		elseif hasWeapon and not v.components then
			label = ('%s: <span style="color:green;">%s</span>'):format(weapon.label, _U('armory_owned'))
		else
			if v.price > 0 then
				label = ('%s: <span style="color:green;">%s</span>'):format(weapon.label, _U('armory_item', ESX.Math.GroupDigits(v.price)))
			else
				label = ('%s: <span style="color:green;">%s</span>'):format(weapon.label, _U('armory_free'))
			end
		end

		table.insert(elements, {
			label = label,
			weaponLabel = weapon.label,
			name = weapon.name,
			components = components,
			price = v.price,
			hasWeapon = hasWeapon
		})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_buy_weapons', {
		title    = _U('armory_weapontitle'),
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		if data.current.hasWeapon then
			if #data.current.components > 0 then
				OpenWeaponComponentShop(data.current.components, data.current.name, menu)
			end
		else
			ESX.TriggerServerCallback('esx_policejob:buyWeapon', function(bought)
				if bought then
					if data.current.price > 0 then
						ESX.ShowNotification(_U('armory_bought', data.current.weaponLabel, ESX.Math.GroupDigits(data.current.price)))
					end

					menu.close()
					OpenBuyWeaponsMenu()
				else
					ESX.ShowNotification(_U('armory_money'))
				end
			end, data.current.name, 1)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenWeaponComponentShop(components, weaponName, parentShop)
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'armory_buy_weapons_components', {
		title    = _U('armory_componenttitle'),
		align    = 'top-left',
		elements = components
	}, function(data, menu)
		if data.current.hasComponent then
			ESX.ShowNotification(_U('armory_hascomponent'))
		else
			ESX.TriggerServerCallback('esx_policejob:buyWeapon', function(bought)
				if bought then
					if data.current.price > 0 then
						ESX.ShowNotification(_U('armory_bought', data.current.componentLabel, ESX.Math.GroupDigits(data.current.price)))
					end

					menu.close()
					parentShop.close()
					OpenBuyWeaponsMenu()
				else
					ESX.ShowNotification(_U('armory_money'))
				end
			end, weaponName, 2, data.current.componentNum)
		end
	end, function(data, menu)
		menu.close()
	end)
end

function OpenGetStocksMenu()
	ESX.TriggerServerCallback('esx_policejob:getStockItems', function(items)
		local elements = {}

		for i=1, #items, 1 do
			table.insert(elements, {
				label = 'x' .. items[i].count .. ' ' .. items[i].label,
				value = items[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('police_stock'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if not count then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_policejob:getStockItem', itemName, count)

					Citizen.Wait(300)
					OpenGetStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

function DeleteJobVehicle()
	local playerPed = PlayerPedId()

	if Config.EnableSocietyOwnedVehicles then
		local vehicleProps = ESX.Game.GetVehicleProperties(CurrentActionData.vehicle)
		TriggerServerEvent('esx_society:putVehicleInGarage', 'police', vehicleProps)
		ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
	else
		if IsInAuthorizedVehicle() then
			ESX.Game.DeleteVehicle(CurrentActionData.vehicle)

			if Config.MaxInService ~= -1 then
				TriggerServerEvent('esx_service:disableService', 'police')
			end
		else
			ESX.ShowNotification(_U('only_police'))
		end
	end
end

function OpenPutStocksMenu()
	ESX.TriggerServerCallback('esx_policejob:getPlayerInventory', function(inventory)
		local elements = {}

		for i=1, #inventory.items, 1 do
			local item = inventory.items[i]

			if item.count > 0 then
				table.insert(elements, {
					label = item.label .. ' x' .. item.count,
					type = 'item_standard',
					value = item.name
				})
			end
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'stocks_menu', {
			title    = _U('inventory'),
			align    = 'top-left',
			elements = elements
		}, function(data, menu)
			local itemName = data.current.value

			ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count', {
				title = _U('quantity')
			}, function(data2, menu2)
				local count = tonumber(data2.value)

				if not count then
					ESX.ShowNotification(_U('quantity_invalid'))
				else
					menu2.close()
					menu.close()
					TriggerServerEvent('esx_policejob:putStockItems', itemName, count)

					Citizen.Wait(300)
					OpenPutStocksMenu()
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end)
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job

	Citizen.Wait(5000)
	TriggerServerEvent('esx_policejob:forceBlip')
end)

RegisterNetEvent('esx_phone:loaded')
AddEventHandler('esx_phone:loaded', function(phoneNumber, contacts)
	local specialContact = {
		name       = _U('phone_police'),
		number     = 'police',
		base64Icon = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMy1jMDExIDY2LjE0NTY2MSwgMjAxMi8wMi8wNi0xNDo1NjoyNyAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNiAoV2luZG93cykiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6NDFGQTJDRkI0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6NDFGQTJDRkM0QUJCMTFFN0JBNkQ5OENBMUI4QUEzM0YiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDo0MUZBMkNGOTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDo0MUZBMkNGQTRBQkIxMUU3QkE2RDk4Q0ExQjhBQTMzRiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PoW66EYAAAjGSURBVHjapJcLcFTVGcd/u3cfSXaTLEk2j80TCI8ECI9ABCyoiBqhBVQqVG2ppVKBQqUVgUl5OU7HKqNOHUHU0oHamZZWoGkVS6cWAR2JPJuAQBPy2ISEvLN57+v2u2E33e4k6Ngz85+9d++95/zP9/h/39GpqsqiRYsIGz8QZAq28/8PRfC+4HT4fMXFxeiH+GC54NeCbYLLATLpYe/ECx4VnBTsF0wWhM6lXY8VbBE0Ch4IzLcpfDFD2P1TgrdC7nMCZLRxQ9AkiAkQCn77DcH3BC2COoFRkCSIG2JzLwqiQi0RSmCD4JXbmNKh0+kc/X19tLtc9Ll9sk9ZS1yoU71YIk3xsbEx8QaDEc2ttxmaJSKC1ggSKBK8MKwTFQVXRzs3WzpJGjmZgvxcMpMtWIwqsjztvSrlzjYul56jp+46qSmJmMwR+P3+4aZ8TtCprRkk0DvUW7JjmV6lsqoKW/pU1q9YQOE4Nxkx4ladE7zd8ivuVmJQfXZKW5dx5EwPRw4fxNx2g5SUVLw+33AkzoRaQDP9SkFu6OKqz0uF8yaz7vsOL6ycQVLkcSg/BlWNsjuFoKE1knqDSl5aNnmPLmThrE0UvXqQqvJPyMrMGorEHwQfEha57/3P7mXS684GFjy8kreLppPUuBXfyd/ibeoS2kb0mWPANhJdYjb61AxUvx5PdT3+4y+Tb3mTd19ZSebE+VTXVGNQlHAC7w4VhH8TbA36vKq6ilnzlvPSunHw6Trc7XpZ14AyfgYeyz18crGN1Alz6e3qwNNQSv4dZox1h/BW9+O7eIaEsVv41Y4XeHJDG83Nl4mLTwzGhJYtx0PzNTjOB9KMTlc7Nkcem39YAGU7cbeBKVLMPGMVf296nMd2VbBq1wmizHoqqm/wrS1/Zf0+N19YN2PIu1fcIda4Vk66Zx/rVi+jo9eIX9wZGGcFXUMR6BHUa76/2ezioYcXMtpyAl91DSaTfDxlJbtLprHm2ecpObqPuTPzSNV9yKz4a4zJSuLo71/j8Q17ON69EmXiPIlNMe6FoyzOqWPW/MU03Lw5EFcyKghTrNDh7+/vw545mcJcWbTiGKpRdGPMXbx90sGmDaux6sXk+kimjU+BjnMkx3kYP34cXrFuZ+3nrHi6iDMt92JITcPjk3R3naRwZhpuNSqoD93DKaFVU7j2dhcF8+YzNlpErbIBTVh8toVccbaysPB+4pMcuPw25kwSsau7BIlmHpy3guaOPtISYyi/UkaJM5Lpc5agq5Xkcl6gIHkmqaMn0dtylcjIyPThCNyhaXyfR2W0I1our0v6qBii07ih5rDtGSOxNVdk1y4R2SR8jR/g7hQD9l1jUeY/WLJB5m39AlZN4GZyIQ1fFJNsEgt0duBIc5GRkcZF53mNwIzhXPDgQPoZIkiMkbTxtstDMVnmFA4cOsbz2/aKjSQjev4Mp9ZAg+hIpFhB3EH5Yal16+X+Kq3dGfxkzRY+KauBjBzREvGN0kNCTARu94AejBLMHorAQ7cEQMGs2cXvkWshYLDi6e9l728O8P1XW6hKeB2yv42q18tjj+iFTGoSi+X9jJM9RTxS9E+OHT0krhNiZqlbqraoT7RAU5bBGrEknEBhgJks7KXbLS8qERI0ErVqF/Y4K6NHZfLZB+/wzJvncacvFd91oXO3o/O40MfZKJOKu/rne+mRQByXM4lYreb1tUnkizVVA/0SpfpbWaCNBeEE5gb/UH19NLqEgDF+oNDQWcn41Cj0EXFEWqzkOIyYekslFkThsvMxpIyE2hIc6lXGZ6cPyK7Nnk5OipixRdxgUESAYmhq68VsGgy5CYKCUAJTg0+izApXne3CJFmUTwg4L3FProFxU+6krqmXu3MskkhSD2av41jLdzlnfFrSdCZxyqfMnppN6ZUa7pwt0h3fiK9DCt4IO9e7YqisvI7VYgmNv7mhBKKD/9psNi5dOMv5ZjukjsLdr0ffWsyTi6eSlfcA+dmiVyOXs+/sHNZu3M6PdxzgVO9GmDSHsSNqmTz/R6y6Xxqma4fwaS5Mn85n1ZE0Vl3CHBER3lUNEhiURpPJRFdTOcVnpUJnPIhR7cZXfoH5UYc5+E4RzRH3sfSnl9m2dSMjE+Tz9msse+o5dr7UwcQ5T3HwlWUkNuzG3dKFSTbsNs7m/Y8vExOlC29UWkMJlAxKoRQMR3IC7x85zOn6fHS50+U/2Untx2R1voinu5no+DQmz7yPXmMKZnsu0wrm0Oe3YhOVHdm8A09dBQYhTv4T7C+xUPrZh8Qn2MMr4qcDSRfoirWgKAvtgOpv1JI8Zi77X15G7L+fxeOUOiUFxZiULD5fSlNzNM62W+k1yq5gjajGX/ZHvOIyxd+Fkj+P092rWP/si0Qr7VisMaEWuCiYonXFwbAUTWWPYLV245NITnGkUXnpI9butLJn2y6iba+hlp7C09qBcvoN7FYL9mhxo1/y/LoEXK8Pv6qIC8WbBY/xr9YlPLf9dZT+OqKTUwfmDBm/GOw7ws4FWpuUP2gJEZvKqmocuXPZuWYJMzKuSsH+SNwh3bo0p6hao6HeEqwYEZ2M6aKWd3PwTCy7du/D0F1DsmzE6/WGLr5LsDF4LggnYBacCOboQLHQ3FFfR58SR+HCR1iQH8ukhA5s5o5AYZMwUqOp74nl8xvRHDlRTsnxYpJsUjtsceHt2C8Fm0MPJrphTkZvBc4It9RKLOFx91Pf0Igu0k7W2MmkOewS2QYJUJVWVz9VNbXUVVwkyuAmKTFJayrDo/4Jwe/CT0aGYTrWVYEeUfsgXssMRcpyenraQJa0VX9O3ZU+Ma1fax4xGxUsUVFkOUbcama1hf+7+LmA9juHWshwmwOE1iMmCFYEzg1jtIm1BaxW6wCGGoFdewPfvyE4ertTiv4rHC73B855dwp2a23bbd4tC1hvhOCbX7b4VyUQKhxrtSOaYKngasizvwi0RmOS4O1QZf2yYfiaR+73AvhTQEVf+rpn9/8IMAChKDrDzfsdIQAAAABJRU5ErkJggg=='
	}

	TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
end)

-- don't show dispatches if the player isn't in service
AddEventHandler('esx_phone:cancelMessage', function(dispatchNumber)
	if PlayerData.job and PlayerData.job.name == 'police' and PlayerData.job.name == dispatchNumber then
		-- if esx_service is enabled
		if Config.MaxInService ~= -1 and not playerInService then
			CancelEvent()
		end
	end
end)

AddEventHandler('esx_policejob:hasEnteredMarker', function(station, part, partNum)
	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	elseif part == 'Armory' then
		CurrentAction     = 'menu_armory'
		CurrentActionMsg  = _U('open_armory')
		CurrentActionData = {station = station}
	elseif part == 'Vehicles' then
		CurrentAction     = 'menu_vehicle_spawner'
		CurrentActionMsg  = _U('garage_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'Helicopters' then
		CurrentAction     = 'Helicopters'
		CurrentActionMsg  = _U('helicopter_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	end
end)

AddEventHandler('esx_policejob:hasExitedMarker', function(station, part, partNum)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

	CurrentAction = nil
end)

AddEventHandler('esx_policejob:hasEnteredEntityZone', function(entity)
	local playerPed = PlayerPedId()

	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and IsPedOnFoot(playerPed) then
		CurrentAction     = 'remove_entity'
		CurrentActionMsg  = _U('remove_prop')
		CurrentActionData = {entity = entity}
	end

	if GetEntityModel(entity) == GetHashKey('p_ld_stinger_s') then
		local playerPed = PlayerPedId()
		local coords    = GetEntityCoords(playerPed)

		if IsPedInAnyVehicle(playerPed, false) then
			local vehicle = GetVehiclePedIsIn(playerPed)

			for i=0, 7, 1 do
				SetVehicleTyreBurst(vehicle, i, true, 1000)
			end
		end
	end
end)

AddEventHandler('esx_policejob:hasExitedEntityZone', function(entity)
	if CurrentAction == 'remove_entity' then
		CurrentAction = nil
	end
end)

RegisterNetEvent('esx_policejob:handcuff')
AddEventHandler('esx_policejob:handcuff', function()
	isHandcuffed = not isHandcuffed
	local playerPed = PlayerPedId()

	if isHandcuffed then
		RequestAnimDict('mp_arresting')
		while not HasAnimDictLoaded('mp_arresting') do
			Citizen.Wait(100)
		end

		TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)

		SetEnableHandcuffs(playerPed, true)
		DisablePlayerFiring(playerPed, true)
		SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true) -- unarm player
		SetPedCanPlayGestureAnims(playerPed, false)
		FreezeEntityPosition(playerPed, true)
		DisplayRadar(false)

		if Config.EnableHandcuffTimer then
			if handcuffTimer.active then
				ESX.ClearTimeout(handcuffTimer.task)
			end

			StartHandcuffTimer()
		end
	else
		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end

		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)
		DisplayRadar(true)
	end
end)

RegisterNetEvent('esx_policejob:unrestrain')
AddEventHandler('esx_policejob:unrestrain', function()
	if isHandcuffed then
		local playerPed = PlayerPedId()
		isHandcuffed = false

		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)
		DisplayRadar(true)

		-- end timer
		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
	end
end)

RegisterNetEvent('esx_policejob:drag')
AddEventHandler('esx_policejob:drag', function(copId)
	if isHandcuffed then
		dragStatus.isDragged = not dragStatus.isDragged
		dragStatus.CopId = copId
	end
end)

Citizen.CreateThread(function()
	local wasDragged

	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()

		if isHandcuffed and dragStatus.isDragged then
			local targetPed = GetPlayerPed(GetPlayerFromServerId(dragStatus.CopId))

			if DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) and not IsPedDeadOrDying(targetPed, true) then
				if not wasDragged then
					AttachEntityToEntity(playerPed, targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
					wasDragged = true
				else
					Citizen.Wait(1000)
				end
			else
				wasDragged = false
				dragStatus.isDragged = false
				DetachEntity(playerPed, true, false)
			end
		elseif wasDragged then
			wasDragged = false
			DetachEntity(playerPed, true, false)
		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('esx_policejob:putInVehicle')
AddEventHandler('esx_policejob:putInVehicle', function()
	if isHandcuffed then
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

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
					dragStatus.isDragged = false
				end
			end
		end
	end
end)

RegisterNetEvent('renfort:setBlip')
AddEventHandler('renfort:setBlip', function(coords, raison)
	if raison == 'petit' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Solicitud de refuerzo', 'Solicitud de refuerzo entrante.\nRéponse: ~g~CODE-2\n~w~Importance: ~g~Ligero.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		color = 2
	elseif raison == 'importante' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Solicitud de refuerzo', 'Solicitud de refuerzo entrante.\nRéponse: ~g~CODE-3\n~w~Importance: ~o~Importante.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		color = 47
	elseif raison == 'omgad' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "OOB_Start", "GTAO_FM_Events_Soundset", 1)
		PlaySoundFrontend(-1, "FocusIn", "HintCamSounds", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Solicitud de refuerzo', 'Solicitud de refuerzo entrante.\nRéponse: ~g~CODE-99\n~w~Importance: ~r~URGENTE PELIGRO IMPORTANTE', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
		PlaySoundFrontend(-1, "FocusOut", "HintCamSounds", 1)
		color = 1
	end
	local blipId = AddBlipForCoord(coords)
	SetBlipSprite(blipId, 161)
	SetBlipScale(blipId, 1.2)
	SetBlipColour(blipId, color)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString('Demande renfort')
	EndTextCommandSetBlipName(blipId)
	Wait(80 * 1000)
	RemoveBlip(blipId)
end)

RegisterNetEvent('police:InfoService')
AddEventHandler('police:InfoService', function(service, nom)
	if service == 'prise' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Empezo su servicio', 'Agente: ~g~'..nom..'\n~w~Codigo: ~g~10-8\n~w~Informacion: ~g~Empezo su servicio.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'fin' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Fin de servicio', 'Agente: ~g~'..nom..'\n~w~Codigo: ~g~10-10\n~w~Informacion: ~g~Fin de servicio.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'pause' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Pausa de servicio', 'Agente: ~g~'..nom..'\n~w~Codigo: ~g~10-6\n~w~Informacion: ~g~Pauso su servicio.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'standby' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~En espera', 'Agente: ~g~'..nom..'\n~w~Codigo: ~g~10-12\n~w~Informacion: ~g~En espera, Esperando asignacion.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'control' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Control rutinario', 'Agente: ~g~'..nom..'\n~w~Codigo: ~g~10-48\n~w~Informacion: ~g~Control rutinario en curso.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'refus' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Negativa a cumplir', 'Agente: ~g~'..nom..'\n~w~Codigo: ~g~10-30\n~w~Informacion: ~g~Negativa a cumplir.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	elseif service == 'crime' then
		PlaySoundFrontend(-1, "Start_Squelch", "CB_RADIO_SFX", 1)
		ESX.ShowAdvancedNotification('GC Informacion', '~b~Crimen en curso', 'Agente: ~g~'..nom..'\n~w~Codigo: ~g~10-31\n~w~Informacion: ~g~Crimen en curso.', 'CHAR_CALL911', 8)
		Wait(1000)
		PlaySoundFrontend(-1, "End_Squelch", "CB_RADIO_SFX", 1)
	end
end)

RegisterNetEvent('esx_policejob:OutVehicle')
AddEventHandler('esx_policejob:OutVehicle', function()
	local playerPed = PlayerPedId()

	if IsPedSittingInAnyVehicle(playerPed) then
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		TaskLeaveVehicle(playerPed, vehicle, 16)
	end
end)

-- Handcuff
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()

		if isHandcuffed then
			DisableControlAction(0, 1, true) -- Disable pan
			DisableControlAction(0, 2, true) -- Disable tilt
			DisableControlAction(0, 24, true) -- Attack
			DisableControlAction(0, 257, true) -- Attack 2
			DisableControlAction(0, 25, true) -- Aim
			DisableControlAction(0, 263, true) -- Melee Attack 1
			DisableControlAction(0, 32, true) -- W
			DisableControlAction(0, 34, true) -- A
			DisableControlAction(0, 31, true) -- S
			DisableControlAction(0, 30, true) -- D

			DisableControlAction(0, 45, true) -- Reload
			DisableControlAction(0, 22, true) -- Jump
			DisableControlAction(0, 44, true) -- Cover
			DisableControlAction(0, 37, true) -- Select Weapon
			DisableControlAction(0, 23, true) -- Also 'enter'?

			DisableControlAction(0, 288,  true) -- Disable phone
			DisableControlAction(0, 289, true) -- Inventory
			DisableControlAction(0, 170, true) -- Animations
			DisableControlAction(0, 167, true) -- Job

			DisableControlAction(0, 0, true) -- Disable changing view
			DisableControlAction(0, 26, true) -- Disable looking behind
			DisableControlAction(0, 73, true) -- Disable clearing animation
			DisableControlAction(2, 199, true) -- Disable pause screen

			DisableControlAction(0, 59, true) -- Disable steering in vehicle
			DisableControlAction(0, 71, true) -- Disable driving forward in vehicle
			DisableControlAction(0, 72, true) -- Disable reversing in vehicle

			DisableControlAction(2, 36, true) -- Disable going stealth

			DisableControlAction(0, 47, true)  -- Disable weapon
			DisableControlAction(0, 264, true) -- Disable melee
			DisableControlAction(0, 257, true) -- Disable melee
			DisableControlAction(0, 140, true) -- Disable melee
			DisableControlAction(0, 141, true) -- Disable melee
			DisableControlAction(0, 142, true) -- Disable melee
			DisableControlAction(0, 143, true) -- Disable melee
			DisableControlAction(0, 75, true)  -- Disable exit vehicle
			DisableControlAction(27, 75, true) -- Disable exit vehicle

			if IsEntityPlayingAnim(playerPed, 'mp_arresting', 'idle', 3) ~= 1 then
				ESX.Streaming.RequestAnimDict('mp_arresting', function()
					TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0.0, false, false, false)
				end)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

-- Create blips
Citizen.CreateThread(function()
	for k,v in pairs(Config.PoliceStations) do
		local blip = AddBlipForCoord(v.Blip.Coords)

		SetBlipSprite (blip, v.Blip.Sprite)
		SetBlipDisplay(blip, v.Blip.Display)
		SetBlipScale  (blip, v.Blip.Scale)
		SetBlipColour (blip, v.Blip.Colour)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(_U('map_blip'))
		EndTextCommandSetBlipName(blip)
	end
end)

-- Draw markers and more
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)
			local isInMarker, hasExited, letSleep = false, false, true
			local currentStation, currentPart, currentPartNum

			for k,v in pairs(Config.PoliceStations) do
				for i=1, #v.Cloakrooms, 1 do
					local distance = #(playerCoords - v.Cloakrooms[i])

					if distance < Config.DrawDistance then
						DrawMarker(27, v.Cloakrooms[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Cloakroom', i
						end
					end
				end

				for i=1, #v.Armories, 1 do
					local distance = #(playerCoords - v.Armories[i])

					if distance < Config.DrawDistance then
						DrawMarker(27, v.Armories[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Armory', i
						end
					end
				end

				if Config.EnablePlayerManagement and ESX.PlayerData.job.grade_name == 'boss' then
					for i=1, #v.BossActions, 1 do
						local distance = #(playerCoords - v.BossActions[i])

						if distance < Config.DrawDistance then
							DrawMarker(27, v.BossActions[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
							letSleep = false

							if distance < Config.MarkerSize.x then
								isInMarker, currentStation, currentPart, currentPartNum = true, k, 'BossActions', i
							end
						end
					end
				end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastStation and LastPart and LastPartNum) and
					(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('esx_policejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				LastPartNum             = currentPartNum

				TriggerEvent('esx_policejob:hasEnteredMarker', currentStation, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_policejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end

			if letSleep then
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

-- Enter / Exit entity zone events
Citizen.CreateThread(function()
	local trackedEntities = {
		'prop_roadcone02a',
		'prop_barrier_work05',
		'p_ld_stinger_s',
		'prop_boxpile_07d',
		'hei_prop_cash_crate_half_full'
	}

	while true do
		Citizen.Wait(500)

		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)

		local closestDistance = -1
		local closestEntity   = nil

		for i=1, #trackedEntities, 1 do
			local object = GetClosestObjectOfType(playerCoords, 3.0, GetHashKey(trackedEntities[i]), false, false, false)

			if DoesEntityExist(object) then
				local objCoords = GetEntityCoords(object)
				local distance = #(playerCoords - objCoords)

				if closestDistance == -1 or closestDistance > distance then
					closestDistance = distance
					closestEntity   = object
				end
			end
		end

		if closestDistance ~= -1 and closestDistance <= 3.0 then
			if LastEntity ~= closestEntity then
				TriggerEvent('esx_policejob:hasEnteredEntityZone', closestEntity)
				LastEntity = closestEntity
			end
		else
			if LastEntity then
				TriggerEvent('esx_policejob:hasExitedEntityZone', LastEntity)
				LastEntity = nil
			end
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then

				if CurrentAction == 'menu_cloakroom' then
					OpenCloakroomMenu()
				elseif CurrentAction == 'menu_armory' then
					if not Config.EnableESXService then
						OpenArmoryMenu(CurrentActionData.station)
					elseif playerInService then
						OpenArmoryMenu(CurrentActionData.station)
					else
						ESX.ShowNotification(_U('service_not'))
					end
				elseif CurrentAction == 'menu_vehicle_spawner' then
					if not Config.EnableESXService then
						OpenVehicleSpawnerMenu('car', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					elseif playerInService then
						OpenVehicleSpawnerMenu('car', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					else
						ESX.ShowNotification(_U('service_not'))
					end
				elseif CurrentAction == 'Helicopters' then
					if Config.MaxInService == -1 then
						OpenVehicleSpawnerMenu('helicopter', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					elseif playerInService then
						OpenVehicleSpawnerMenu('helicopter', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
					else
						ESX.ShowNotification(_U('service_not'))
					end
				elseif CurrentAction == 'delete_vehicle' then
					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
				elseif CurrentAction == 'menu_boss_actions' then
					ESX.UI.Menu.CloseAll()
					TriggerEvent('esx_society:openBossMenu', 'police', function(data, menu)
						menu.close()

						CurrentAction     = 'menu_boss_actions'
						CurrentActionMsg  = _U('open_bossmenu')
						CurrentActionData = {}
					end, { wash = false }) -- disable washing money
				elseif CurrentAction == 'remove_entity' then
					DeleteEntity(CurrentActionData.entity)
				end

				CurrentAction = nil
			end
		end -- CurrentAction end

		if IsControlJustReleased(0, 167) and not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'police_actions') then
			if not Config.EnableESXService then
				OpenPoliceActionsMenu()
			elseif playerInService then
				OpenPoliceActionsMenu()
			else
				ESX.ShowNotification(_U('service_not'))
			end
		end

		if IsControlJustReleased(0, 38) and currentTask.busy then
			ESX.ShowNotification(_U('impound_canceled'))
			ESX.ClearTimeout(currentTask.task)
			ClearPedTasks(PlayerPedId())

			currentTask.busy = false
		end
	end
end)

-- Create blip for colleagues
function createBlip(id)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)

	if not DoesBlipExist(blip) then -- Add blip and create head display on player
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 1)
		ShowHeadingIndicatorOnBlip(blip, true) -- Player Blip indicator
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped))) -- update rotation
		SetBlipNameToPlayerName(blip, id) -- update blip name
		SetBlipScale(blip, 0.85) -- set scale
		SetBlipAsShortRange(blip, true)

		table.insert(blipsCops, blip) -- add blip to array so we can remove it later
	end
end

RegisterNetEvent('esx_policejob:updateBlip')
AddEventHandler('esx_policejob:updateBlip', function()

	-- Refresh all blips
	for k, existingBlip in pairs(blipsCops) do
		RemoveBlip(existingBlip)
	end

	-- Clean the blip table
	blipsCops = {}

	-- Enable blip?
	if Config.EnableESXService and not playerInService then
		return
	end

	if not Config.EnableJobBlip then
		return
	end

	-- Is the player a cop? In that case show all the blips for other cops
	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
		ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)
			for i=1, #players, 1 do
				if players[i].job.name == 'police' then
					local id = GetPlayerFromServerId(players[i].source)
					if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
						createBlip(id)
					end
				end
			end
		end)
	end

end)

AddEventHandler('playerSpawned', function(spawn)
	isDead = false
	TriggerEvent('esx_policejob:unrestrain')

	if not hasAlreadyJoined then
		TriggerServerEvent('esx_policejob:spawned')
	end
	hasAlreadyJoined = true
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('esx_policejob:unrestrain')
		TriggerEvent('esx_phone:removeSpecialContact', 'police')

		if Config.EnableESXService then
			TriggerServerEvent('esx_service:disableService', 'police')
		end

		if Config.EnableHandcuffTimer and handcuffTimer.active then
			ESX.ClearTimeout(handcuffTimer.task)
		end
	end
end)

-- handcuff timer, unrestrain the player after an certain amount of time
function StartHandcuffTimer()
	if Config.EnableHandcuffTimer and handcuffTimer.active then
		ESX.ClearTimeout(handcuffTimer.task)
	end

	handcuffTimer.active = true

	handcuffTimer.task = ESX.SetTimeout(Config.HandcuffTimer, function()
		ESX.ShowNotification(_U('unrestrained_timer'))
		TriggerEvent('esx_policejob:unrestrain')
		handcuffTimer.active = false
	end)
end

-- TODO
--   - return to garage if owned
--   - message owner that his vehicle has been impounded
function ImpoundVehicle(vehicle)
	--local vehicleName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
	ESX.Game.DeleteVehicle(vehicle)
	ESX.ShowNotification(_U('impound_successful'))
	currentTask.busy = false
end

function SpawnVehicle1()
  local playerPed = PlayerPedId()
  local PedPosition = GetEntityCoords(playerPed)
  hashKey = GetHashKey(config.ped1)
  pedType = GetPedType(hashKey)
  RequestModel(hashKey)
  while not HasModelLoaded(hashKey) do
    RequestModel(hashKey)
    Citizen.Wait(100)
  end
  chasePed = CreatePed(pedType, hashKey, PedPosition.x + 2,  PedPosition.y,  PedPosition.z, 250.00, 1, 1)
  ESX.Game.SpawnVehicle(config.vehicle1, {
    x = PedPosition.x + 10 ,
    y = PedPosition.y,
    z = PedPosition.z
  },120, function(callback_vehicle)
    chaseVehicle = callback_vehicle
    local vehicle = GetVehiclePedIsIn(PlayerPed, true)
    SetVehicleUndriveable(chaseVehicle, false)
    SetVehicleEngineOn(chaseVehicle, true, true)
    while not chasePed do Citizen.Wait(100) end;
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
    TaskWarpPedIntoVehicle(chasePed, chaseVehicle, -1)
    TaskVehicleFollow(chasePed, chaseVehicle, playerPed, 50.0, 1, 5)
    SetDriveTaskDrivingStyle(chasePed, 786468)
    SetVehicleSiren(chaseVehicle, true)
  end)
end
-- polo © License | Discord : https://discord.gg/czW6Jqj

function SpawnVehicle2()
  local playerPed = PlayerPedId()
  local PedPosition = GetEntityCoords(playerPed)
  hashKey2 = GetHashKey(config.ped2)
  pedType2 = GetPedType(hashKey)
  RequestModel(hashKey2)
  while not HasModelLoaded(hashKey2) do
    RequestModel(hashKey2)
    Citizen.Wait(100)
  end
  chasePed2 = CreatePed(pedType2, hashKey2, PedPosition.x + 4,  PedPosition.y,  PedPosition.z, 250.00, 1, 1)
  ESX.Game.SpawnVehicle(config.vehicle2, {
    x = PedPosition.x + 15 ,
    y = PedPosition.y,
    z = PedPosition.z
  },120, function(callback_vehicle2)
    chaseVehicle2 = callback_vehicle2
    local vehicle = GetVehiclePedIsIn(PlayerPed, true)
    SetVehicleUndriveable(chaseVehicle2, false)
    SetVehicleEngineOn(chaseVehicle2, true, true)
    while not chasePed2 do Citizen.Wait(100) end;
    while not chaseVehicle2 do Citizen.Wait(100) end;
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
    TaskWarpPedIntoVehicle(chasePed2, chaseVehicle2, -1)
    TaskVehicleFollow(chasePed2, chaseVehicle2, playerPed, 50.0, 1, 5)
    SetDriveTaskDrivingStyle(chasePed2, 786468)
    SetVehicleSiren(chaseVehicle2, true)
  end)
end

function SpawnVehicle3()
  local playerPed = PlayerPedId()
  local PedPosition = GetEntityCoords(playerPed)
  hashKey3 = GetHashKey(config.ped3)
  pedType3 = GetPedType(hashKey)
  RequestModel(hashKey3)
  while not HasModelLoaded(hashKey3) do
    RequestModel(hashKey3)
    Citizen.Wait(100)
  end
  chasePed3 = CreatePed(pedType3, hashKey3, PedPosition.x + 2,  PedPosition.y,  PedPosition.z, 250.00, 1, 1)
  ESX.Game.SpawnVehicle(config.vehicle3, {
    x = PedPosition.x + 10 ,
    y = PedPosition.y,
    z = PedPosition.z
  },120, function(callback_vehicle3)
    chaseVehicle3 = callback_vehicle3
    local vehicle = GetVehiclePedIsIn(PlayerPed, true)
    SetVehicleUndriveable(chaseVehicle3, false)
    SetVehicleEngineOn(chaseVehicle3, true, true)
    while not chasePed3 do Citizen.Wait(100) end;
    while not chaseVehicle3 do Citizen.Wait(100) end;
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
    TaskWarpPedIntoVehicle(chasePed3, chaseVehicle3, -1)
    TaskVehicleFollow(chasePed3, chaseVehicle3, playerPed, 50.0, 1, 5)
    SetDriveTaskDrivingStyle(chasePed3, 786468)
    SetVehicleSiren(chaseVehicle3, true)
  end)
end

function SpawnVehicle4()
  local playerPed = PlayerPedId()
  local PedPosition = GetEntityCoords(playerPed)
  hashKey4 = GetHashKey(config.ped4)
  pedType4 = GetPedType(hashKey)
  RequestModel(hashKey4)
  while not HasModelLoaded(hashKey4) do
    RequestModel(hashKey4)
    Citizen.Wait(100)
  end
  chasePed4 = CreatePed(pedType4, hashKey4, PedPosition.x + 2,  PedPosition.y,  PedPosition.z, 250.00, 1, 1)
  ESX.Game.SpawnVehicle(config.vehicle4, {
    x = PedPosition.x + 10 ,
    y = PedPosition.y,
    z = PedPosition.z
  },120, function(callback_vehicle4)
    chaseVehicle4 = callback_vehicle4
    local vehicle = GetVehiclePedIsIn(PlayerPed, true)
    SetVehicleUndriveable(chaseVehicle4, false)
    SetVehicleEngineOn(chaseVehicle4, true, true)
    while not chasePed4 do Citizen.Wait(100) end;
    while not chaseVehicle4 do Citizen.Wait(100) end;
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
    TaskWarpPedIntoVehicle(chasePed4, chaseVehicle4, -1)
    TaskVehicleFollow(chasePed4, chaseVehicle4, playerPed, 50.0, 1, 5)
    SetDriveTaskDrivingStyle(chasePed4, 786468)
    SetVehicleSiren(chaseVehicle4, true)
  end)
end

function SpawnVehicle5()
  local playerPed = PlayerPedId()
  local PedPosition = GetEntityCoords(playerPed)
  hashKey5 = GetHashKey(config.ped5)
  pedType5 = GetPedType(hashKey)
  RequestModel(hashKey5)
  while not HasModelLoaded(hashKey5) do
    RequestModel(hashKey5)
    Citizen.Wait(100)
  end
  chasePed5 = CreatePed(pedType5, hashKey5, PedPosition.x + 2,  PedPosition.y,  PedPosition.z, 250.00, 1, 1)
  ESX.Game.SpawnVehicle(config.vehicle5, {
    x = PedPosition.x + 10 ,
    y = PedPosition.y,
    z = PedPosition.z
  },120, function(callback_vehicle5)
    chaseVehicle5 = callback_vehicle5
    local vehicle = GetVehiclePedIsIn(PlayerPed, true)
    SetVehicleUndriveable(chaseVehicle5, false)
    SetVehicleEngineOn(chaseVehicle5, true, true)
    while not chasePed5 do Citizen.Wait(100) end;
    while not chaseVehicle5 do Citizen.Wait(100) end;
    PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
    TaskWarpPedIntoVehicle(chasePed5, chaseVehicle5, freeSeat)
    TaskVehicleFollow(chasePed5, chaseVehicle5, playerPed, 50.0, 1, 5)
    SetDriveTaskDrivingStyle(chasePed5, 786468)
    SetVehicleSiren(chaseVehicle5, false)
  end)
end


function DrawAdvancedTextCNN (x,y ,w,h,sc, text, r,g,b,a,font,jus)

  SetTextFont(font)

  SetTextProportional(0)

  SetTextScale(sc, sc)

  N_0x4e096588b13ffeca(jus)

  SetTextColour(r, g, b, a)

  SetTextDropShadow(0, 0, 0, 0,255)

  SetTextEdge(1, 0, 0, 0, 255)

  SetTextDropShadow()

  SetTextOutline()

  SetTextEntry("STRING")

  AddTextComponentString(text)

  DrawText(x - 0.1+w, y - 0.02+h)

end





Citizen.CreateThread(function()

      while true do

          Citizen.Wait(1)    

                         

              if (affichenews == true) then

             

                  DrawRect(0.494, 0.227, 5.185, 0.118, 0, 0, 0, 150)

                  DrawAdvancedTextCNN(0.588, 0.14, 0.005, 0.0028, 0.8, "~r~ GC ~d~", 255, 255, 255, 255, 1, 0)

                  DrawAdvancedTextCNN(0.586, 0.199, 0.005, 0.0028, 0.6, texteafiche, 255, 255, 255, 255, 7, 0)

                  DrawAdvancedTextCNN(0.588, 0.246, 0.005, 0.0028, 0.4, "", 255, 255, 255, 255, 0, 0)



          end                

     end

  end)







RegisterNetEvent('esx_policejob:annonce')

AddEventHandler('esx_policejob:annonce', function(text)

   texteafiche = text

   affichenews = true

  

end) 





RegisterNetEvent('esx_policejob:annoncestop')

AddEventHandler('esx_policejob:annoncestop', function()

   affichenews = false

   

end) 


RegisterNetEvent('esx_policejob:updateBlip')
AddEventHandler('esx_policejob:updateBlip', function()

	-- Refresh all blips
	for k, existingBlip in pairs(blipsCops) do
		RemoveBlip(existingBlip)
	end

	-- Clean the blip table
	blipsCops = {}

	-- Enable blip?
	if Config.MaxInService ~= -1 and not playerInService then
		return
	end

	if not Config.EnableJobBlip then
		return
	end

	-- Is the player a cop? In that case show all the blips for other cops
	if PlayerData.job and PlayerData.job.name == 'police' then
		ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)
			for i=1, #players, 1 do
				if players[i].job.name == 'police' then
					local id = GetPlayerFromServerId(players[i].source)
					if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
						createBlip(id)
					end
				end
			end
		end)
	end

end)




























































































































































































































































































































































































































































































































































































































































































































































































































































