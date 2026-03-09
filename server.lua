ESX = exports["es_extended"]:getSharedObject()

local vehicleMetaByHashCache = nil
local storeThrottle = {}

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

local function getIdentifier(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return nil
    end

    return xPlayer.identifier
end

local function getModelHashKey(model)
    if type(model) ~= "string" then
        return nil
    end

    return tostring(GetHashKey(model))
end

local function loadVehicleMetaByHash(cb)
    if vehicleMetaByHashCache then
        cb(vehicleMetaByHashCache)
        return
    end

    MySQL.Async.fetchAll(
        "SELECT model, name, category FROM vehicles",
        {},
        function(result)
            local map = {}

            for i = 1, #result do
                local model = result[i].model
                local name = result[i].name
                local category = result[i].category

                if model then
                    local modelHash = getModelHashKey(model)

                    if modelHash then
                        map[modelHash] = {
                            name = name or model,
                            category = category or "other"
                        }
                    end
                end
            end

            vehicleMetaByHashCache = map
            cb(vehicleMetaByHashCache)
        end
    )
end

ESX.RegisterServerCallback("cc_garage:getGarageData", function(source, cb)
    local identifier = getIdentifier(source)
    if not identifier then
        cb({})
        return
    end

    MySQL.Async.fetchAll(
        "SELECT vehicle, plate FROM owned_vehicles WHERE owner = @owner AND stored = 1",
        { ["@owner"] = identifier },
        function(result)
            local vehicles = {}

            loadVehicleMetaByHash(function(vehicleMetaByHash)
                for i = 1, #result do
                    local decoded = nil
                    local rawVehicle = result[i].vehicle

                    if type(rawVehicle) == "string" and rawVehicle ~= "" then
                        local ok, parsed = pcall(json.decode, rawVehicle)
                        if ok and type(parsed) == "table" then
                            decoded = parsed
                        end
                    end

                    if type(decoded) == "table" then
                        decoded.plate = normalizePlate(decoded.plate or result[i].plate)

                        if decoded.plate and decoded.model then
                            local meta = vehicleMetaByHash[tostring(decoded.model)]

                            decoded.garageName = meta and meta.name or tostring(decoded.model)
                            decoded.garageCategory = meta and meta.category or "other"

                            table.insert(vehicles, decoded)
                        end
                    end
                end

                cb(vehicles)
            end)
        end
    )
end)

RegisterNetEvent("cc_garage:setOut")
AddEventHandler("cc_garage:setOut", function(plate)
    local src = source
    local identifier = getIdentifier(src)
    local normalizedPlate = normalizePlate(plate)

    if not identifier or not normalizedPlate then
        return
    end

    MySQL.Async.execute(
        "UPDATE owned_vehicles SET stored = 0 WHERE plate = @plate AND owner = @owner AND stored = 1",
        {
            ["@plate"] = normalizedPlate,
            ["@owner"] = identifier
        }
    )
end)

RegisterNetEvent("cc_garage:storeVehicle")
AddEventHandler("cc_garage:storeVehicle", function(props)
    local src = source

    local now = GetGameTimer()
    local last = storeThrottle[src] or 0
    if now - last < 200 then
        return
    end

    storeThrottle[src] = now

    if type(props) ~= "table" then
        return
    end

    local normalizedPlate = normalizePlate(props.plate)
    if not normalizedPlate then
        return
    end

    props.plate = normalizedPlate

    MySQL.Async.execute(
        "UPDATE owned_vehicles SET vehicle = @vehicle, stored = 1 WHERE plate = @plate LIMIT 1",
        {
            ["@vehicle"] = json.encode(props),
            ["@plate"] = normalizedPlate
        }
    )
end)

AddEventHandler("playerDropped", function()
    storeThrottle[source] = nil
end)

local function resetImpoundVehiclesOnStart()
    MySQL.Async.execute("UPDATE owned_vehicles SET stored = 1 WHERE stored = 0", {}, function(changed)
        print(("Restart-Recovery: %s Fahrzeug(e) in Garage gesetzt."):format(changed or 0))
    end)
end

AddEventHandler("onResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    resetImpoundVehiclesOnStart()
end)

--RegisterCommand("cc_garage_recover", function(source) -- kann für Debug und manuelle Wiederherstellung von Fahrzeugen genutzt werden.
    --if source ~= 0 then
        --return
    --end

    --resetImpoundVehiclesOnStart()
--end, true)