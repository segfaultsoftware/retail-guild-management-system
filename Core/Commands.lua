local _, RGMS = ...

local Commands = {}

local function showHelp(api)
    api.Print("Available commands: /rgms help, /rgms reset")
end

function Commands.handle(input, api)
    local command = tostring(input or ""):match("^%s*(%S*)"):lower()

    if command == "" or command == "help" then
        showHelp(api)
        return
    end

    if command == "reset" then
        api.Reset:requestManual()
        return
    end

    api.Print(("Unknown command %q. Type /rgms help."):format(command))
end

if type(RGMS) == "table" then
    RGMS.Commands = Commands
    SLASH_RGMS1 = "/rgms"
    SlashCmdList.RGMS = function(input)
        Commands.handle(input, RGMS)
    end
end

return Commands
