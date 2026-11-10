-- WoW adapter and slash-command surface for the standalone runtime probe.

local addonName, addon = ...
addon = type(addon) == "table" and addon or {}

local Core = addon.Core
if type(Core) ~= "table" and type(require) == "function" then
    Core = require("Diagnostics.RGMSRuntimeProbe.Core")
end

local Runtime = {}
addon.Runtime = Runtime

local REGION_NAMES = {
    [1] = "US",
    [2] = "KR",
    [3] = "EU",
    [4] = "TW",
    [5] = "CN",
}

Runtime.HELP_LINES = {
    "RGMS runtime probe commands:",
    "  /rgmsprobe start - Start or resume bounded capture.",
    "  /rgmsprobe status - Show capture state and bounded counts.",
    "  /rgmsprobe snapshot - Request and capture the current roster surfaces.",
    "  /rgmsprobe mark reload - Mark the next session as a UI reload.",
    "  /rgmsprobe mark logout-login - Mark the next session as logout/login.",
    "  /rgmsprobe mark cold-restart - Mark the next session as a cold client restart.",
    "  /rgmsprobe stop - Capture once more, stop, and finalize the export.",
    "  /rgmsprobe export - Refresh the sanitized export without printing its contents.",
    "  /rgmsprobe reset confirm - Erase all local probe data.",
}

local state
local registrationErrors = {}

local function addError(target, code)
    target.errors = target.errors or {}
    for _, existing in ipairs(target.errors) do
        if existing == code then
            return
        end
    end
    target.errors[#target.errors + 1] = code
end

local function printMessage(message)
    local frame = _G.DEFAULT_CHAT_FRAME
    if type(frame) == "table" and type(frame.AddMessage) == "function" then
        frame:AddMessage("|cff33ff99RGMS Probe|r: " .. tostring(message))
    end
end

local function showHelp()
    for _, line in ipairs(Runtime.HELP_LINES) do
        printMessage(line)
    end
end

local function determineNameStyle(interface, productId)
    if productId == 18 then
        return "forever"
    end
    local number = tonumber(interface)
    if number and number >= 16000 and number < 17000 then
        return "forever"
    end
    return "retail"
end

local function collectRuntime()
    local result = { errors = {} }
    for _, code in ipairs(registrationErrors) do
        addError(result, code)
    end
    result.productId = _G.WOW_PROJECT_ID

    if type(_G.GetBuildInfo) == "function" then
        local ok, version, build, _, interface = pcall(_G.GetBuildInfo)
        if ok then
            result.version = version
            result.build = build
            result.interface = interface
            if version == nil or build == nil or interface == nil then
                addError(result, "GET_BUILD_INFO_INCOMPLETE")
            end
        else
            addError(result, "GET_BUILD_INFO_FAILED")
        end
    else
        addError(result, "GET_BUILD_INFO_MISSING")
    end

    if type(_G.GetCurrentRegion) == "function" then
        local ok, regionId = pcall(_G.GetCurrentRegion)
        if ok and regionId ~= nil then
            result.region = REGION_NAMES[regionId] or tostring(regionId)
        elseif ok then
            addError(result, "GET_CURRENT_REGION_UNAVAILABLE")
        else
            addError(result, "GET_CURRENT_REGION_FAILED")
        end
    else
        addError(result, "GET_CURRENT_REGION_MISSING")
    end

    if type(_G.GetRealmName) == "function" then
        local ok, realmName = pcall(_G.GetRealmName)
        if ok and realmName ~= nil then
            result.realmName = realmName
        elseif ok then
            addError(result, "GET_REALM_NAME_UNAVAILABLE")
        else
            addError(result, "GET_REALM_NAME_FAILED")
        end
    else
        addError(result, "GET_REALM_NAME_MISSING")
    end

    if type(_G.GetNormalizedRealmName) == "function" then
        local ok, realmName = pcall(_G.GetNormalizedRealmName)
        if ok and realmName ~= nil then
            result.normalizedRealmName = realmName
        elseif ok then
            addError(result, "GET_NORMALIZED_REALM_NAME_UNAVAILABLE")
        else
            addError(result, "GET_NORMALIZED_REALM_NAME_FAILED")
        end
    else
        addError(result, "GET_NORMALIZED_REALM_NAME_MISSING")
    end

    if result.productId == 18 then
        if type(_G.UnitName) == "function" then
            local ok, firstName, surname = pcall(_G.UnitName, "player")
            if ok and type(firstName) == "string" and firstName ~= ""
                and type(surname) == "string" and surname ~= "" then
                result.playerName = firstName .. " " .. surname
            elseif ok then
                addError(result, "UNIT_NAME_INCOMPLETE")
            else
                addError(result, "UNIT_NAME_FAILED")
            end
        else
            addError(result, "UNIT_NAME_MISSING")
        end
        -- Record UnitFullName's realm result independently. Do not substitute
        -- GetRealmName or reinterpret UnitName's Forever surname as a realm.
        if type(_G.UnitFullName) == "function" then
            local ok, _, playerRealm = pcall(_G.UnitFullName, "player")
            if ok then
                result.playerRealm = playerRealm
            else
                addError(result, "UNIT_FULL_NAME_FAILED")
            end
        else
            addError(result, "UNIT_FULL_NAME_MISSING")
        end
    elseif type(_G.UnitFullName) == "function" then
        local ok, playerName, playerRealm = pcall(_G.UnitFullName, "player")
        if ok then
            result.playerName = playerName
            result.playerRealm = playerRealm
        else
            addError(result, "UNIT_FULL_NAME_FAILED")
        end
    elseif type(_G.UnitName) == "function" then
        addError(result, "UNIT_FULL_NAME_MISSING")
        local ok, playerName, playerRealm = pcall(_G.UnitName, "player")
        if ok then
            result.playerName = playerName
            result.playerRealm = playerRealm
        else
            addError(result, "UNIT_NAME_FAILED")
        end
    else
        addError(result, "UNIT_FULL_NAME_MISSING")
        addError(result, "UNIT_NAME_MISSING")
    end

    result.nameStyle = determineNameStyle(result.interface, result.productId)
    return result
end

local function collectGuildInfo(raw)
    if type(_G.GetGuildInfo) ~= "function" then
        addError(raw, "GET_GUILD_INFO_MISSING")
        return
    end
    local ok, guildName, _, _, guildRealm = pcall(_G.GetGuildInfo, "player")
    if ok then
        raw.guild.name = guildName
        raw.guild.realm = guildRealm
    else
        addError(raw, "GET_GUILD_INFO_FAILED")
    end
end

local function collectClubMembers(raw)
    local clubApi = _G.C_Club
    if type(clubApi) ~= "table"
        or type(clubApi.GetGuildClubId) ~= "function" then
        addError(raw, "GET_GUILD_CLUB_ID_MISSING")
        return nil
    end

    local idOk, clubId = pcall(clubApi.GetGuildClubId)
    if not idOk then
        addError(raw, "GET_GUILD_CLUB_ID_FAILED")
        return nil
    end
    if clubId == nil then
        addError(raw, "GET_GUILD_CLUB_ID_UNAVAILABLE")
        return nil
    end
    raw.guild.clubId = clubId

    if type(clubApi.GetClubInfo) == "function" then
        local infoOk, clubInfo = pcall(clubApi.GetClubInfo, clubId)
        if infoOk and type(clubInfo) == "table" then
            if raw.guild.name == nil then
                raw.guild.name = clubInfo.name
            end
            if type(clubInfo.memberCount) == "number" then
                raw.guild.memberCount = clubInfo.memberCount
            end
        elseif infoOk then
            addError(raw, "GET_CLUB_INFO_UNAVAILABLE")
        else
            addError(raw, "GET_CLUB_INFO_FAILED")
        end
    else
        addError(raw, "GET_CLUB_INFO_MISSING")
    end

    if type(clubApi.GetClubMembers) ~= "function" then
        addError(raw, "GET_CLUB_MEMBERS_MISSING")
        return nil
    end
    local listOk, memberIds = pcall(clubApi.GetClubMembers, clubId)
    if not listOk then
        addError(raw, "GET_CLUB_MEMBERS_FAILED")
        return nil
    end
    if type(memberIds) ~= "table" then
        addError(raw, "GET_CLUB_MEMBERS_UNAVAILABLE")
        return nil
    end

    raw.memberListCount = #memberIds
    raw.membersTruncated = #memberIds > Core.LIMITS.membersPerObservation
    local members = {}
    local count = math.min(#memberIds, Core.LIMITS.membersPerObservation)
    if type(clubApi.GetMemberInfo) ~= "function" then
        addError(raw, "GET_MEMBER_INFO_MISSING")
    end
    for index = 1, count do
        local member = {}
        if type(clubApi.GetMemberInfo) == "function" then
            local infoOk, info = pcall(
                clubApi.GetMemberInfo,
                clubId,
                memberIds[index]
            )
            if infoOk and type(info) == "table" then
                member.name = info.name
                member.guid = info.guid
                if type(info.name) ~= "string" or info.name == ""
                    or type(info.guid) ~= "string" or info.guid == "" then
                    addError(raw, "GET_MEMBER_INFO_INCOMPLETE")
                end
            elseif infoOk then
                addError(raw, "GET_MEMBER_INFO_INCOMPLETE")
            else
                addError(raw, "GET_MEMBER_INFO_FAILED")
            end
        end
        members[#members + 1] = member
    end
    return members
end

local function guildRosterInfo(raw, index)
    if type(_G.GetGuildRosterInfo) ~= "function" then
        addError(raw, "GET_GUILD_ROSTER_INFO_MISSING")
        return nil
    end
    local values = { pcall(_G.GetGuildRosterInfo, index) }
    if values[1] ~= true then
        addError(raw, "GET_GUILD_ROSTER_INFO_FAILED")
        return nil
    end
    local member = {
        name = values[2],
        guid = values[18],
    }
    if type(member.name) ~= "string" or member.name == ""
        or type(member.guid) ~= "string" or member.guid == "" then
        addError(raw, "GET_GUILD_ROSTER_INFO_INCOMPLETE")
    end
    return member
end

local function collectGuildRoster(raw)
    if type(_G.GetNumGuildMembers) ~= "function" then
        addError(raw, "GET_NUM_GUILD_MEMBERS_MISSING")
        return nil
    end
    local ok, total, online = pcall(_G.GetNumGuildMembers)
    if not ok then
        addError(raw, "GET_NUM_GUILD_MEMBERS_FAILED")
        return nil
    end
    if type(total) ~= "number" then
        addError(raw, "GET_NUM_GUILD_MEMBERS_UNAVAILABLE")
        return nil
    end

    raw.guildRosterMemberCount = total
    if type(online) == "number" then
        raw.guildRosterOnlineCount = online
    end

    if type(_G.GetGuildRosterInfo) ~= "function" then
        addError(raw, "GET_GUILD_ROSTER_INFO_MISSING")
        return nil
    end
    local members = {}
    raw.membersTruncated = raw.membersTruncated
        or total > Core.LIMITS.membersPerObservation
    local count = math.min(total, Core.LIMITS.membersPerObservation)
    for index = 1, count do
        members[#members + 1] = guildRosterInfo(raw, index) or {}
    end
    return members
end

local function membersAreComplete(members, expectedCount)
    if type(members) ~= "table" or type(expectedCount) ~= "number"
        or #members ~= math.min(expectedCount, Core.LIMITS.membersPerObservation) then
        return false
    end
    for _, member in ipairs(members) do
        if type(member.name) ~= "string" or member.name == ""
            or type(member.guid) ~= "string" or member.guid == "" then
            return false
        end
    end
    return true
end

local function collectObservation(trigger)
    local runtime = collectRuntime()
    local raw = {
        trigger = trigger,
        nameStyle = runtime.nameStyle,
        errors = {},
        guild = {},
        members = {},
        memberSource = "none",
    }

    collectGuildInfo(raw)
    local clubMembers = collectClubMembers(raw)
    local rosterMembers = collectGuildRoster(raw)

    local clubComplete = membersAreComplete(clubMembers, raw.memberListCount)
    local rosterComplete = membersAreComplete(
        rosterMembers,
        raw.guildRosterMemberCount
    )
    if clubComplete or (clubMembers ~= nil and not rosterComplete) then
        raw.members = clubMembers
        raw.memberSource = "club"
    elseif rosterComplete or rosterMembers ~= nil then
        raw.members = rosterMembers
        raw.memberSource = "guild-roster"
    end

    return raw
end

local function requestRoster()
    if type(_G.C_GuildInfo) == "table"
        and type(_G.C_GuildInfo.GuildRoster) == "function" then
        local requested = pcall(_G.C_GuildInfo.GuildRoster)
        if requested then
            return true
        end
    end
    if type(_G.GuildRoster) == "function" then
        local requested = pcall(_G.GuildRoster)
        if requested then
            return true
        end
        return nil, "ROSTER_REQUEST_FAILED"
    end
    if type(_G.C_GuildInfo) == "table"
        and type(_G.C_GuildInfo.GuildRoster) == "function" then
        return nil, "ROSTER_REQUEST_FAILED"
    end
    return nil, "ROSTER_REQUEST_UNAVAILABLE"
end

local function setState(value)
    state = Core.loadState(value)
    _G.RGMSRuntimeProbeDB = state
    return state
end

local function refreshExport()
    local export = Core.createExport(state or Core.newState())
    _G.RGMSRuntimeProbeExport = export
    return export
end

local function capture(trigger)
    if not state or not state.enabled then
        return nil, "capture is not enabled"
    end
    return Core.recordObservation(state, collectObservation(trigger))
end

local function recordEvent(name, values)
    values = type(values) == "table" and values or {}
    values.name = name
    return Core.recordEvent(state, values)
end

local function activeSession()
    if not state or type(state.currentSessionIndex) ~= "number" then
        return nil
    end
    for _, session in ipairs(state.sessions) do
        if session.index == state.currentSessionIndex then
            return session
        end
    end
    return nil
end

local function requestRosterAndRecordFailure()
    local requested, failureEvent = requestRoster()
    if not requested then
        recordEvent(failureEvent or "ROSTER_REQUEST_FAILED")
    end
    return requested
end

local function startCapture()
    if not state then
        setState(_G.RGMSRuntimeProbeDB)
    end
    if state.enabled and activeSession() then
        printMessage("Capture is already active.")
        return true
    end

    Core.startSession(state, collectRuntime(), "initial")
    _G.RGMSRuntimeProbeDB = state
    _G.RGMSRuntimeProbeExport = nil
    recordEvent("PROBE_START")
    capture("PROBE_START")
    requestRosterAndRecordFailure()
    printMessage("Bounded runtime capture started.")
    return true
end

local function stopCapture()
    if not state.enabled then
        printMessage("Capture is not active; the existing sanitized export was preserved.")
        return nil
    end

    capture("PROBE_STOP")
    recordEvent("PROBE_STOP")
    Core.stopSession(state, true, "manual-stop")
    local export = refreshExport()
    if export.complete then
        -- A usable export contains only aliases. Drop the working database so
        -- raw alias-map keys are not written during the final flush.
        _G.RGMSRuntimeProbeDB = nil
        printMessage("Capture stopped. Sanitized RGMSRuntimeProbeExport is ready.")
    else
        -- Preserve the local working record for diagnosis. The extractor will
        -- reject this incomplete export and the raw database must not be shared.
        _G.RGMSRuntimeProbeDB = state
        printMessage(
            "Capture stopped after a probe limit was exceeded; reset and rerun before exporting evidence."
        )
    end
    return true
end

local function status()
    local session = activeSession()
    local eventCount = session and #session.events or 0
    local observationCount = session and #session.observations or 0
    printMessage(string.format(
        "Capture %s; %d/%d sessions retained; current session has %d/%d events and %d/%d observations.",
        state.enabled and "active" or "stopped",
        #state.sessions,
        Core.LIMITS.sessions,
        eventCount,
        Core.LIMITS.events,
        observationCount,
        Core.LIMITS.observations
    ))
end

local function snapshot()
    if not state.enabled then
        printMessage("Capture is not active. Run /rgmsprobe start first.")
        return nil
    end
    recordEvent("MANUAL_SNAPSHOT")
    local observation = capture("MANUAL_SNAPSHOT")
    requestRosterAndRecordFailure()
    if observation then
        printMessage("Captured a bounded roster observation and requested a refresh.")
    end
    return observation
end

local function mark(boundary)
    if not state.enabled then
        printMessage("Capture is not active. Run /rgmsprobe start first.")
        return nil
    end
    local marked = Core.markBoundary(state, boundary)
    if not marked then
        printMessage("Boundary must be reload, logout-login, or cold-restart.")
        return nil
    end
    recordEvent("MARK_" .. string.upper(boundary):gsub("%-", "_"))
    printMessage("Next session boundary marked as " .. boundary .. ".")
    return true
end

local function reset(input)
    if input ~= "confirm" then
        printMessage("Reset was not run. Use /rgmsprobe reset confirm to erase local probe data.")
        return nil
    end
    setState(Core.newState())
    _G.RGMSRuntimeProbeExport = nil
    printMessage("All local runtime probe data was erased.")
    return true
end

local function normalize(input)
    return tostring(input or ""):match("^%s*(.-)%s*$"):lower()
end

function Runtime.handle(input)
    local command = normalize(input)
    if command == "start" then
        return startCapture()
    elseif command == "status" then
        return status()
    elseif command == "snapshot" then
        return snapshot()
    elseif command == "stop" then
        return stopCapture()
    elseif command == "export" then
        if not state or state.captureStopped ~= true or state.enabled then
            printMessage("No finalized capture is available. Run /rgmsprobe stop first.")
            return nil
        end
        local export = refreshExport()
        if export.complete then
            printMessage("Sanitized RGMSRuntimeProbeExport was refreshed.")
        else
            printMessage("The capture is truncated and cannot be exported as evidence.")
        end
        return true
    elseif command == "reset" then
        return reset("")
    elseif command == "reset confirm" then
        return reset("confirm")
    end

    local boundary = command:match("^mark%s+([%a%-]+)$")
    if boundary then
        return mark(boundary)
    end

    showHelp()
    return nil
end

local function eventValues(event, ...)
    local first, second = ...
    if event == "GUILD_ROSTER_UPDATE" then
        return { canRequestRosterUpdate = first }
    end
    if event == "CLUB_MEMBERS_UPDATED" then
        return { clubId = first }
    end
    if event == "CLUB_MEMBER_UPDATED"
        or event == "CLUB_MEMBER_PRESENCE_UPDATED" then
        return { clubId = first, memberId = second }
    end
    return {}
end

local function onEvent(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= addonName then
            return
        end
        setState(_G.RGMSRuntimeProbeDB)
        if state.enabled then
            _G.RGMSRuntimeProbeExport = nil
            Core.startSession(state, collectRuntime(), "initial")
            recordEvent("ADDON_LOADED")
            capture("ADDON_LOADED")
            requestRosterAndRecordFailure()
        end
        return
    end

    if not state or not state.enabled then
        return
    end

    recordEvent(event, eventValues(event, ...))
    capture(event)

    if event == "PLAYER_LOGOUT" then
        Core.stopSession(state, false, "player-logout")
    end
end

Runtime.collectRuntime = collectRuntime
Runtime.collectObservation = collectObservation
Runtime.refreshExport = refreshExport

if type(_G.CreateFrame) == "function" then
    local frame = _G.CreateFrame("Frame")
    local events = {
        "ADDON_LOADED",
        "PLAYER_LOGIN",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVING_WORLD",
        "PLAYER_LOGOUT",
        "PLAYER_GUILD_UPDATE",
        "GUILD_ROSTER_UPDATE",
        "INITIAL_CLUBS_LOADED",
        "CLUB_MEMBERS_UPDATED",
        "CLUB_MEMBER_UPDATED",
        "CLUB_MEMBER_PRESENCE_UPDATED",
    }
    for _, event in ipairs(events) do
        local registered = pcall(frame.RegisterEvent, frame, event)
        if not registered then
            addError({ errors = registrationErrors }, "EVENT_REGISTRATION_FAILED")
        end
    end
    frame:SetScript("OnEvent", onEvent)
    Runtime.EventFrame = frame
end

_G.SLASH_RGMSRUNTIMEPROBE1 = "/rgmsprobe"
_G.SlashCmdList = _G.SlashCmdList or {}
_G.SlashCmdList.RGMSRUNTIMEPROBE = Runtime.handle

return Runtime
