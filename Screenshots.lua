-- Screenshots: when and where each screenshot was taken
local _, ns = ...

ns.On("SCREENSHOT_SUCCEEDED", function()
    ns.Store.Event("screenshot")
end)
