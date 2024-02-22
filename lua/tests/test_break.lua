Response = {
    ["type"] = "",
    ["id"] = "",
    ["data"] = {}
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

local response = BreakOrTil({["steps"] = 1})
local serialized = textutils.serialize(response)
print(serialized)

local response = BreakOrTil({["steps"] = 2})
local serialized = textutils.serialize(response)

print(serialized)