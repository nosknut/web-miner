-- https://github.com/LemADEC/WarpDrive/wiki
-- https://github.com/nosknut/web-miner/blob/main/web-remote.lua

local osAdapter = require("os-oc-adapter")

local SPREADSHEET_URL =
"https://docs.google.com/spreadsheets/d/1-Gt65A1KFmbqph36-CFq6dNlJEtZex0EZXSSg_QPPKo/edit#gid=905815096"

local SHIP_DIMMENSIONS = {
    front = 7,
    back = 8,
    right = 12,
    left = 3,
    up = 6,
    down = 2,
}

local DESTINATIONS = {
    ["Base"] = {
        planet = "Earth",
        galaxy = "MilkyWay",
        coordinates = {
            ground = {
                x = 259,
                y = 70,
                z = 807,
            },
            orbit = {
                x = -10999,
                y = 247,
                z = -12675,
            },
            hyperspace = {
                x = -10999,
                y = 247,
                z = -12675,
            },
        },
    },
    ["Atlantis"] = {
        planet = "Lantea",
        galaxy = "Pegasus",
        coordinates = {
            ground = {
                x = 0,
                y = 0,
                z = 0,
            },
            orbit = {
                x = 0,
                y = 0,
                z = 0,
            },
            hyperspace = {
                x = 0,
                y = 0,
                z = 0,
            },
        }
    }
}

local function updateShipDimmensions(ship)
    ship.dim_positive(
        SHIP_DIMMENSIONS.front,
        SHIP_DIMMENSIONS.right,
        SHIP_DIMMENSIONS.up
    )

    ship.dim_negative(
        SHIP_DIMMENSIONS.back,
        SHIP_DIMMENSIONS.left,
        SHIP_DIMMENSIONS.down
    )
end

local function getSpreadsheet()
    local response = osAdapter.getRequest(SPREADSHEET_URL)

    return {
        summon = true,
        update = false,
        liftMode = "down",
        targetLocation = "Base",
        targetCoordinates = {
            x = 0,
            y = 0,
            z = 0
        },
    }
end

local function getCurrentPosition(ship)
    local x, y, z = ship.position()
    return {
        coordinates = {
            x = x,
            y = y,
            z = z,
        },
        inSpace = ship.isInSpace(),
        inPlanet = ship.isInPlanet(),
        inHyperspace = ship.isInHyperspace(),
        galaxy = ship.galaxyName(),
        planet = ship.planetName(),
    }
end

local function enterHypespace(ship)
    print("Entering hyperspace...")
    ship.mode(5)
    ship.jump()
    osAdapter.reboot()
end

local function leaveHyperspace(ship)
    print("Leaving hyperspace...")
    ship.mode(5)
    ship.jump()
    osAdapter.reboot()
end

local function leavePlanet(ship)
    print("Leaving planet...")
    ship.mode(1)
    ship.movement(0, 500, 0)
    ship.jump()
    osAdapter.reboot()
end

local function enterPlanet(ship)
    print("Entering planet...")
    ship.mode(1)
    ship.movement(0, -500, 0)
    ship.jump()
    osAdapter.reboot()
end

local function navigateToHyperspace(ship, currentPosition)
    if currentPosition.inPlanet then
        leavePlanet(ship)
    end

    if currentPosition.inSpace then
        enterHypespace(ship)
    end
end

local function navigateToSpace(ship, currentPosition)
    if currentPosition.inPlanet then
        leavePlanet(ship)
    end

    if currentPosition.inHyperspace then
        leaveHyperspace(ship)
    end
end

local function navigateToPlanet(ship, currentPosition)
    if currentPosition.inHyperspace then
        leaveHyperspace(ship)
    end

    if currentPosition.inSpace then
        enterPlanet(ship)
    end
end

local function navigateToCoordinates(ship, currentCoordinates, targetCoordinates)
    local front = targetCoordinates.x - currentCoordinates.x
    local up = targetCoordinates.y - currentCoordinates.y
    local right = targetCoordinates.z - currentCoordinates.z

    if front == 0 and up == 0 and right == 0 then
        print("Already at coordinates!")
        return
    end

    print("Navigating to coordinates:")
    print("X: " .. targetCoordinates.x)
    print("Y: " .. targetCoordinates.y)
    print("Z: " .. targetCoordinates.z)

    print("Moving:")
    print("Front: " .. front)
    print("Up: " .. up)
    print("Right: " .. right)

    print("Jumping...")
    ship.mode(1)
    ship.movement(front, up, right)
    ship.jump()
    osAdapter.reboot()
end

local function navigateToTargetLocation(ship, spreadsheet)
    local currentPosition = getCurrentPosition(ship)

    if spreadsheet.targetLocation == "hyperspace" then
        navigateToHyperspace(ship, currentPosition)
    end

    if spreadsheet.targetLocation == "space" then
        navigateToSpace(ship, currentPosition)
    end

    if spreadsheet.targetLocation == "planet" then
        navigateToPlanet(ship, currentPosition)
    end

    if spreadsheet.targetLocation == "coordinates" then
        navigateToCoordinates(ship, currentPosition, spreadsheet.targetCoordinates)
    end

    local destination = DESTINATIONS[spreadsheet.targetLocation]

    if destination == nil then
        print("Error: Invalid target destination:")
        print(spreadsheet.targetLocation)
        osAdapter.reboot()
    else
        print("Navigating to " .. spreadsheet.targetLocation .. "...")
        if currentPosition.galaxy ~= destination.galaxy then
            print("Jumping to " .. destination.galaxy .. "...")
            navigateToHyperspace(ship, currentPosition)
            navigateToCoordinates(ship, currentPosition, destination.coordinates.hyperspace)
            navigateToPlanet(ship, currentPosition)
        elseif currentPosition.planet ~= destination.planet then
            print("Jumping to " .. destination.planet .. "...")
            navigateToSpace(ship, currentPosition)
            navigateToCoordinates(ship, currentPosition, destination.coordinates.space)
            navigateToPlanet(ship, currentPosition)
        elseif
            currentPosition.coordinates.x ~= destination.coordinates.planet.x or
            currentPosition.coordinates.y ~= destination.coordinates.planet.y or
            currentPosition.coordinates.z ~= destination.coordinates.planet.z
        then
            navigateToCoordinates(ship, currentPosition, destination.coordinates.planet)
        end
    end
end

while true do
    local ship = osAdapter.getShip()
    updateShipDimmensions(ship)

    local spreadsheet = getSpreadsheet()

    osAdapter.clearTerminal()

    if spreadsheet.update then
        osAdapter.update()
    end

    print("Summon players:", spreadsheet.summon)
    print("Lift mode:", spreadsheet.liftMode)

    print("Target Location:", spreadsheet.targetLocation)

    if spreadsheet.summon then
        ship.summon_all()
        osAdapter.sleep(3)
    end

    local redstone = osAdapter.getRedstone()
    if redstone ~= nil then
        if spreadsheet.liftMode == "up" then
            redstone.setOutput(4, 0)
        elseif spreadsheet.liftMode == "down" then
            redstone.setOutput(4, 15)
        end
        osAdapter.sleep(3)
    end

    navigateToTargetLocation(ship, spreadsheet)
    
    osAdapter.sleep(5)
end
