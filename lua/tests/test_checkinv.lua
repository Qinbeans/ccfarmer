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

local response = CheckInventory()
local serialized = textutils.serialize(response)
print(serialized)