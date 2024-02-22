-- quick start computercraft farm program
-- First thing is to connect to a websocket server
--   ws://localhost:8091

local host = "cctweak.qinbeans.net"

-- Request Types
--  move X
--  break X
--  place X
--  lookDown X
--  checkInventory X
--  checkFuel X
--  refuel X
--  checkExternal X
--  out X
--  in X
-- struct for Requests
Requests = {
    ["type"] = "",
    ["id"] = "",
    ["data"] = {}
}

-- Response Types
--  report
--  bye
-- struct for Responses
Response = {
    ["type"] = "",
    ["id"] = "",
    ["data"] = {}
}

local MAX_INDEX = 16

DirectionIn = {
    front = turtle.suck,
    down = turtle.suckDown,
    up = turtle.suckUp
}

DirectionOut = {
    front = turtle.drop,
    down = turtle.dropDown,
    up = turtle.dropUp
}

RequestMap = {
    ["checkExternal"] = CheckExternal,
    ["in"] = In,
    ["out"] = Out,
    ["lookDown"] = LookDown,
    ["break"] = BreakOrTil,
    ["place"] = Place,
    ["checkInventory"] = CheckInventory,
    ["checkFuel"] = CheckFuel,
    ["refuel"] = Refuel
}

function Response:new(type, id, data)
    local response = {}
    setmetatable(response, self)
    self.__index = self
    response.type = type
    response.id = id
    response.data = data
    return response
end

function CheckExternal(data) 
    local inventory = {}
    local name = data.name
    local external = peripheral.find(name)
    for slot, item in pairs(external.list()) do
        item.index = slot
        table.insert(inventory, item)
    end
    return Response:new("report", "", {["inventory"] = inventory})
end

-- Inputs items from an external inventory to the turtle
function In(data)
    local count = data.count
    local direction = data.direction
    if count < 1 or count > 64 then
        return Response:new("report", "", {["error"] = "Count out of range"})
    end
    local ok = DirectionIn[direction](count)
    if ok then
        return Response:new("report", "", {["status"] = "ok"})
    else
        return Response:new("report", "", {["error"] = "No items to input"})
    end
end

-- Outputs items from the turtle to an external inventory
function Out(data)
    local count = data.count
    local direction = data.direction
    if count < 1 or count > 64 then
        return Response:new("report", "", {["error"] = "Count out of range"})
    end
    local ok = DirectionOut[direction](count)
    if ok then
        return Response:new("report", "", {["status"] = "ok"})
    else
        return Response:new("report", "", {["error"] = "No items to output"})
    end
end

function LookDown() 
    local isBlock, detail = turtle.inspectDown()
    if isBlock then
        if detail.name == "minecraft:grass_block" or detail.name == "minecraft:grass_block" then
            return Response:new("report", "", {["blockType"] = "tilable"})
        elseif detail.name == "minecraft:farmland" then
            return Response:new("report", "", {["blockType"] = "tilled"})
        end
    end
    return Response:new("report", "", {["blockType"] = ""})
end

function BreakOrTil(data) 
    local steps = data["steps"]
    for i = 1, steps do
        local canDig, err = turtle.digDown()
        if not canDig then
            return Response:new("report", "", {["error"] = err})
        end
        local canMove, err = turtle.forward()
        if not canMove then
            return Response:new("report", "", {["error"] = err})
        end
    end
    return Response:new("report", "", {["status"] = "broken", ["steps"] = steps})
end

function Place(data) 
    local steps = data["steps"]
    local index = data["index"]
    local name = turtle.getItemDetail(index).name
    if index < 1 or index > MAX_INDEX then
        return Response:new("report", "", {["error"] = "Index out of range"})
    end
    
    -- if name doesn't contain "seed" then return error
    if not string.find(name, "seed") then
        return Response:new("report", "", {["error"] = "Not a seed"})
    end

    for i = 1, steps do
        local canPlace, err = turtle.placeDown(index)
        if not canPlace then
            return Response:new("report", "", {["error"] = err})
        end
        local canMove, err = turtle.forward()
        if not canMove then
            return Response:new("report", "", {["error"] = err})
        end
    end

    return Response:new("report", "", {["status"] = "placed", ["steps"] = steps})
end

function CheckInventory() 
    local inventory = {}
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        if item then
            item["index"] = i
            table.insert(inventory, item)
        end
    end
    return Response:new("report", "", {["inventory"] = inventory})
end

function CheckFuel() 
    local fuelLevel = turtle.getFuelLevel()
    return Response:new("report", "", {["level"] = fuelLevel})
end

function Refuel(data) 
    local fuelLevel = turtle.getFuelLevel()
    local amount = data["amount"]
    local ok = turtle.refuel(amount)
    if ok then
        return Response:new("report", "", {["status"] = "ok", ["level"] = fuelLevel})
    end
    return Response:new("report", "", {["status"] = "error", ["level"] = fuelLevel})
end

function GetId() 
    local request = "https://" .. host .. "/api/connect"
    local body = textutils.unserialiseJSON(http.post(request, "").readAll())
    return body.id
end

function Attach()
    local id = GetId()
    local request = "wss://" .. host .. "/api/ws?id=" .. id
    local handle = http.websocket(request)

    print("Connected to " .. host)
    
    while true do
        local message = handle.receive()
        if message then
            local request = textutils.unserialize(message)
            if request == nil then
                if message == "hello" then
                    print("Received hello")
                    handle.send(textutils.serialize(Response:new("report", "", {["status"] = "ok"})))
                else
                    print("Received unknown message")
                end
            else
                local response = RequestMap[request.type](request.data)
                handle.send(textutils.serialize(response))
            end
        end
    end
end

Attach()