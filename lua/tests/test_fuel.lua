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