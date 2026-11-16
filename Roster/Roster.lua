local _, RGMS = ...

local Roster = RGMS.Roster or {}
local Names = type(RGMS.RosterNames) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")
local ClientFlavor = type(RGMS.ClientFlavor) == "table"
    and RGMS.ClientFlavor
    or require("Core.ClientFlavor")
local CharacterIdentity = type(RGMS.CharacterIdentity) == "table"
    and RGMS.CharacterIdentity
    or require("Core.CharacterIdentity")
local GuildIdentity = type(RGMS.GuildIdentity) == "table"
    and RGMS.GuildIdentity
    or require("Core.GuildIdentity")

local REGION_NAMES = {
    [1] = "US",
    [2] = "KR",
    [3] = "EU",
    [4] = "TW",
    [5] = "CN",
}

local GUILD_IDENTITY_PENDING = "guild-identity-pending"
local WAITING_FOR_GUILD_DATA = "Waiting for guild data…"
local GUILD_DATA_ACTIONABLE =
    "Guild data is still unavailable. Click Refresh to retry."
local IDENTITY_RETRY_DELAYS = { 0.5, 1, 2, 4, 8 }

-- Guild readiness is deliberately session-only. Saved guild ownership remains
-- keyed exclusively by the canonical identity returned from Bootstrap.
local guildReadiness = {
    waiting = false,
    exhausted = false,
    startupRefreshPending = false,
    manualRefreshPending = false,
    retryIndex = 1,
    retryTimer = nil,
    generation = 0,
    releasingRosterScan = false,
    scanLockRetryDeferred = false,
}

local function identityKey(identity)
    return type(identity) == "table" and identity.key or nil
end

local function cancelIdentityRetry(invalidate)
    local timer = guildReadiness.retryTimer
    guildReadiness.retryTimer = nil
    if timer ~= nil and type(timer.Cancel) == "function" then
        pcall(timer.Cancel, timer)
    end
    if invalidate then
        guildReadiness.generation = guildReadiness.generation + 1
    end
end

local function restartIdentityRetry()
    cancelIdentityRetry(true)
    guildReadiness.retryIndex = 1
    guildReadiness.exhausted = false
end

local function clearGuildReadiness()
    cancelIdentityRetry(true)
    guildReadiness.waiting = false
    guildReadiness.exhausted = false
    guildReadiness.startupRefreshPending = false
    guildReadiness.manualRefreshPending = false
    guildReadiness.retryIndex = 1
    guildReadiness.scanLockRetryDeferred = false
end

local function savedDataIsDisabled()
    return (type(RGMS.SavedDataState) == "table"
            and RGMS.SavedDataState.enabled == false)
        or (type(RGMS.AccountDataState) == "table"
            and RGMS.AccountDataState.enabled == false)
end

local function createIdentityRetryTimer(delay, callback)
    if type(RGMS.NewTimer) == "function" then
        return RGMS.NewTimer(delay, callback)
    end
    if type(C_Timer) == "table" and type(C_Timer.NewTimer) == "function" then
        return C_Timer.NewTimer(delay, callback)
    end
    return nil
end

local function scheduleIdentityRetry()
    if guildReadiness.retryTimer ~= nil
        or not guildReadiness.waiting
        or guildReadiness.exhausted then
        return false
    end

    local delay = IDENTITY_RETRY_DELAYS[guildReadiness.retryIndex]
    if delay == nil then
        guildReadiness.exhausted = true
        if type(Roster.RefreshStatus) == "function" then
            Roster.RefreshStatus()
        end
        return false
    end

    guildReadiness.retryIndex = guildReadiness.retryIndex + 1
    local generation = guildReadiness.generation
    local timer
    timer = createIdentityRetryTimer(delay, function()
        if generation ~= guildReadiness.generation
            or guildReadiness.retryTimer ~= timer then
            return
        end
        guildReadiness.retryTimer = nil
        Roster.ActivateAndRefresh("automatic")
    end)
    guildReadiness.retryTimer = timer
    if timer == nil then
        guildReadiness.exhausted = true
        if type(Roster.RefreshStatus) == "function" then
            Roster.RefreshStatus()
        end
        return false
    end
    return true
end

local function incomplete(message)
    return nil, "incomplete", message
end

local function copyTimestamp(timestamp)
    return {
        unixSeconds = timestamp.unixSeconds,
        iso8601 = timestamp.iso8601,
    }
end

local function captureGuildIdentity(flavor, region, clubId, clubInfo)
    if type(RGMS.ResolveCurrentGuildIdentity) ~= "function" then
        return incomplete("the guild identity service is unavailable")
    end

    local identity, identityError = RGMS.ResolveCurrentGuildIdentity()
    if identity == nil then
        return incomplete(identityError or "the guild identity is unavailable")
    end

    local valid, validationError = GuildIdentity.validate(identity)
    if not valid then
        return incomplete(validationError)
    end
    if identity.flavor ~= flavor
        or identity.region ~= region
        or identity.name ~= clubInfo.name then
        return incomplete("the guild identity changed during roster capture")
    end
    if flavor == ClientFlavor.FOREVER
        and tostring(identity.clubId) ~= tostring(clubId) then
        return incomplete("the guild club changed during roster capture")
    end
    return identity
end

-- Keep this adapter project-owned: available roster libraries use legacy
-- product-specific APIs or publish partial results, while RGMS already owns
-- the shared C_Club identity and transactional-completion contracts.
local function createModernApi()
    local api = {}

    function api:isInGuild()
        return IsInGuild() == true
    end

    function api:requestRoster()
        C_GuildInfo.GuildRoster()
    end

    function api:captureSnapshot()
        local flavor = type(ClientFlavor.getFlavor) == "function"
            and ClientFlavor.getFlavor()
            or nil
        if flavor ~= ClientFlavor.RETAIL and flavor ~= ClientFlavor.FOREVER then
            return incomplete("the client flavor is unavailable")
        end

        local regionId = type(GetCurrentRegion) == "function"
            and GetCurrentRegion()
            or nil
        local region = REGION_NAMES[regionId]
        if region == nil then
            return incomplete("the client region is unavailable")
        end

        local clubId = C_Club.GetGuildClubId()
        if clubId == nil then
            return incomplete("the guild club is not initialized")
        end

        local clubInfo = C_Club.GetClubInfo(clubId)
        if type(clubInfo) ~= "table"
            or type(clubInfo.name) ~= "string"
            or clubInfo.name == ""
            or type(clubInfo.memberCount) ~= "number" then
            return incomplete("guild identity or member count is unavailable")
        end

        local guildIdentity, guildState, guildError = captureGuildIdentity(
            flavor,
            region,
            clubId,
            clubInfo
        )
        if guildIdentity == nil then
            return nil, guildState, guildError
        end

        local numberOfRanks = GuildControlGetNumRanks()
        if type(numberOfRanks) ~= "number" or numberOfRanks < 1 then
            return incomplete("configured guild ranks are unavailable")
        end

        local ranks = {}
        local rankNames = {}
        for rankOrder = 1, numberOfRanks do
            local rankName = GuildControlGetRankName(rankOrder)
            if type(rankName) ~= "string" or rankName == "" then
                return incomplete("a configured guild rank is unavailable")
            end

            local permissions = {}
            if type(C_GuildInfo.GuildControlGetRankFlags) == "function" then
                local flagsAvailable, flags = pcall(
                    C_GuildInfo.GuildControlGetRankFlags,
                    rankOrder
                )
                if flagsAvailable and type(flags) == "table" then
                    permissions = flags
                end
            end

            ranks[#ranks + 1] = {
                index = rankOrder,
                name = rankName,
                permissions = {
                    invite = permissions[5] == true,
                    remove = permissions[7] == true,
                    editOfficerNote = permissions[22] == true,
                },
            }
            rankNames[rankOrder] = rankName
        end

        local memberIds = C_Club.GetClubMembers(clubId)
        if type(memberIds) ~= "table" or #memberIds ~= clubInfo.memberCount then
            return incomplete("the guild member list is partial")
        end

        local scannedAt, timestampError = RGMS.DateTime.utcTimestamp(GetServerTime())
        if not scannedAt then
            return nil, "api-failure", timestampError
        end

        local members = {}
        local seenIdentities = {}
        for _, memberId in ipairs(memberIds) do
            local info = C_Club.GetMemberInfo(clubId, memberId)
            if type(info) ~= "table"
                or type(info.name) ~= "string"
                or info.name == ""
                or type(info.guid) ~= "string"
                or info.guid == ""
                or type(info.guildRank) ~= "string"
                or info.guildRank == ""
                or type(info.guildRankOrder) ~= "number"
                or type(info.level) ~= "number"
                or type(info.classID) ~= "number" then
                return incomplete("one or more guild members are partial")
            end

            local configuredRankName = rankNames[info.guildRankOrder]
            if configuredRankName == nil or configuredRankName ~= info.guildRank then
                return incomplete("a guild member refers to an unavailable rank")
            end

            local classInfo = C_CreatureInfo.GetClassInfo(info.classID)
            if type(classInfo) ~= "table"
                or type(classInfo.classFile) ~= "string"
                or classInfo.classFile == "" then
                return incomplete("a guild member class is unavailable")
            end

            local name = info.name
            local realm
            if flavor == ClientFlavor.RETAIL then
                name, realm = Names.splitDisplayName(
                    info.name,
                    GetNormalizedRealmName()
                )
            end

            local identityInput = {
                flavor = flavor,
                region = region,
                name = name,
                guid = info.guid,
            }
            if flavor == ClientFlavor.RETAIL then
                identityInput.realm = realm
            end
            local characterIdentity = CharacterIdentity.create(identityInput)
            local identity = characterIdentity and characterIdentity.key
            if identity == nil or seenIdentities[identity] then
                return incomplete("guild member names are incomplete or duplicated")
            end
            seenIdentities[identity] = true

            local leadershipRole
            if info.role == Enum.ClubRoleIdentifier.Owner
                or info.role == Enum.ClubRoleIdentifier.Leader then
                leadershipRole = "guild-master"
            elseif info.role == Enum.ClubRoleIdentifier.Moderator then
                leadershipRole = "officer"
            end

            local lastOnline
            if info.lastOnlineHour ~= nil then
                if type(info.lastOnlineYear) ~= "number"
                    or type(info.lastOnlineMonth) ~= "number"
                    or type(info.lastOnlineDay) ~= "number"
                    or type(info.lastOnlineHour) ~= "number" then
                    return incomplete("a guild member last-online value is partial")
                end
                lastOnline = {
                    years = info.lastOnlineYear,
                    months = info.lastOnlineMonth,
                    days = info.lastOnlineDay,
                    hours = info.lastOnlineHour,
                }
            end

            members[#members + 1] = {
                identity = identity,
                guid = info.guid,
                name = characterIdentity.name,
                realm = characterIdentity.realm,
                displayName = characterIdentity.displayName,
                rankName = info.guildRank,
                rankIndex = info.guildRankOrder,
                level = info.level,
                classId = info.classID,
                classFileName = classInfo.classFile,
                leadershipRole = leadershipRole,
                isOnline = info.lastOnlineHour == nil,
                lastOnline = lastOnline,
                observedAt = copyTimestamp(scannedAt),
            }
        end

        if #members ~= clubInfo.memberCount then
            return incomplete("one or more guild members are partial")
        end

        table.sort(members, function(left, right)
            if left.displayName ~= right.displayName then
                return left.displayName < right.displayName
            end
            return left.identity < right.identity
        end)

        return {
            guild = guildIdentity,
            scannedAt = scannedAt,
            ranks = ranks,
            members = members,
        }
    end

    return api
end

function Roster.CanScan()
    return RGMS.Reset:canScan("the guild roster")
end

function Roster.CanReport()
    return RGMS.Reset:canReport("the roster report")
end

function Roster.IsScanInProgress()
    local scanner = Roster.Scanner
    return type(scanner) == "table"
        and type(scanner.IsInProgress) == "function"
        and scanner:IsInProgress()
end

function Roster.IsAvailable()
    if type(IsInGuild) ~= "function" then
        return true
    end

    local checked, isInGuild = pcall(IsInGuild)
    return checked and isInGuild == true
end

function Roster.GetGuildIdentityReadiness()
    if not guildReadiness.waiting then
        return nil
    end
    if guildReadiness.exhausted then
        return "exhausted", GUILD_DATA_ACTIONABLE
    end
    return "waiting", WAITING_FOR_GUILD_DATA
end

function Roster.PrimeGuildIdentityPending(reason)
    if reason ~= GUILD_IDENTITY_PENDING then
        return false
    end

    restartIdentityRetry()
    guildReadiness.waiting = true
    if type(Roster.RefreshStatus) == "function" then
        Roster.RefreshStatus()
    end
    return true
end

function Roster.RefreshStatus()
    if type(RGMS.UI) ~= "table" or type(RGMS.UI.SetViewStatus) ~= "function" then
        return
    end

    local disabledState = type(RGMS.SavedDataState) == "table"
        and RGMS.SavedDataState.enabled == false
        and RGMS.SavedDataState
        or (type(RGMS.AccountDataState) == "table"
            and RGMS.AccountDataState.enabled == false
            and RGMS.AccountDataState)
    if disabledState then
        clearGuildReadiness()
        if type(RGMS.UI.SetGuildIdentityPending) == "function" then
            RGMS.UI.SetGuildIdentityPending(false, false)
        end
        if type(RGMS.UI.SetDataState) == "function" then
            RGMS.UI.SetDataState(false, disabledState.status)
        end
        return
    end

    if type(RGMS.UI.SetDataState) == "function" then
        RGMS.UI.SetDataState(true)
    end

    local readiness, readinessMessage = Roster.GetGuildIdentityReadiness()
    if type(RGMS.UI.SetGuildIdentityPending) == "function" then
        RGMS.UI.SetGuildIdentityPending(
            readiness ~= nil,
            readiness == "exhausted"
        )
    end

    local available = Roster.IsAvailable()
    if type(RGMS.UI.SetRosterAvailable) == "function" then
        RGMS.UI.SetRosterAvailable(available)
    end
    if type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RefreshStatus) == "function" then
        RGMS.MainsAlts.RefreshStatus()
    end
    if type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RefreshTags) == "function" then
        RGMS.MainsAlts.RefreshTags()
    end

    if readiness ~= nil then
        if type(RGMS.UI.SetViewContent) == "function" then
            RGMS.UI.SetViewContent("roster", readinessMessage)
        end
        RGMS.UI.SetViewStatus("roster", readinessMessage)
        return
    end

    if type(RGMS.UI.SetRosterReport) == "function"
        and type(RGMS.RosterReport) == "table"
        and type(RGMS.RosterReport.build) == "function"
        and type(RGMS.DB) == "table"
        and type(RGMS.DB.roster) == "table" then
        local report, reportError = RGMS.RosterReport.build(
            RGMS.DB.roster,
            nil,
            RGMS.DateTime
        )
        if report then
            RGMS.UI.SetRosterReport(report)
        else
            RGMS.UI.SetViewStatus(
                "roster",
                "Roster report unavailable: " .. tostring(reportError)
            )
            return
        end
    end

    local scannedAt = type(RGMS.DB) == "table"
        and type(RGMS.DB.roster) == "table"
        and RGMS.DB.roster.scannedAt
    local lastSuccessful
    if scannedAt then
        lastSuccessful = RGMS.DateTime.formatPacificTimestamp(
            scannedAt.unixSeconds
        )
    end

    if Roster.IsScanInProgress() then
        local status = "Updating..."
        if lastSuccessful then
            status = status .. " Last successful update: " .. lastSuccessful
        else
            status = status .. " No successful update yet."
        end
        RGMS.UI.SetViewStatus("roster", status)
        return
    end

    if not available then
        local status = lastSuccessful
            and "Not in a guild. Last successful update: " .. lastSuccessful
            or "Not in a guild. No roster data yet"
        RGMS.UI.SetViewStatus("roster", status)
        return
    end

    local currentCount = 0
    for _, member in ipairs(
        type(RGMS.DB) == "table"
            and type(RGMS.DB.roster) == "table"
            and type(RGMS.DB.roster.members) == "table"
            and RGMS.DB.roster.members
            or {}
    ) do
        if member.isMissing ~= true then
            currentCount = currentCount + 1
        end
    end
    RGMS.UI.SetViewStatus(
        "roster",
        string.format("%d roster character%s", currentCount,
            currentCount == 1 and "" or "s")
    )
end

local function scannerUnavailable(source)
    if source ~= "automatic" then
        RGMS.Print("Could not start the guild roster scan because the scanner is unavailable.")
    end
    return nil, "scanner-unavailable"
end

function Roster.RequestScan(source)
    local scanner = Roster.Scanner
    if type(scanner) ~= "table" or type(scanner.Request) ~= "function" then
        return scannerUnavailable(source)
    end
    return scanner:Request(source)
end

function Roster.ActivateAndRefresh(source, options)
    source = source == "manual" and "manual" or "automatic"
    options = options or {}

    if options.restartIdentityRetry then
        restartIdentityRetry()
    end
    if options.startupRefresh then
        guildReadiness.startupRefreshPending = true
    end
    if source == "manual" then
        guildReadiness.manualRefreshPending = true
    end

    if savedDataIsDisabled() then
        local requestedSource = guildReadiness.manualRefreshPending
            and "manual"
            or source
        clearGuildReadiness()
        Roster.RefreshStatus()
        return Roster.RequestScan(requestedSource)
    end

    local previousIdentityKey = identityKey(RGMS.ActiveGuildIdentity)
    local identity
    local activationError
    local activationReason
    if type(RGMS.ActivateCurrentGuild) == "function" then
        identity, _, activationError, activationReason =
            RGMS.ActivateCurrentGuild()
    end

    if identity == nil and activationReason == GUILD_IDENTITY_PENDING then
        if options.guildTransition and previousIdentityKey ~= nil then
            restartIdentityRetry()
            guildReadiness.startupRefreshPending = true
        end
        guildReadiness.waiting = true
        Roster.RefreshStatus()
        scheduleIdentityRetry()
        return nil, GUILD_IDENTITY_PENDING, activationError
    end

    if identity == nil then
        local requestedSource = guildReadiness.manualRefreshPending
            and "manual"
            or source
        clearGuildReadiness()
        Roster.RefreshStatus()
        return Roster.RequestScan(requestedSource)
    end

    local currentIdentityKey = identityKey(identity)
    if options.guildTransition
        and previousIdentityKey ~= currentIdentityKey then
        guildReadiness.startupRefreshPending = true
    end

    cancelIdentityRetry(true)
    guildReadiness.waiting = false
    guildReadiness.exhausted = false
    guildReadiness.retryIndex = 1

    -- ActivateCurrentGuild has rebound the account partition. Render it before
    -- the scanner changes the status to the in-progress presentation.
    Roster.RefreshStatus()

    if guildReadiness.startupRefreshPending then
        local scannerBusy = Roster.IsScanInProgress()
        local globallyLocked = type(RGMS.IsScanLocked) == "function"
            and RGMS.IsScanLocked()
        if scannerBusy or globallyLocked then
            return identity, "scan-pending"
        end

        local accepted, requestReason, admitted =
            Roster.RequestScan("automatic")
        if accepted or admitted then
            guildReadiness.startupRefreshPending = false
            guildReadiness.manualRefreshPending = false
        end
        return accepted, requestReason, admitted
    end

    if guildReadiness.manualRefreshPending then
        guildReadiness.manualRefreshPending = false
        return Roster.RequestScan("manual")
    end

    if options.requestScan then
        return Roster.RequestScan(source)
    end

    return identity
end

function Roster.RequestManualScan()
    return Roster.ActivateAndRefresh("manual", {
        restartIdentityRetry = guildReadiness.exhausted,
    })
end

function Roster.RequestAutomaticScan()
    return Roster.ActivateAndRefresh("automatic", {
        requestScan = true,
    })
end

function Roster.OnGlobalScanLockReleased()
    if guildReadiness.releasingRosterScan then
        if guildReadiness.startupRefreshPending then
            guildReadiness.scanLockRetryDeferred = true
        end
        return false
    end
    if not guildReadiness.startupRefreshPending
        or guildReadiness.waiting
        or Roster.IsScanInProgress() then
        return false
    end
    return Roster.ActivateAndRefresh("automatic")
end

function Roster.AcknowledgeNewsSet(setId)
    if type(RGMS.AccountDataState) ~= "table"
        or not RGMS.AccountDataState.enabled
        or type(RGMS.ActiveGuildIdentity) ~= "table" then
        return nil, "account guild data is unavailable"
    end
    local guild = RGMS.AccountData.findGuild(
        RGMS.AccountDataState.model,
        RGMS.ActiveGuildIdentity
    )
    if not guild then
        return nil, "current guild partition is unavailable"
    end
    local newsSets, acknowledgeError = RGMS.RosterNews.acknowledge(
        guild.newsSets,
        setId
    )
    if not newsSets then
        return nil, acknowledgeError
    end
    local model, replaceError = RGMS.AccountData.replaceRosterNews(
        RGMS.AccountDataState.model,
        RGMS.ActiveGuildIdentity,
        guild.rosterObservation,
        newsSets
    )
    if not model then
        return nil, replaceError
    end
    RGMSAccountDB = model
    RGMS.AccountDataState.model = model
    RGMS.DB = RGMS.AccountData.view(
        model,
        RGMS.ActiveGuildIdentity,
        RGMS.SavedDataState.model.ui
    )
    if type(RGMS.UI) == "table"
        and type(RGMS.UI.SetNewsSets) == "function" then
        RGMS.UI.SetNewsSets(RGMS.DB.newsSets)
    end
    return true
end

Roster.CreateModernApi = createModernApi
Roster.CreateRetailApi = createModernApi
RGMS.Roster = Roster

if type(Roster.Scanner) ~= "table"
    and type(RGMS.RosterScanner) == "table"
    and type(C_GuildInfo) == "table"
    and type(C_Club) == "table" then
    Roster.Scanner = RGMS.RosterScanner.create({
        api = createModernApi(),
        ownership = RGMS.DatasetOwnership,
        reduceRoster = function(previousDataset, snapshot)
            return RGMS.RosterTenure.reduce(
                previousDataset,
                snapshot,
                RGMS.DateTime
            )
        end,
        canScan = Roster.CanScan,
        getCurrentGuildIdentity = RGMS.ResolveCurrentGuildIdentity,
        isScanLocked = RGMS.IsScanLocked,
        beginScan = function()
            return RGMS.BeginScan("roster")
        end,
        endScan = function()
            guildReadiness.releasingRosterScan = true
            local released, releaseError = RGMS.EndScan("roster")
            guildReadiness.releasingRosterScan = false
            return released, releaseError
        end,
        rejectConcurrentScan = RGMS.RejectConcurrentScan,
        print = RGMS.Print,
        setInProgress = function(inProgress)
            if type(RGMS.UI) == "table"
                and type(RGMS.UI.SetRosterScanInProgress) == "function" then
                RGMS.UI.SetRosterScanInProgress(inProgress)
            end
            Roster.RefreshStatus()
        end,
        completeSuccess = function(newsCreated)
            if type(RGMS.MainsAlts) == "table"
                and type(RGMS.MainsAlts.RefreshGuildNotes) == "function" then
                RGMS.MainsAlts.RefreshGuildNotes()
            end
            if type(RGMS.UI) == "table"
                and type(RGMS.UI.CompleteRosterScan) == "function" then
                RGMS.UI.CompleteRosterScan(newsCreated)
            end
        end,
        refreshStatus = Roster.RefreshStatus,
    })

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
    eventFrame:RegisterEvent("INITIAL_CLUBS_LOADED")
    eventFrame:RegisterEvent("CLUB_MEMBERS_UPDATED")
    eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            Roster.ActivateAndRefresh("automatic", {
                restartIdentityRetry = true,
                startupRefresh = true,
            })
        elseif event == "GUILD_ROSTER_UPDATE" then
            local canRequestRosterUpdate = ...
            if canRequestRosterUpdate then
                Roster.Scanner:RequestRosterUpdate()
            else
                Roster.Scanner:OnDataUpdated()
            end
        elseif event == "INITIAL_CLUBS_LOADED" then
            if guildReadiness.waiting
                or guildReadiness.startupRefreshPending then
                Roster.ActivateAndRefresh("automatic")
            end
            Roster.Scanner:RequestRosterUpdate()
        elseif event == "CLUB_MEMBERS_UPDATED" then
            if guildReadiness.waiting
                or guildReadiness.startupRefreshPending then
                Roster.ActivateAndRefresh("automatic")
            end
            Roster.Scanner:OnDataUpdated()
        elseif event == "PLAYER_GUILD_UPDATE" then
            Roster.ActivateAndRefresh("automatic", {
                guildTransition = true,
            })
            if Roster.IsScanInProgress()
                and type(Roster.Scanner.OnDataUpdated) == "function" then
                Roster.Scanner:OnDataUpdated()
            end
        end
    end)
    eventFrame:SetScript("OnUpdate", function(_, elapsed)
        Roster.Scanner:Update(elapsed)
        if guildReadiness.scanLockRetryDeferred then
            guildReadiness.scanLockRetryDeferred = false
            Roster.OnGlobalScanLockReleased()
        end
    end)
    Roster.EventFrame = eventFrame
end

return Roster
