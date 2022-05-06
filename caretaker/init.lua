-- Caretaker.lua
-- Coltrane Willsey
-- 2022-03-24 [18:22]

function getindex(x) return typeof(x) == "Instance" and x.Name or nil end
function new_guid()
    return game:GetService("HttpService"):GenerateGUID(false)
end

local Caretaker = {}
Caretaker.__index = Caretaker
Caretaker.ClassName = "Caretaker"

--[=[
    Creates a new Caretaker class

    ```lua
    local caretaker = Caretaker.new()
    ```

    @return Caretaker
--]=]
function Caretaker.new()
    local self = setmetatable({}, Caretaker)
    self._OBJECT_INDEX = {}

    return self
end

--[=[
    Extends an already existing Caretaker

    ```lua
    local ct0 = Caretaker.new()
    local ct1 = ct0:Extend()
    local ct1_0 = ct1:Extend()
    local ct2 = ct0:Extend()

    --[[
    [Constructor]
        ⮑ ct0
            ⮑ ct1
                ⮑ ct1_0
            ⮑ ct2
    --]]
    ```

    @return Caretaker
--]=]
function Caretaker:Extend()
    local _ct = Caretaker.new()
    return self:Add(_ct, "Cleanup")
end

--[=[
    Binds Caretaker:Cleanup() to Instance.Destroying

    ```lua
    local caretaker = Caretaker.new()
    caretaker:AttachToInstance(instance)

    instance:Destroy()
    -- ⮑ executes caretaker:Cleanup()
    ```
    
    @param instance Instance
--]=]
function Caretaker:AttachToInstance(instance: Instance)
    self.Instance = instance
    local _c = self.Instance.Destroying:Connect(function()
        self:Cleanup()
    end)
    self._attached_instance_connection_id = self:Add(_c)
end

--[=[
    Unassigns a Caretaker from an Instance

    ```lua
    caretaker:DetachFromInstance()

    instance:Destroy()
    -- ⮑ will not execute caretaker:Cleanup()
    ```
--]=]
function Caretaker:DetachFromInstance()
    self:Clean(self._attached_instance_connection_id)
    self._attached_instance_connection_id = nil
    self.Instance = nil
end

--[=[
    Adds an object to the Caretaker's cleanup stack

    ```lua
    local caretaker = Caretaker.new()
    caretaker:Add(instance.Changed:Connect(...))
    -- ⮑ adds a connection to the Caretaker's cleanup stack
    ```

    @param object any
    @param cleanupMethod string?

    @return any & number
--]=]
function Caretaker:Add(object: any, cleanupMethod: string?)
    local index = getindex(object) or new_guid()
    self._OBJECT_INDEX[index] = {
        Object = object;
        cleanupMethod = cleanupMethod
            or (typeof(object) == "RBXScriptConnection") and "Disconnect"
            or "Destroy"
    }

    return object, index
end

--[=[
    Removes an object from the Caretaker's cleanup stack

    ```lua
    caretaker:Remove(instance)
    caretaker:Cleanup()
    -- ⮑ instance remains
    ```

    @param object Instance | string
--]=]
function Caretaker:Remove(object: Instance | string)
    local index = getindex(object) or object
    if self._OBJECT_INDEX[index] then
        self._OBJECT_INDEX[index] = nil
    end
end

--[=[
    Cleanus up a specific object from the Caretaker's cleanup stack

    ```lua
    caretaker:Clean(instance)
    -- ⮑ cleans up this instance, but nothing else
    ```

    @param object Instance | string
--]=]
function Caretaker:Clean(object: Instance | string)
    local index = getindex(object) or object
    if self._OBJECT_INDEX[index] then
        local obj = self._OBJECT_INDEX[index]
        obj.Object[obj.cleanupMethod](obj.Object)

        self:Remove(object)
    end
end

--[=[
    Cleans up the entire cleanup stack for this Caretaker

    ```lua
    caretaker:Cleanup()
    ```
--]=]
function Caretaker:Cleanup()
    for k, _ in pairs(self._OBJECT_INDEX) do
        self:Clean(k)
    end
end

--[=[
    (alias of Caretaker:Cleanup())
    Cleans up the entire cleanup stack for this Caretaker

    ```lua
    caretaker:Destroy()
    ```
--]=]
function Caretaker:Destroy()
    self:Cleanup()
end

return Caretaker