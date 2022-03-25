-- Caretaker.lua
-- Coltrane Willsey
-- 2022-03-24 [18:22]

--[[

    Caretaker.new(): Caretaker

    class Caretaker:
        Caretaker:Extend(): Caretaker

        Caretaker:AttachToInstance(instance: Instance)
        Caretaker:DetachFromInstance()

        Caretaker:Add(thing: any): any, string
        Caretaker:Remove(thing: any)
        Caretaker:Clean(thing: any)

        Caretaker:Cleanup()
        Caretaker:Destroy()

--]]

function getindex(x) return typeof(x) == "Instance" and x.Name or nil end
function new_guid()
    return game:GetService("HttpService"):GenerateGUID(false)
end

local Caretaker = {}
Caretaker.__index = Caretaker
Caretaker.ClassName = "Caretaker"

function Caretaker.new()
    local self = setmetatable({}, Caretaker)
    self._OBJECT_INDEX = {}

    return self
end

function Caretaker:Extend()
    local _ct = Caretaker.new()
    return self:Add(_ct, "Cleanup")
end

function Caretaker:AttachToInstance(instance: Instance)
    self.Instance = instance
    local _c = self.Instance.Destroying:Connect(function()
        self:Cleanup()
    end)
    self._attached_instance_connection_id = self:Add(_c)
end

function Caretaker:DetachFromInstance(instance: Instance)
    self:Clean(self._attached_instance_connection_id)
    self._attached_instance_connection_id = nil
    self.Instance = nil
end

function Caretaker:Add(thing: any, cleanupMethod: string?)
    local index = getindex(thing) or new_guid()
    self._OBJECT_INDEX[index] = {
        Object = thing;
        cleanupMethod = cleanupMethod
            or (typeof(thing) == "RBXScriptConnection") and "Disconnect"
            or "Destroy"
    }

    return thing, index
end

function Caretaker:Remove(thing: Instance | string)
    local index = getindex(thing) or thing
    if self._OBJECT_INDEX[index] then
        self._OBJECT_INDEX[index] = nil
    end
end

function Caretaker:Clean(thing: Instance | string)
    local index = getindex(thing) or thing
    if self._OBJECT_INDEX[index] then
        local obj = self._OBJECT_INDEX[index]
        obj.Object[obj.cleanupMethod](obj.Object)

        self:Remove(thing)
    end
end

function Caretaker:Cleanup()
    for k, _ in pairs(self._OBJECT_INDEX) do
        self:Clean(k)
    end
end

function Caretaker:Destroy()
    self:Cleanup()
    self = nil
end

return Caretaker