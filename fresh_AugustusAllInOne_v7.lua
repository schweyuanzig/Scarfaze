-- fresh_AugustusAllInOne_v7.lua
-- v7 wrapper based on AugustusAllInOne_v6.lua

local Base = loadstring(readfile("AugustusAllInOne_v6.lua"))()

local RawCreateWindow = Base.CreateWindow

function Base:CreateWindow(options)
    local Window = RawCreateWindow(self, options or {})

    if Window.AddBindList == nil then
        function Window:AddBindList()
            self.Options.ShowBindList = true
            if self._refreshBindList then
                self:_refreshBindList()
            end
            return self.BindList
        end
    end

    return Window
end

return Base
