local component = require("component")
local internet = require("internet")
local computer = require("computer")
local term = require("term")
local os = require("os")

local WEB_REMOTE_URL = "https://github.com/nosknut/web-miner/blob/main/web-remote.lua"
local OS_OC_ADAPTER_URL = "https://github.com/nosknut/web-miner/blob/main/web-remote.lua"

osAdapter = {}

function osAdapter.sleep(seconds)
    os.sleep(seconds)
end

function osAdapter.reboot()
    print("Rebooting...")
    osAdapter.sleep(3)
    computer.shutdown(true)
end

function osAdapter.getShip()
    local ship = component.warpdriveShipController

    if not (ship == nil) then
        return ship
    end

    print("Error: core not connected!")
    osAdapter.reboot()
end

function osAdapter.getRedstone()
    local redstone = component.redstone

    if redstone == nil then
        print("Error: redstone not connected!")
    end

    return redstone
end

function osAdapter.clearTerminal()
    term.clear()
    term.setCursor(1, 1)
end

function osAdapter.getRequest(url)
    local _, response = internet.request(url)
    return response
end

local function getFile(url)
    local response = osAdapter.getRequest(url)
    return response.readAll()
end

local function writeFile(content, path)
    local file = io.open(path, "w")

    if file == nil then
        print("Error: Could not open file!")
        return
    end

    file:write(content)
    file:close()
end

function osAdapter.update()
    print("Downloading...")

    writeFile(getFile(WEB_REMOTE_URL), "/home/web-remote.lua")
    writeFile(getFile(OS_OC_ADAPTER_URL), "/home/os-oc-adapter.lua")

    print("Updated!")
    osAdapter.reboot()
end
