local _, RGMS = ...

local Bank = RGMS.Bank or {}
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
local SLOTS_PER_TAB = 98

local function incomplete(message)
    return nil, "incomplete", message
end

local function captureGuildIdentity()
    local clubId = C_Club.GetGuildClubId()
    if clubId == nil then
        return incomplete("the guild club is not initialized")
    end

    local clubInfo = C_Club.GetClubInfo(clubId)
    local guildName, _, _, guildRealm = GetGuildInfo("player")
    guildName = type(clubInfo) == "table" and clubInfo.name or guildName
    local normalizedRealm = guildRealm or GetNormalizedRealmName()
    local displayRealm = guildRealm or GetRealmName()
    if type(guildName) ~= "string" or guildName == ""
        or type(normalizedRealm) ~= "string" or normalizedRealm == ""
        or type(displayRealm) ~= "string" or displayRealm == "" then
        return incomplete("guild name or realm is unavailable")
    end

    return {
        id = tostring(clubId),
        name = guildName,
        realm = {
            name = Realm.normalize(displayRealm),
            slug = Realm.normalize(normalizedRealm),
        },
        region = REGION_NAMES[GetCurrentRegion()] or "Unknown",
    }
end

local function displayedTabName(name, tabIndex)
    if type(name) == "string" and name ~= "" then
        return name
    end
    if type(GUILDBANK_TAB_NUMBER) == "string" then
        return string.format(GUILDBANK_TAB_NUMBER, tabIndex)
    end
    return "Tab " .. tostring(tabIndex)
end

local function createRetailApi()
    local api = {}

    function api:isOpen()
        return GuildBankFrame ~= nil
            and type(GuildBankFrame.IsShown) == "function"
            and GuildBankFrame:IsShown()
    end

    function api:captureCatalog()
        local guild, guildState, guildError = captureGuildIdentity()
        if not guild then
            return nil, guildState, guildError
        end

        local tabCount = GetNumGuildBankTabs()
        if type(tabCount) ~= "number"
            or tabCount < 0
            or tabCount ~= math.floor(tabCount) then
            return incomplete("the purchased guild-bank tab count is unavailable")
        end

        local tabs = {}
        for tabIndex = 1, tabCount do
            local name, icon, isViewable, canDeposit, withdrawalsPerDay =
                GetGuildBankTabInfo(tabIndex)
            if (type(icon) ~= "number" and type(icon) ~= "string")
                or (isViewable ~= nil and type(isViewable) ~= "boolean")
                or (canDeposit ~= nil and type(canDeposit) ~= "boolean")
                or type(withdrawalsPerDay) ~= "number" then
                return incomplete(
                    "guild-bank tab " .. tabIndex .. " access data is unavailable"
                )
            end

            tabs[#tabs + 1] = {
                index = tabIndex,
                name = displayedTabName(name, tabIndex),
                icon = icon,
                isViewable = isViewable == true,
                canDeposit = canDeposit == true,
                withdrawalsPerDay = withdrawalsPerDay,
            }
        end

        return {
            guild = guild,
            tabs = tabs,
        }
    end

    function api:requestTab(tabIndex)
        QueryGuildBankTab(tabIndex)
    end

    function api:captureTab(tabIndex)
        local slots = {}
        for slotIndex = 1, SLOTS_PER_TAB do
            local texture, quantity, isLocked = GetGuildBankItemInfo(
                tabIndex,
                slotIndex
            )
            local itemLink = GetGuildBankItemLink(tabIndex, slotIndex)
            local occupied = texture ~= nil
                or itemLink ~= nil
                or (type(quantity) == "number" and quantity > 0)

            if occupied then
                if (type(texture) ~= "number" and type(texture) ~= "string")
                    or type(itemLink) ~= "string"
                    or itemLink == ""
                    or type(quantity) ~= "number"
                    or quantity < 1
                    or quantity ~= math.floor(quantity)
                    or (isLocked ~= nil and type(isLocked) ~= "boolean") then
                    return incomplete(
                        "guild-bank tab "
                            .. tabIndex
                            .. " slot "
                            .. slotIndex
                            .. " is partial"
                    )
                end

                local itemId = tonumber(itemLink:match("item:(%d+)"))
                if itemId == nil or itemId < 1 or itemId ~= math.floor(itemId) then
                    return incomplete(
                        "guild-bank tab "
                            .. tabIndex
                            .. " slot "
                            .. slotIndex
                            .. " has no basic item ID"
                    )
                end

                slots[#slots + 1] = {
                    tabIndex = tabIndex,
                    slotIndex = slotIndex,
                    itemId = itemId,
                    itemLink = itemLink,
                    quantity = quantity,
                    isLocked = isLocked == true,
                }
            elseif quantity ~= nil and quantity ~= 0 then
                return incomplete(
                    "guild-bank tab "
                        .. tabIndex
                        .. " slot "
                        .. slotIndex
                        .. " is partial"
                )
            end
        end
        return slots
    end

    function api:captureTimestamp()
        local timestamp, timestampError = RGMS.DateTime.utcTimestamp(GetServerTime())
        if not timestamp then
            return nil, "api-failure", timestampError
        end
        return timestamp
    end

    return api
end

function Bank.CanScan()
    return RGMS.Reset:canScan("the guild bank")
end

function Bank.CanReport()
    return RGMS.Reset:canReport("the bank report")
end

function Bank.IsScanInProgress()
    local scanner = Bank.Scanner
    return type(scanner) == "table"
        and type(scanner.IsInProgress) == "function"
        and scanner:IsInProgress()
end

function Bank.RefreshStatus()
    if type(RGMS.UI) ~= "table" or type(RGMS.UI.SetViewStatus) ~= "function" then
        return
    end

    if Bank.IsScanInProgress() then
        RGMS.UI.SetViewStatus("bank", "Scanning...")
        return
    end

    local scannedAt = type(RGMS.DB) == "table"
        and type(RGMS.DB.bank) == "table"
        and RGMS.DB.bank.scannedAt
    if scannedAt then
        local formatted = RGMS.DateTime.formatPacificTimestamp(scannedAt.unixSeconds)
        RGMS.UI.SetViewStatus("bank", "Last successful scan: " .. formatted)
    else
        RGMS.UI.SetViewStatus("bank", "No bank data yet")
    end
end

local function scannerUnavailable(source)
    if source ~= "automatic" and type(RGMS.Print) == "function" then
        RGMS.Print("Could not start the guild bank scan because the scanner is unavailable.")
    end
    return nil, "scanner-unavailable"
end

function Bank.RequestScan(source)
    local scanner = Bank.Scanner
    if type(scanner) ~= "table" or type(scanner.Request) ~= "function" then
        return scannerUnavailable(source)
    end
    return scanner:Request(source)
end

function Bank.RequestManualScan()
    return Bank.RequestScan("manual")
end

function Bank.RequestAutomaticScan()
    return Bank.RequestScan("automatic")
end

function Bank.CancelScan()
    local scanner = Bank.Scanner
    if type(scanner) ~= "table" or type(scanner.Cancel) ~= "function" then
        return false
    end
    return scanner:Cancel()
end

local function setGuildBankOpen(isOpen)
    if type(RGMS.UI) == "table"
        and type(RGMS.UI.SetGuildBankOpen) == "function" then
        RGMS.UI.SetGuildBankOpen(isOpen)
    end
end

local function alignWithGuildBank()
    if GuildBankFrame == nil
        or type(GuildBankFrame.IsShown) ~= "function"
        or not GuildBankFrame:IsShown() then
        return
    end

    RGMS.UI.AlignToRightOf(GuildBankFrame)
end

Bank.CreateRetailApi = createRetailApi
RGMS.Bank = Bank

if type(Bank.Scanner) ~= "table"
    and type(RGMS.BankScanner) == "table"
    and type(C_Club) == "table"
    and type(GetNumGuildBankTabs) == "function" then
    Bank.Scanner = RGMS.BankScanner.create({
        api = createRetailApi(),
        ownership = RGMS.DatasetOwnership,
        reduceBank = function(_, snapshot)
            return {
                guild = snapshot.guild,
                scannedAt = snapshot.scannedAt,
                tabs = snapshot.tabs,
                slots = snapshot.slots,
            }
        end,
        canScan = Bank.CanScan,
        print = RGMS.Print,
        setInProgress = function(inProgress)
            if type(RGMS.UI) == "table"
                and type(RGMS.UI.SetBankScanInProgress) == "function" then
                RGMS.UI.SetBankScanInProgress(inProgress)
            end
            Bank.RefreshStatus()
        end,
        refreshStatus = Bank.RefreshStatus,
    })
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
eventFrame:RegisterEvent("GUILDBANKFRAME_CLOSED")
eventFrame:RegisterEvent("GUILDBANKBAGSLOTS_CHANGED")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
eventFrame:RegisterEvent("UI_SCALE_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, interactionType)
    if event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        if interactionType ~= Enum.PlayerInteractionType.GuildBanker then
            return
        end

        setGuildBankOpen(true)
        local shown = RGMS.UI.Show("bank")
        if shown then
            alignWithGuildBank()
        end
        Bank.RequestAutomaticScan()
        return
    end

    if event == "GUILDBANKFRAME_CLOSED" then
        setGuildBankOpen(false)
        Bank.CancelScan()
        return
    end

    if event == "GUILDBANKBAGSLOTS_CHANGED" then
        if type(Bank.Scanner) == "table"
            and type(Bank.Scanner.OnSlotsChanged) == "function" then
            Bank.Scanner:OnSlotsChanged()
        end
        return
    end

    if RGMS.UI.IsShown() then
        alignWithGuildBank()
    end
end)
eventFrame:SetScript("OnUpdate", function(_, elapsed)
    if type(Bank.Scanner) == "table"
        and type(Bank.Scanner.Update) == "function" then
        Bank.Scanner:Update(elapsed)
    end
end)

Bank.EventFrame = eventFrame

return Bank
