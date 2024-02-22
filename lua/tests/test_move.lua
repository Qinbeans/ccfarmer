Response = {
    ["type"] = "",
    ["id"] = "",
    ["data"] = {}
}

Direction = {
    right = turtle.turnRight,
    left = turtle.turnLeft,
    forward = turtle.forward,
    back = turtle.back,
    up = turtle.up,
    down = turtle.down
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

function Move(data)
    local steps = data["steps"]
    local direction = data["direction"]
    local func = Direction[direction]
    for i = 1, steps do
        local canMove, err = func()
        if not canMove then
            return Response:new("report", "", {["error"] = err})
        end
    end
    return Response:new("report", "", {["status"] = "moved", ["steps"] = steps}) 
end

local response = Move({["steps"] = 1, ["direction"] = "forward"})
local serialized = textutils.serialize(response)
print(serialized)

local response = Move({["steps"] = 2, ["direction"] = "up"})
local serialized = textutils.serialize(response)
print(serialized)