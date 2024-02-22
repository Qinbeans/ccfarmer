Response = {
    ["type"] = "",
    ["id"] = "",
    ["data"] = {}
}

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

function Response:new(type, id, data)
    local response = {}
    setmetatable(response, self)
    self.__index = self
    response.type = type
    response.id = id
    response.data = data
    return response
end

function CheckInventory(data) 
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

local response = CheckInventory({name = "minecraft:chest"})
local serialized = textutils.serialize(response)
print(serialized)
local response = In({count = 1, direction = "down"})
local serialized = textutils.serialize(response)
print(serialized)
local response = Out({count = 1, direction = "down"})
local serialized = textutils.serialize(response)
print(serialized)