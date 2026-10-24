local _, RGMS = ...

local Roster = RGMS.Roster or {}
local Names = type(RGMS.RosterNames) == "table"
    and RGMS.RosterNames
    or require("Roster.Names")
local Realm = type(RGMS.Realm) == "table"
    and RGMS.Realm
    or require("Core.Realm")

local REGION_NAMES = {
    [1] = "US",
    [2] = "KR",
    [3] = "EU",
    [4] = "TW",
    [5] = "CN",
}

local function incomplete(message)
    return nil, "incomplete", message
end

local function copyTimestamp(timestamp)
    return {
        unixSeconds = timestamp.unixSeconds,
        iso8601 = timestamp.iso8601,
    }
end

local function createRetailApi()
    local api = {}

    function api:isInGuild()
        return IsInGuild() == true
    end

    function api:requestRoster()
        C_GuildInfo.GuildRoster()
    end

    function api:captureSnapshot()
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

        local guildName, _, _, guildRealm = GetGuildInfo("player")
        guildName = clubInfo.name or guildName
        local normalizedRealm = guildRealm or GetNormalizedRealmName()
        local displayRealm = guildRealm or GetRealmName()
        if type(guildName) ~= "string" or guildName == ""
            or type(normalizedRealm) ~= "string" or normalizedRealm == ""
            or type(displayRealm) ~= "string" or displayRealm == "" then
            return incomplete("guild name or realm is unavailable")
        end
        normalizedRealm = Realm.normalize(normalizedRealm)
        displayRealm = Realm.normalize(displayRealm)

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
        local seenNames = {}
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

            local name, realm, displayName = Names.splitDisplayName(
                info.name,
                GetNormalizedRealmName()
            )
            if name == "" or realm == "" or seenNames[displayName] then
                return incomplete("guild member names are incomplete or duplicated")
            end
            seenNames[displayName] = true

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
                guid = info.guid,
                name = name,
                realm = realm,
                displayName = displayName,
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

        table.sort(members, function(left, right)
            return left.displayName < right.displayName
        end)

        return {
            guild = {
                id = tostring(clubId),
                name = guildName,
                realm = {
                    name = displayRealm,
                    slug = normalizedRealm,
                },
                region = REGION_NAMES[GetCurrentRegion()] or "Unknown",
            },
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
        if type(RGMS.UI.SetDataState) == "function" then
            RGMS.UI.SetDataState(false, disabledState.status)
        end
        return
    end

    if type(RGMS.UI.SetDataState) == "function" then
        RGMS.UI.SetDataState(true)
    end

    local available = Roster.IsAvailable()
    if type(RGMS.UI.SetRosterAvailable) == "function" then
        RGMS.UI.SetRosterAvailable(available)
    end
    if type(RGMS.MainsAlts) == "table"
        and type(RGMS.MainsAlts.RefreshStatus) == "function" then
        RGMS.MainsAlts.RefreshStatus()
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

function Roster.RequestManualScan()
    return Roster.RequestScan("manual")
end

function Roster.RequestAutomaticScan()
    return Roster.RequestScan("automatic")
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

Roster.CreateRetailApi = createRetailApi
RGMS.Roster = Roster

if type(Roster.Scanner) ~= "table"
    and type(RGMS.RosterScanner) == "table"
    and type(C_GuildInfo) == "table"
    and type(C_Club) == "table" then
    Roster.Scanner = RGMS.RosterScanner.create({
        api = createRetailApi(),
        ownership = RGMS.DatasetOwnership,
        reduceRoster = function(previousDataset, snapshot)
            return RGMS.RosterTenure.reduce(
                previousDataset,
                snapshot,
                RGMS.DateTime
            )
        end,
        canScan = Roster.CanScan,
        isScanLocked = RGMS.IsScanLocked,
        beginScan = function()
            return RGMS.BeginScan("roster")
        end,
        endScan = function()
            return RGMS.EndScan("roster")
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
            if type(RGMS.ActivateCurrentGuild) == "function" then
                RGMS.ActivateCurrentGuild()
            end
            Roster.RequestAutomaticScan()
        elseif event == "GUILD_ROSTER_UPDATE" then
            local canRequestRosterUpdate = ...
            if canRequestRosterUpdate then
                Roster.Scanner:RequestRosterUpdate()
            else
                Roster.Scanner:OnDataUpdated()
            end
        elseif event == "INITIAL_CLUBS_LOADED" then
            Roster.Scanner:RequestRosterUpdate()
        elseif event == "CLUB_MEMBERS_UPDATED" then
            Roster.Scanner:OnDataUpdated()
        elseif event == "PLAYER_GUILD_UPDATE" then
            local identity
            local rosterInitialized = false
            if type(RGMS.ActivateCurrentGuild) == "function" then
                identity, rosterInitialized = RGMS.ActivateCurrentGuild()
            end
            Roster.RefreshStatus()
            if identity ~= nil and rosterInitialized then
                Roster.RequestAutomaticScan()
            end
        end
    end)
    eventFrame:SetScript("OnUpdate", function(_, elapsed)
        Roster.Scanner:Update(elapsed)
    end)
    Roster.EventFrame = eventFrame
end

return Roster
