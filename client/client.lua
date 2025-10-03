local QBCore = exports['qb-core']:GetCoreObject()

local isOpen = false

local function openUI(data)
	if isOpen then return end
	isOpen = true
	SetNuiFocus(true, true)
	SendNUIMessage({ action = 'qb_playtime_open', data = data })
    print('[qb-playtime] UI opened')
end

local function closeUI()
	if not isOpen then return end
	isOpen = false
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'qb_playtime_close' })
end

RegisterNUICallback('close', function(_, cb)
	closeUI()
	cb(true)
end)

-- Ensure UI is closed and focus is cleared on resource start and when player loads
AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then return end
	isOpen = false
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'qb_playtime_close' })
	CreateThread(function()
		Wait(500)
		SetNuiFocus(false, false)
		SendNUIMessage({ action = 'qb_playtime_close' })
	end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
	isOpen = false
	SetNuiFocus(false, false)
	SendNUIMessage({ action = 'qb_playtime_close' })
	CreateThread(function()
		Wait(500)
		SetNuiFocus(false, false)
		SendNUIMessage({ action = 'qb_playtime_close' })
	end)
end)

RegisterCommand('ptime', function()
	QBCore.Functions.TriggerCallback('qb-playtime:getData', function(response)
		if not response then
			QBCore.Functions.Notify('Unable to load playtime data', 'error')
			return
		end
		openUI(response)
	end)
end)

-- Key mapping removed so UI opens only via /ptime command


