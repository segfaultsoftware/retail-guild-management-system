local _, RGMS = ...

local Commands = {}

local HELP_LINES = {
    "RGMS commands:",
    "  /rgms - Toggle the main window and select Roster when opening.",
    "  /rgms help - Show this command list.",
    "  /rgms debug - Toggle verbose diagnostic logging.",
    "  /rgms scanroster - Scan the guild roster.",
    "  /rgms reset - Open the reset confirmation.",
}

local function showHelp(api)
    for _, line in ipairs(HELP_LINES) do
        api.Print(line)
    end
end

local function normalize(input)
    return tostring(input or ""):match("^%s*(.-)%s*$"):lower()
end

function Commands.handle(input, api)
    local command = normalize(input)

    if command == "" then
        api.UI.Toggle("roster")
        return
    end

    if command == "help" then
        showHelp(api)
        return
    end

    if command == "scanroster" then
        api.Roster.RequestManualScan()
        return
    end

    if command == "debug" then
        local enabled = api.ToggleDebug()
        api.Print("Debug logging " .. (enabled and "enabled." or "disabled."))
        return
    end

    if command == "reset" then
        api.Reset:requestManual()
        return
    end

    showHelp(api)
end

Commands.HELP_LINES = HELP_LINES
Commands.normalize = normalize

if type(RGMS) == "table" then
    RGMS.Commands = Commands
    SLASH_RGMS1 = "/rgms"
    SlashCmdList.RGMS = function(input)
        Commands.handle(input, RGMS)
    end
end

return Commands
