local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

    Window:Dialog({
        Title = "Notice ⚠️",
        Content = "The script is not 100% anti-ban on some maps the anti-cheat ends up noticing the modifications and ends up banning the user.\n Use it at your own risk and responsibility.",
        Buttons = {
            {
            Title = "Confirm",
            Callback = function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/AKAiDOHub/AKAIDOSCRIPTS/main/AIMBOTINGLES.lua"))()
            end
            },
            {
                Title = "Cancel",
                Callback = function()
                            
                end
            }
        }
    })
