local _, RGMS = ...

local MainsAlts = RGMS.MainsAlts or {}

local function scanInProgress()
    return type(RGMS.Roster) == "table"
        and type(RGMS.Roster.IsScanInProgress) == "function"
        and RGMS.Roster.IsScanInProgress()
end

local function characterCount(value)
    local withoutContinuationBytes = string.gsub(value, "[\128-\191]", "")
    return #withoutContinuationBytes
end

local function publishGroups(groups)
    if type(RGMS.AccountData) ~= "table"
        or type(RGMS.AccountData.replaceMainAltGroups) ~= "function"
        or type(RGMS.AccountDataState) ~= "table"
        or type(RGMS.ActiveGuildIdentity) ~= "table" then
        return nil, "Mains/Alts account storage is unavailable"
    end

    local replacement, guildOrError = RGMS.AccountData.replaceMainAltGroups(
        RGMS.AccountDataState.model,
        RGMS.ActiveGuildIdentity,
        groups
    )
    if not replacement then
        return nil, guildOrError
    end

    RGMSAccountDB = replacement
    RGMS.AccountDataState.model = replacement
    if type(RGMS.ActivateCurrentGuild) == "function" then
        RGMS.ActivateCurrentGuild()
    else
        RGMS.DB.mainAltGroups = guildOrError.mainAltGroups
    end
    return true
end

local function characterExists(identity)
    if type(identity) ~= "string" or identity == ""
        or type(RGMS.DB) ~= "table"
        or type(RGMS.DB.roster) ~= "table"
        or type(RGMS.DB.roster.members) ~= "table"
        or type(RGMS.RosterNames) ~= "table"
        or type(RGMS.RosterNames.identity) ~= "function" then
        return false
    end

    for _, member in ipairs(RGMS.DB.roster.members) do
        if RGMS.RosterNames.identity(member.name, member.realm) == identity then
            return true
        end
    end
    return false
end

local function publishNote(identity, note)
    if type(RGMS.AccountData) ~= "table"
        or type(RGMS.AccountData.replaceCharacterNote) ~= "function"
        or type(RGMS.AccountDataState) ~= "table"
        or type(RGMS.ActiveGuildIdentity) ~= "table" then
        return nil, "character note account storage is unavailable"
    end

    local replacement, guildOrError = RGMS.AccountData.replaceCharacterNote(
        RGMS.AccountDataState.model,
        RGMS.ActiveGuildIdentity,
        identity,
        note
    )
    if not replacement then
        return nil, guildOrError
    end

    RGMSAccountDB = replacement
    RGMS.AccountDataState.model = replacement
    if type(RGMS.ActivateCurrentGuild) == "function" then
        RGMS.ActivateCurrentGuild()
    else
        RGMS.DB.characterNotes = guildOrError.characterNotes
    end
    MainsAlts.RefreshStatus()
    return true
end

function MainsAlts.SaveCharacterNote(identity, value)
    if scanInProgress() then
        return nil, "character notes are disabled during a roster scan"
    end
    if not characterExists(identity) then
        return nil, "roster character is unavailable"
    end
    if type(value) ~= "string" then
        return nil, "character note must be text"
    end

    local maximum = type(RGMS.AccountData) == "table"
        and RGMS.AccountData.MAX_CHARACTER_NOTE_LENGTH
        or 5500
    if characterCount(value) > maximum then
        return nil, "character note must not exceed " .. maximum .. " characters"
    end
    local trimmed = string.match(value, "^%s*(.-)%s*$") or ""
    return publishNote(identity, trimmed ~= "" and trimmed or nil)
end

function MainsAlts.DeleteCharacterNote(identity)
    if scanInProgress() then
        return nil, "character notes are disabled during a roster scan"
    end
    if not characterExists(identity) then
        return nil, "roster character is unavailable"
    end
    return publishNote(identity, nil)
end

function MainsAlts.GroupSelected(selectedIdentities)
    if scanInProgress() then
        return nil, "grouping is disabled during a roster scan"
    end
    if type(RGMS.DB) ~= "table"
        or type(RGMS.MainsAltsGroups) ~= "table"
        or type(RGMS.MainsAltsGroups.apply) ~= "function" then
        return nil, "Mains/Alts grouping is unavailable"
    end

    local groups, mainIdentity = RGMS.MainsAltsGroups.apply(
        RGMS.DB.roster,
        RGMS.DB.mainAltGroups,
        selectedIdentities
    )
    if not groups then
        return nil, mainIdentity
    end
    local published, publishError = publishGroups(groups)
    if not published then
        return nil, publishError
    end
    if type(RGMS.UI) == "table"
        and type(RGMS.UI.CompleteMainsAltsGrouping) == "function" then
        RGMS.UI.CompleteMainsAltsGrouping(mainIdentity)
    end
    MainsAlts.RefreshStatus()
    return true, mainIdentity
end

local function changeAltGroup(methodName, altIdentity)
    if scanInProgress() then
        return nil, "group changes are disabled during a roster scan"
    end
    if type(RGMS.DB) ~= "table"
        or type(RGMS.MainsAltsGroups) ~= "table"
        or type(RGMS.MainsAltsGroups[methodName]) ~= "function" then
        return nil, "Mains/Alts group changes are unavailable"
    end

    local groups, mainIdentityOrError, groupRemains = RGMS.MainsAltsGroups[methodName](
        RGMS.DB.mainAltGroups,
        altIdentity
    )
    if not groups then
        return nil, mainIdentityOrError
    end

    local published, publishError = publishGroups(groups)
    if not published then
        return nil, publishError
    end
    if type(RGMS.UI) == "table"
        and type(RGMS.UI.CompleteMainsAltsChange) == "function" then
        RGMS.UI.CompleteMainsAltsChange(
            mainIdentityOrError,
            methodName ~= "remove" or groupRemains ~= false
        )
    end
    MainsAlts.RefreshStatus()
    return true, mainIdentityOrError
end

function MainsAlts.PromoteAlt(altIdentity)
    return changeAltGroup("promote", altIdentity)
end

function MainsAlts.RemoveAlt(altIdentity)
    return changeAltGroup("remove", altIdentity)
end

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
        if type(RGMS.UI.SetMainsAltsAvailable) == "function" then
            RGMS.UI.SetMainsAltsAvailable(false)
        end
        RGMS.UI.SetViewStatus("mainsalts", "Mains/Alts report unavailable")
        return
    end

    local report, reportError = RGMS.MainsAltsReport.build(
        RGMS.DB.roster,
        RGMS.DB.mainAltGroups,
        RGMS.DB.characterNotes
    )
    if not report then
        if type(RGMS.UI.SetMainsAltsAvailable) == "function" then
            RGMS.UI.SetMainsAltsAvailable(false)
        end
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
