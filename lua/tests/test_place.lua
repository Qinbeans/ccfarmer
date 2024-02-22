Response = {
    ["type"] = "",
    ["id"] = "",
    ["data"] = {}
}

local MAX_INDEX = 16

function Response:new(type, id, data)
    local response = {}
    setmetatable(response, self)
    self.__index = self
    response.type = type
    response.id = id
    response.data = data
    return response
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

local response = Place({["steps"] = 1, ["index"] = 1})
local serialized = textutils.serialize(response)
print(serialized)

local response = Place({["steps"] = 2, ["index"] = 5})
local serialized = textutils.serialize(response)

print(serialized)