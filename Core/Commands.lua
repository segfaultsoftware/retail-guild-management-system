local _, RGMS = ...

local function ShowHelp()
    RGMS.Print("Help is under construction. Available command: /rgms help")
end

SLASH_RGMS1 = "/rgms"
SlashCmdList.RGMS = function(input)
    local command = input:match("^%s*(%S*)"):lower()

    if command == "" or command == "help" then
        ShowHelp()
        return
    end

    RGMS.Print(("Unknown command %q. Type /rgms help."):format(command))
end
