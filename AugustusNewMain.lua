local Base = loadstring(game:HttpGet("https://raw.githubusercontent.com/schweyuanzig/Scarfaze/refs/heads/main/AugustusMain.lua"))()

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
