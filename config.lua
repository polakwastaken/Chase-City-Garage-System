Config = {}

-- Spawn-Verhalten
Config.SpawnCooldown = 3 -- Cooldown zwischen Auspark-Vorgängen in Sekunden
Config.RequireClearSpawn = true -- Nur spawnen, wenn Spawnpunkt frei ist
Config.SpawnClearRadius = 3.0 -- Radius für Frei-Prüfung am Spawnpunkt

-- Optionaler /dv Command
Config.AllowDVCommand = true -- Wenn false, wird /dv gar nicht registriert
Config.DVRadius = 2.0 -- Standardradius für /dv ohne Parameter

-- Marker-/Render-Einstellungen
Config.DrawDistance = 20.0
Config.MarkerType = 1
Config.MarkerScale = vector3(1.5, 1.5, 1.0)

-- Garagen-Standorte
Config.Garages = {
    {
        name = "Garage", -- Interner Name
        blip = true, -- Blip für diese Garage anzeigen
        blipSprite = 357,
        blipColor = 3,
        blipScale = 0.7,
        blipName = "Oleg Brechstange", -- Blip-Anzeige im Spiel

        menuCoords = vector3(214.5193, -806.4205, 30.8150), -- Marker zum Garagen-Menü öffnen
        storeCoords = vector3(215.8280, -787.9207, 30.8293), -- Marker zum Einparken
        spawnCoords = vector4(232.1140, -794.0580, 30.5802, 159.4393), -- Fester Ausparkpunkt (x,y,z,h)

        menuRadius = 3.0, -- Interaktionsradius am Menü-Marker
        storeRadius = 5.0 -- Interaktionsradius am Store-Marker
    }
}

-- Einpark-Marker
Config.StoreMarker = {
    type = 1,
    scale = vector3(6.0, 6.0, 0.8),
    color = {r = 255, g = 255, b = 255, a = 120}
}

-- Kategorienamen + Reihenfolge im Garagen-Menü (key muss zur vehicles.category passen)
Config.CategoryLabels = {
    { key = "zivistreet", label = "Zivil Street" },
    { key = "copstreet", label = "Police Street" },
    { key = "zivioffroad", label = "Zivil Offroad" },
    { key = "copoffroad", label = "Police Offroad" },
    { key = "zivihyper", label = "Zivil Hypercars" },
    { key = "cophyper", label = "Police Hyper" },
    { key = "other", label = "Sonstige" }
}

-- Optionale Anzeigenamen für einzelne Fahrzeuge (key = Spawnname in Kleinbuchstaben)
Config.VehicleLabels = {
    adder = "Bugatti Veyron"
}