# Chase City Garage System

ESX Garagenscript für FiveM.

## Übersicht

- Garage öffnen per Marker (in Config einstellbar) oder Command (`/garage`, Keybind `F5`)
- Kein Impound-System
- Fahrzeuge werden aus `owned_vehicles` geladen
- Kategorien kommen aus der Tabelle `vehicles` und werden über `config.lua` benannt/sortiert
- Einparken per Menu/Marker.
- Optionaler `/dv [radius]` Command (per Config deaktivierbar)
- Restart-Recovery setzt bei Resource-Start alle Fahrzeuge wieder in die Garage
- leicht ersetzbar mit ESX-Garage
- kompatibel mit ESX-Vehicleshop

## Voraussetzungen

- FiveM Server (fxserver)
- ESX Legacy (`es_extended`)
- `mysql-async`
- NativeUI (`@NativeUI/src/NativeUIReloaded.lua`)

## Installation

1. Resource in den Serverordner legen, z. B. `resources/[local]/cc_garage`.
2. Prüfen, dass Abhängigkeiten in min. folgender Reihenfolge gestartet werden:
   - `es_extended`
   - `mysql-async`
   - `NativeUI`
3. In `server.cfg` eintragen:

```cfg
ensure cc_garage
```

## Datenbank-Anforderungen

Das Script nutzt diese Tabellen (sind standardmäßig so enthalten):

- `owned_vehicles`
  - benötigte Felder: `owner`, `plate`, `vehicle`, `stored`
- `vehicles`
  - benötigte Felder: `model`, `name`, `category`

Verhalten:

- Beim Ausparken: `owned_vehicles.stored = 0`
- Beim Einparken: `owned_vehicles.vehicle` wird aktualisiert und `stored = 1`

## Konfiguration (`config.lua`)

Aktuelle Standardkonfiguration:

```lua
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
```

## Commands

- `/garage` oder `F5`
  - Öffnet das Garagenmenu

- `/dv [radius]`
  - Nur aktiv, wenn `Config.AllowDVCommand = true`
  - Entfernt Fahrzeuge im Radius

## Standard-Nutzung

1. Zum Garage-Marker fahren und `E` drücken oder per `F5` Menü öffnen.
2. Fahrzeug aus dem Menü ausparken.
3. Zum Store-Marker fahren und als Fahrer `E` drücken oder per `/dv` Command Fahrzeug löschen.
4. Fahrzeug wird repariert, gespeichert und entfernt.

## Troubleshooting

- Garage zeigt keine Fahrzeuge:
  - Prüfen, ob Datensätze in `owned_vehicles` vorhanden sind
  - Prüfen, ob `stored = 1` gesetzt ist
  - Prüfen, ob `owner` zur Spieler-Identifier passt
- Falsche Kategorienamen:
  - `vehicles.category` in DB prüfen
  - `Config.CategoryLabels` auf passende `key` Werte prüfen
- `/dv` funktioniert nicht:
  - `Config.AllowDVCommand` auf `true` setzen
  - Resource neu starten

## MIT Lizenz

Dieses Projekt ist unter der MIT Lizenz veröffentlicht.
