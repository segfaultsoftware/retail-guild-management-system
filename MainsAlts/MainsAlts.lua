local _, RGMS = ...

local MainsAlts = RGMS.MainsAlts or {}

function MainsAlts.RefreshStatus()
    if type(RGMS.UI) ~= "table"
        or type(RGMS.UI.SetViewStatus) ~= "function" then
        return
    end

    local available = type(RGMS.Roster) ~= "table"
        or type(RGMS.Roster.IsAvailable) ~= "function"
        or RGMS.Roster.IsAvailable()
    if type(RGMS.UI.SetMainsAltsAvailable) == "function" then
        RGMS.UI.SetMainsAltsAvailable(available)
    end

    if not available then
        RGMS.UI.SetViewContent("mainsalts", "Not in a guild")
        RGMS.UI.SetViewStatus("mainsalts", "Not in a guild")
        return
    end

    if type(RGMS.MainsAltsReport) ~= "table"
        or type(RGMS.MainsAltsReport.build) ~= "function"
        or type(RGMS.DB) ~= "table" then
        RGMS.UI.SetViewStatus("mainsalts", "Mains/Alts report unavailable")
        return
    end

    local report, reportError = RGMS.MainsAltsReport.build(
        RGMS.DB.roster,
        RGMS.DB.mainAltGroups
    )
    if not report then
        RGMS.UI.SetViewStatus(
            "mainsalts",
            "Mains/Alts report unavailable: " .. tostring(reportError)
        )
        return
    end
    RGMS.UI.SetMainsAltsReport(report)

    local scanning = type(RGMS.Roster) == "table"
        and type(RGMS.Roster.IsScanInProgress) == "function"
        and RGMS.Roster.IsScanInProgress()
    if scanning then
        RGMS.UI.SetViewStatus("mainsalts", "Roster scan in progress")
    elseif #report.rows == 0 then
        RGMS.UI.SetViewStatus("mainsalts", "No roster data yet")
    else
        RGMS.UI.SetViewStatus(
            "mainsalts",
            string.format("%d roster character%s", #RGMS.DB.roster.members,
                #RGMS.DB.roster.members == 1 and "" or "s")
        )
    end
end

RGMS.MainsAlts = MainsAlts

return MainsAlts
