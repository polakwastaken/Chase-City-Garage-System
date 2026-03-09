ESX = exports["es_extended"]:getSharedObject()

local menuPool = NativeUI.CreatePool()
local garageMenuOpen = false
local lastSpawnTime = 0

RegisterKeyMapping("garage", "Garagenmenu öffnen", "keyboard", "F5")

local function normalizePlate(plate)
    if type(plate) ~= "string" then
        return nil
    end

    local normalized = string.upper((plate:gsub("^%s*(.-)%s*$", "%1")))
    if normalized == "" then
        return nil
    end

    return normalized
end

local function fixVehicleBeforeStore(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
end

local function acquireEntityControl(entity)
    if not DoesEntityExist(entity) then
        return false
    end

    if NetworkHasControlOfEntity(entity) then
        return true
    end

    NetworkRequestControlOfEntity(entity)

    local attempts = 0
    while attempts < 15 do
        if NetworkHasControlOfEntity(entity) then
            return true
        end

        Citizen.Wait(0)
        NetworkRequestControlOfEntity(entity)
        attempts = attempts + 1
    end

    return NetworkHasControlOfEntity(entity)
end

Citizen.CreateThread(function()
    while true do
        if garageMenuOpen and menuPool:IsAnyMenuOpen() then
            menuPool:ProcessMenus()
            Citizen.Wait(0)
        else
            Citizen.Wait(250)
        end
    end
end)

Citizen.CreateThread(function()
    for _, g in pairs(Config.Garages) do
        if g.blip then
            local blip = AddBlipForCoord(g.menuCoords)
            SetBlipSprite(blip, g.blipSprite)
            SetBlipScale(blip, g.blipScale)
            SetBlipColour(blip, g.blipColor)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(g.blipName)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1500

        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        for _, g in pairs(Config.Garages) do
            local dist = #(coords - g.menuCoords)
            local sdist = #(coords - g.storeCoords)

            if dist < Config.DrawDistance then
                sleep = 0

                DrawMarker(
                    Config.MarkerType,
                    g.menuCoords.x, g.menuCoords.y, g.menuCoords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.MarkerScale.x, Config.MarkerScale.y, Config.MarkerScale.z,
                    255, 255, 255, 150,
                    false, true, 2, false, nil, nil, false
                )

                if dist < g.menuRadius then
                    ESX.ShowHelpNotification("Drücke ~INPUT_CONTEXT~ für Garage")

                    if IsControlJustPressed(0, 38) and not menuPool:IsAnyMenuOpen() then
                        OpenGarage(g.spawnCoords)
                    end
                end
            end

            if sdist < Config.DrawDistance then
                sleep = 0

                DrawMarker(
                    Config.StoreMarker.type,
                    g.storeCoords.x, g.storeCoords.y, g.storeCoords.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    Config.StoreMarker.scale.x,
                    Config.StoreMarker.scale.y,
                    Config.StoreMarker.scale.z,
                    Config.StoreMarker.color.r,
                    Config.StoreMarker.color.g,
                    Config.StoreMarker.color.b,
                    Config.StoreMarker.color.a,
                    false, true, 2, false, nil, nil, false
                )

                if sdist < g.storeRadius and IsPedInAnyVehicle(ped, false) then
                    ESX.ShowHelpNotification("Drücke ~INPUT_CONTEXT~ zum Einparken")

                    if IsControlJustPressed(0, 38) then
                        StoreVehicle()
                    end
                end
            end
        end

        Citizen.Wait(sleep)
    end
end)

RegisterCommand("garage", function()
    if menuPool:IsAnyMenuOpen() then
        return
    end

    OpenGarage(nil)
end, false)

TriggerEvent("chat:addSuggestion", "/garage", "Öffnet das Garagenmenu")

if Config.AllowDVCommand then
    RegisterCommand("dv", function(_, args)
        local radius = tonumber(args[1]) or Config.DVRadius
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local vehicles = ESX.Game.GetVehiclesInArea(coords, radius)

        for _, veh in pairs(vehicles) do
            if DoesEntityExist(veh) then
                fixVehicleBeforeStore(veh)

                local props = ESX.Game.GetVehicleProperties(veh)
                if props and props.plate then
                    TriggerServerEvent("cc_garage:storeVehicle", props)
                end

                if acquireEntityControl(veh) then
                    DeleteEntity(veh)
                end
            end
        end
    end, false)

    TriggerEvent("chat:addSuggestion", "/dv", "Löscht Fahrzeuge im Radius.", {
        { name = "radius", help = "Optionaler Radius in Metern" }
    })
end

function OpenGarage(spawnOverride)
    if garageMenuOpen or menuPool:IsAnyMenuOpen() then
        return
    end

    garageMenuOpen = true
    menuPool = NativeUI.CreatePool()

    ESX.TriggerServerCallback("cc_garage:getGarageData", function(vehicles)
        local grouped = {}

        for i = 1, #vehicles do
            local props = vehicles[i]
            local cat = props.garageCategory or "other"

            if not grouped[cat] then
                grouped[cat] = {}
            end

            table.insert(grouped[cat], props)
        end

        local mainMenu = NativeUI.CreateMenu("Garage", "Fahrzeugklassen")
        menuPool:Add(mainMenu)

        local categories = {}
        local added = {}

        if Config.CategoryLabels then
            for _, entry in ipairs(Config.CategoryLabels) do
                local cat = entry.key
                local list = grouped[cat]

                if cat and list and #list > 0 then
                    table.insert(categories, {
                        label = entry.label or cat,
                        list = list
                    })
                    added[cat] = true
                end
            end
        end

        for cat, list in pairs(grouped) do
            if not added[cat] and list and #list > 0 then
                table.insert(categories, {
                    label = cat,
                    list = list
                })
            end
        end

        for _, categoryData in ipairs(categories) do
            local list = categoryData.list
            local label = categoryData.label

            local catSubMenu = menuPool:AddSubMenu(mainMenu, label, "Fahrzeuge")
            catSubMenu.Item:RightLabel(">>>")

            for _, props in ipairs(list) do
                local spawnName = string.lower(GetDisplayNameFromVehicleModel(props.model))
                local niceName = props.garageName or spawnName

                if Config.VehicleLabels and Config.VehicleLabels[spawnName] then
                    niceName = Config.VehicleLabels[spawnName]
                end

                local plate = normalizePlate(props.plate) or "UNKNOWN"
                local text = string.format("%s | %s | %s", plate, niceName, spawnName)
                local vitem = NativeUI.CreateItem(text, "Ausparken")
                catSubMenu.SubMenu:AddItem(vitem)

                vitem.Activated = function()
                    if (GetGameTimer() - lastSpawnTime) / 1000 < Config.SpawnCooldown then
                        ESX.ShowNotification("Cooldown aktiv.")
                        return
                    end

                    lastSpawnTime = GetGameTimer()
                    garageMenuOpen = false
                    mainMenu:Visible(false)
                    catSubMenu.SubMenu:Visible(false)

                    SpawnVehicle(props, spawnOverride)
                end
            end
        end

        if #categories == 0 then
            ESX.ShowNotification("Keine gekauften Fahrzeuge gefunden.")
            garageMenuOpen = false
            return
        end

        mainMenu:Visible(true)
        menuPool:RefreshIndex()

        Citizen.CreateThread(function()
            while garageMenuOpen do
                Citizen.Wait(200)
                if not menuPool:IsAnyMenuOpen() then
                    garageMenuOpen = false
                    break
                end
            end
        end)
    end)
end

function SpawnVehicle(props, spawnOverride)
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped then
        local current = GetVehiclePedIsIn(ped, false)

        fixVehicleBeforeStore(current)
        local currentProps = ESX.Game.GetVehicleProperties(current)

        TriggerServerEvent("cc_garage:storeVehicle", currentProps)
        if acquireEntityControl(current) then
            DeleteVehicle(current)
        end
        DoSpawn(props, spawnOverride)

        return
    end

    DoSpawn(props, spawnOverride)
end

function DoSpawn(props, spawnOverride)
    local ped = PlayerPedId()
    local coords
    local heading

    if spawnOverride then
        coords = vector3(spawnOverride.x, spawnOverride.y, spawnOverride.z)
        heading = spawnOverride.w
    else
        coords = GetEntityCoords(ped)
        heading = GetEntityHeading(ped)
    end

    if Config.RequireClearSpawn and not ESX.Game.IsSpawnPointClear(coords, Config.SpawnClearRadius) then
        ESX.ShowNotification("Spawnpunkt ist blockiert.")
        return
    end

    ESX.Game.SpawnVehicle(props.model, coords, heading, function(vehicle)
        ESX.Game.SetVehicleProperties(vehicle, props)
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        TriggerServerEvent("cc_garage:setOut", props.plate)
    end)
end

function StoreVehicle()
    local ped = PlayerPedId()

    if not IsPedInAnyVehicle(ped, false) then
        return
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetPedInVehicleSeat(vehicle, -1) ~= ped then
        ESX.ShowNotification("Du musst Fahrer sein.")
        return
    end

    fixVehicleBeforeStore(vehicle)
    local props = ESX.Game.GetVehicleProperties(vehicle)
    TriggerServerEvent("cc_garage:storeVehicle", props)
    if acquireEntityControl(vehicle) then
        DeleteVehicle(vehicle)
    end
end