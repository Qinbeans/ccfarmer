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

-- move forward 1 step, look down, report
local canMove, err = turtle.forward()
if not canMove then
    print(err)
    return
end
local response = LookDown()
local serialized = textutils.serialize(response)

print(serialized)