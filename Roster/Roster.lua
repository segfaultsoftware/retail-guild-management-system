local _, RGMS = ...

-- Guild roster collection and reporting will live in this module.
RGMS.Roster = RGMS.Roster or {}

function RGMS.Roster.CanScan()
    return RGMS.Reset:canScan("the guild roster")
end

function RGMS.Roster.CanReport()
    return RGMS.Reset:canReport("the roster report")
end

function RGMS.Roster.IsScanInProgress()
    local scanner = RGMS.Roster.Scanner
    if type(scanner) ~= "table" then
        return false
    end

    if type(scanner.IsInProgress) == "function" then
        return scanner:IsInProgress()
    end

    return scanner.inProgress == true
end

function RGMS.Roster.RequestManualScan()
    if not IsInGuild() then
        RGMS.Print(
            "Cannot scan the guild roster because this character is not in a guild."
        )
        return nil, "not-in-guild"
    end

    if RGMS.Roster.IsScanInProgress() then
        RGMS.Print(
            "A guild roster scan is already in progress; no second scan was started."
        )
        return nil, "scan-in-progress"
    end

    if not RGMS.Roster.CanScan() then
        return nil, "scanning-disabled"
    end

    local scanner = RGMS.Roster.Scanner
    if type(scanner) ~= "table" or type(scanner.Request) ~= "function" then
        RGMS.Print("Could not start the guild roster scan because the scanner is unavailable.")
        return nil, "scanner-unavailable"
    end

    return scanner:Request("manual")
end
