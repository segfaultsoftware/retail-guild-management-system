local bankScannerModule = require("Bank.Scanner")
local bankState = require("Bank.State")
local commands = require("Core.Commands")
local datasetOwnership = require("Core.DatasetOwnership")
local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local mvp = require("Tests.mvp_fixtures")
local resetModule = require("Core.Reset")
local rosterScannerModule = require("Roster.Scanner")
local savedData = require("Core.SavedData")
local tenure = require("Roster.Tenure")
local test = require("Tests.lib.runner")

local function transition(name, callback)
    local succeeded, failure = pcall(callback)
    if not succeeded then
        error("transition [" .. name .. "] failed: " .. tostring(failure), 2)
    end
end

local function memberSnapshot(date, options)
    options = options or {}
    local member = mvp.roster_member(date, options.member)
    return mvp.roster_snapshot(date, {
        guild = options.guild,
        ranks = options.ranks,
        members = { member },
    })
end

local function newSession(options)
    options = options or {}
    local session = {
        current = options.model or savedData.newModel(),
        messages = {},
        confirmations = {},
        state = nil,
        inGuild = options.inGuild ~= false,
        bankOpen = options.bankOpen == true,
        rosterCaptureMode = "success",
        rosterSnapshot = nil,
        bankCatalog = nil,
        bankSlots = {},
        bankTimestamp = nil,
        bankMoney = options.bankMoney or 1233452412,
        rosterRequests = 0,
        bankRequests = {},
        ui = {
            windowShown = false,
            selectedTab = "roster",
            rosterInProgress = false,
            bankInProgress = false,
        },
    }
    session.state = savedData.load(session.current)

    local function record(message)
        session.messages[#session.messages + 1] = message
    end

    session.ownership = datasetOwnership.create({
        savedData = savedData,
        getSavedData = function()
            return session.current
        end,
        commit = function(model)
            session.current = model
            if type(session.state) == "table" and session.state.enabled then
                session.state.model = model
            end
        end,
        print = record,
    })

    session.rosterScanner = rosterScannerModule.create({
        api = {
            isInGuild = function()
                return session.inGuild
            end,
            requestRoster = function()
                session.rosterRequests = session.rosterRequests + 1
            end,
            captureSnapshot = function()
                if session.rosterCaptureMode == "partial" then
                    return nil, "incomplete", "member list is partial"
                end
                if session.rosterCaptureMode == "error" then
                    error("simulated roster API failure")
                end
                return session.rosterSnapshot
            end,
        },
        ownership = session.ownership,
        reduceRoster = function(previousDataset, snapshot)
            return tenure.reduce(previousDataset, snapshot, dateTime)
        end,
        timeoutSeconds = 2,
        canScan = function()
            return session.state.enabled == true
        end,
        print = record,
        setInProgress = function(inProgress)
            session.ui.rosterInProgress = inProgress
        end,
        refreshStatus = function()
        end,
    })

    session.bankScanner = bankScannerModule.create({
        api = {
            isOpen = function()
                return session.bankOpen
            end,
            captureCatalog = function()
                return session.bankCatalog
            end,
            requestTab = function(_, tabIndex)
                session.bankRequests[#session.bankRequests + 1] = tabIndex
            end,
            captureTab = function(_, tabIndex)
                return session.bankSlots[tabIndex] or {}
            end,
            captureTimestamp = function()
                return session.bankTimestamp
            end,
            captureMoney = function()
                return session.bankMoney
            end,
        },
        ownership = session.ownership,
        reduceBank = function(previousDataset, snapshot)
            return bankState.reduce(previousDataset, snapshot, dateTime)
        end,
        timeoutSeconds = 2,
        canScan = function()
            return session.state.enabled == true
        end,
        print = record,
        setInProgress = function(inProgress)
            session.ui.bankInProgress = inProgress
        end,
        refreshStatus = function()
        end,
    })

    session.reset = resetModule.create({
        savedData = savedData,
        getSavedData = function()
            return session.current
        end,
        getState = function()
            return session.state
        end,
        commit = function(model, state)
            session.current = model
            session.state = state
        end,
        showConfirmation = function(request)
            session.confirmations[#session.confirmations + 1] = request
        end,
        print = record,
        setDataState = function(enabled)
            session.state.enabled = enabled
        end,
        refreshViews = function()
        end,
    })

    session.commandApi = {
        Print = record,
        UI = {
            Toggle = function(selectedTab)
                session.ui.windowShown = not session.ui.windowShown
                session.ui.selectedTab = selectedTab
            end,
        },
        Roster = {
            RequestManualScan = function()
                return session.rosterScanner:Request("manual")
            end,
        },
        Reset = session.reset,
    }

    function session:scanRoster(snapshot, source)
        self.rosterCaptureMode = "success"
        self.rosterSnapshot = snapshot
        local started, reason = self.rosterScanner:Request(source or "manual")
        if not started then
            return started, reason
        end
        return self.rosterScanner:OnDataUpdated()
    end

    function session:startBankScan(catalog, slotsByTab, date, source)
        self.bankOpen = true
        self.bankCatalog = catalog
        self.bankSlots = slotsByTab or {}
        self.bankTimestamp = {
            unixSeconds = date.unixSeconds,
            iso8601 = date.iso8601,
        }
        return self.bankScanner:Request(source or "manual")
    end

    function session:finishBankScan()
        while self.bankScanner:IsInProgress()
            and self.bankScanner.work.requestedTab ~= nil do
            local completed, state = self.bankScanner:OnSlotsChanged()
            if completed == nil or state == "incomplete" then
                return completed, state
            end
            if state == "empty-retry" then
                local requested, requestState = self.bankScanner:Update(1)
                if requested == nil then
                    return requested, requestState
                end
            end
        end
        return true
    end

    function session:scanBank(catalog, slotsByTab, date, source)
        local started, reason = self:startBankScan(catalog, slotsByTab, date, source)
        if not started then
            return started, reason
        end
        return self:finishBankScan()
    end

    function session:closeRgms()
        self.ui.windowShown = false
        self.bankScanner:Cancel()
    end

    function session:closeBank()
        self.bankOpen = false
        self.bankScanner:Cancel()
    end

    function session:reload()
        local loaded = savedData.load(self.current)
        if loaded.enabled then
            self.current = loaded.model
            self.state = loaded
        end
        return loaded
    end

    function session:rosterRefreshEnabled()
        return self.state.enabled == true
            and self.inGuild
            and not self.rosterScanner:IsInProgress()
    end

    function session:bankRefreshEnabled()
        return self.state.enabled == true
            and self.bankOpen
            and not self.bankScanner:IsInProgress()
    end

    return session
end

local function scanInitialRoster(session, date, guild)
    return session:scanRoster(memberSnapshot(date, {
        guild = guild,
        ranks = mvp.ranks("Member"),
        member = {
            rankName = "Member",
            rankIndex = 2,
            isOnline = true,
        },
    }), "automatic")
end

return {
    test.case("MVP-E2E-01 guilded first login persists and reloads roster state", function()
        local session = newSession()

        transition("automatic first-login scan", function()
            test.assert_true(scanInitialRoster(session, mvp.dates.day1Morning))
            test.assert_false(session.ui.rosterInProgress)
            test.assert_equal(session.current.roster.scannedAt.iso8601, "2024-06-01T16:00:00Z")
            test.assert_equal(session.current.roster.members[1].rankTenureStartDate, "2024-06-01")
            test.assert_equal(
                session.messages[#session.messages],
                "Guild roster scan complete: 1 members across 3 ranks."
            )
        end)

        transition("saved-variable reload", function()
            local persisted = session.current
            local loaded = session:reload()
            test.assert_true(loaded.enabled)
            test.assert_equal(session.current, persisted)
            test.assert_true(savedData.validate(session.current))
        end)
    end),

    test.case("MVP-E2E-02 unguilded login remains empty until a later manual scan", function()
        local session = newSession({ inGuild = false })

        transition("silent unguilded automatic request", function()
            local started, reason = session.rosterScanner:Request("automatic")
            test.assert_nil(started)
            test.assert_equal(reason, "not-in-guild")
            test.assert_equal(session.messages, {})
            test.assert_equal(session.current, savedData.newModel())
        end)

        transition("explicit unguilded manual request", function()
            local started, reason = session.rosterScanner:Request("manual")
            test.assert_nil(started)
            test.assert_equal(reason, "not-in-guild")
            test.assert_equal(
                session.messages[#session.messages],
                "Cannot scan the guild roster because this character is not in a guild."
            )
        end)

        transition("manual scan after joining", function()
            session.inGuild = true
            local snapshot = memberSnapshot(mvp.dates.day2, {
                member = { isOnline = true },
            })
            test.assert_true(session:scanRoster(snapshot, "manual"))
            test.assert_equal(session.current.roster.scannedAt.iso8601, "2024-06-02T16:00:00Z")
            test.assert_true(session:rosterRefreshEnabled())
        end)
    end),

    test.case("MVP-E2E-03 roster rank missing retention and reappearance timeline", function()
        local session = newSession()

        transition("day 1 initial observation", function()
            test.assert_true(scanInitialRoster(session, mvp.dates.day1Morning))
        end)

        transition("same-day rank rename", function()
            local snapshot = memberSnapshot(mvp.dates.day1Afternoon, {
                ranks = mvp.ranks("Raider"),
                member = {
                    rankName = "Raider",
                    rankIndex = 2,
                    isOnline = true,
                },
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(session.current.roster.members[1].rankTenureStartDate, "2024-06-01")
            test.assert_equal(session.current.roster.members[1].rankName, "Raider")
        end)

        transition("day 2 same-rank carry-forward", function()
            local snapshot = memberSnapshot(mvp.dates.day2, {
                ranks = mvp.ranks("Raider"),
                member = {
                    rankName = "Raider",
                    rankIndex = 2,
                    isOnline = true,
                },
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(
                session.current.roster.members[1].rankTenureStartDate,
                "2024-06-01"
            )
        end)

        transition("day 2 promotion", function()
            local snapshot = memberSnapshot(mvp.dates.day2, {
                ranks = mvp.ranks("Raider"),
                member = {
                    rankName = "Officer",
                    rankIndex = 1,
                    isOnline = true,
                },
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(session.current.roster.members[1].rankTenureStartDate, "2024-06-02")
        end)

        transition("day 3 demotion", function()
            local snapshot = memberSnapshot(mvp.dates.day3, {
                ranks = mvp.ranks("Raider"),
                member = {
                    rankName = "Raider",
                    rankIndex = 2,
                    isOnline = true,
                },
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(session.current.roster.members[1].rankTenureStartDate, "2024-06-03")
        end)

        transition("first missing day", function()
            local snapshot = mvp.roster_snapshot(mvp.dates.day4, {
                ranks = mvp.ranks("Raider"),
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_true(session.current.roster.members[1].isMissing)
            test.assert_equal(session.current.roster.members[1].lastSeenDate, "2024-06-03")
            test.assert_equal(session.current.roster.members[1].lastOnline.days, 1)
        end)

        transition("missing day 21 retained", function()
            local snapshot = mvp.roster_snapshot(mvp.dates.missingDay21, {
                ranks = mvp.ranks("Raider"),
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(#session.current.roster.members, 1)
            test.assert_true(session.current.roster.members[1].isMissing)
            test.assert_equal(session.current.roster.members[1].lastOnline.days, 21)
        end)

        transition("missing day 22 removed", function()
            local snapshot = mvp.roster_snapshot(mvp.dates.missingDay22, {
                ranks = mvp.ranks("Raider"),
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(#session.current.roster.members, 0)
        end)

        transition("reappearance creates a fresh tenure", function()
            local snapshot = memberSnapshot(mvp.dates.reappeared, {
                ranks = mvp.ranks("Raider"),
                member = {
                    rankName = "Raider",
                    rankIndex = 2,
                    isOnline = true,
                },
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(session.current.roster, mvp.expected_roster_after_reappearance())
        end)
    end),

    test.case("MVP-E2E-04 roster failures preserve prior data with RGMS closed", function()
        local session = newSession()
        test.assert_true(scanInitialRoster(session, mvp.dates.day1Morning))
        local committed = session.current

        transition("partial update continues after window close", function()
            session.rosterCaptureMode = "partial"
            test.assert_true(session.rosterScanner:Request("manual"))
            session.ui.windowShown = false
            local completed, state = session.rosterScanner:OnDataUpdated()
            test.assert_false(completed)
            test.assert_equal(state, "incomplete")
            test.assert_true(session.rosterScanner:IsInProgress())
            test.assert_equal(session.current, committed)
        end)

        transition("closed-window timeout", function()
            local completed, reason = session.rosterScanner:Update(2)
            test.assert_nil(completed)
            test.assert_equal(reason, "timeout")
            test.assert_equal(session.current, committed)
            test.assert_matches(session.messages[#session.messages], "timed out")
        end)

        transition("client API failure", function()
            session.rosterCaptureMode = "error"
            test.assert_true(session.rosterScanner:Request("automatic"))
            local completed, reason = session.rosterScanner:OnDataUpdated()
            test.assert_nil(completed)
            test.assert_equal(reason, "api-failure")
            test.assert_equal(session.current, committed)
            test.assert_matches(session.messages[#session.messages], "simulated roster API failure")
        end)
    end),

    test.case("MVP-E2E-05 bank access and item transitions persist atomically", function()
        local session = newSession({ bankOpen = true })
        local catalog = mvp.bank_catalog(nil, false)

        transition("mixed-access full success", function()
            test.assert_true(session:scanBank(catalog, {
                [1] = { mvp.bank_slot(1, 1, 1001, 20) },
            }, mvp.dates.day1Morning, "automatic"))
            test.assert_equal(session.bankRequests, { 1 })
            test.assert_equal(session.current.bank.slots[1].stableSinceDate, "2024-06-01")
            test.assert_equal(
                session.messages[#session.messages],
                "Guild bank scan complete: 2 purchased tabs, 1 accessible, 1 occupied slots."
            )
            local persisted = session.current
            test.assert_true(session:reload().enabled)
            test.assert_equal(session.current, persisted)
        end)

        transition("unchanged item", function()
            test.assert_true(session:scanBank(catalog, {
                [1] = { mvp.bank_slot(1, 1, 1001, 20) },
            }, mvp.dates.day2))
            test.assert_equal(session.current.bank.slots[1].stableSinceDate, "2024-06-01")
        end)

        transition("count changed", function()
            test.assert_true(session:scanBank(catalog, {
                [1] = { mvp.bank_slot(1, 1, 1001, 10) },
            }, mvp.dates.day3))
            test.assert_equal(session.current.bank.slots[1].stableSinceDate, "2024-06-03")
        end)

        transition("item replaced", function()
            test.assert_true(session:scanBank(catalog, {
                [1] = { mvp.bank_slot(1, 1, 2002, 5) },
            }, mvp.dates.day4))
            test.assert_equal(session.current.bank.slots[1].stableSinceDate, "2024-06-04")
        end)

        transition("slot emptied", function()
            test.assert_true(session:scanBank(catalog, { [1] = {} }, mvp.dates.day5))
            test.assert_equal(session.current.bank.slots, {})
        end)

        transition("item moved", function()
            test.assert_true(session:scanBank(catalog, {
                [1] = { mvp.bank_slot(1, 2, 2002, 5) },
            }, mvp.dates.day6))
            test.assert_equal(session.current.bank.slots[1].slotIndex, 2)
            test.assert_equal(session.current.bank.slots[1].stableSinceDate, "2024-06-06")
        end)

        transition("tab inaccessible retains last observation", function()
            local inaccessible = mvp.bank_catalog(nil, false)
            inaccessible.tabs[1].isViewable = false
            inaccessible.tabs[1].canDeposit = false
            test.assert_true(session:scanBank(inaccessible, {}, mvp.dates.day7))
            test.assert_equal(session.current.bank.slots[1].slotIndex, 2)
            test.assert_equal(
                session.current.bank.slots[1].observedAt.iso8601,
                "2024-06-06T16:00:00Z"
            )
            test.assert_equal(
                session.current.bank.tabs[1].lastAccessibleAt.iso8601,
                "2024-06-06T16:00:00Z"
            )
        end)

        transition("tab accessible again", function()
            test.assert_true(session:scanBank(catalog, {
                [1] = { mvp.bank_slot(1, 2, 2002, 5) },
            }, mvp.dates.day8))
            test.assert_equal(session.current.bank, mvp.expected_bank_after_access_returns())
        end)
    end),

    test.case("MVP-E2E-06 both bank cancellation paths preserve committed state", function()
        local session = newSession({ bankOpen = true })
        local initialCatalog = mvp.bank_catalog(nil, false)
        test.assert_true(session:scanBank(initialCatalog, {
            [1] = { mvp.bank_slot(1, 1, 1001, 20) },
        }, mvp.dates.day1Morning))
        local committed = session.current
        local twoAccessible = mvp.bank_catalog(nil, true)

        transition("closing RGMS cancels after a partial tab", function()
            test.assert_true(session:startBankScan(twoAccessible, {
                [1] = { mvp.bank_slot(1, 1, 1001, 99) },
                [2] = { mvp.bank_slot(2, 1, 3003, 1) },
            }, mvp.dates.day2))
            test.assert_true(session.bankScanner:OnSlotsChanged())
            test.assert_true(session.bankScanner:IsInProgress())
            session:closeRgms()
            test.assert_false(session.bankScanner:IsInProgress())
            test.assert_equal(session.current, committed)
        end)

        transition("closing guild bank cancels immediately", function()
            test.assert_true(session:startBankScan(twoAccessible, {
                [1] = { mvp.bank_slot(1, 1, 1001, 77) },
            }, mvp.dates.day3))
            session:closeBank()
            test.assert_false(session.bankScanner:IsInProgress())
            test.assert_equal(session.current, committed)
        end)
    end),

    test.case("MVP-E2E-07 roster and bank guild ownership changes independently", function()
        local position = fixtures.window_position()
        local model = savedData.newModel()
        model.ui.windowPosition = position
        local session = newSession({ model = model, bankOpen = true })
        local guildA = mvp.guild_a()
        local guildB = mvp.guild_b()

        transition("both datasets start on guild A", function()
            test.assert_true(scanInitialRoster(session, mvp.dates.day1Morning, guildA))
            test.assert_true(session:scanBank(mvp.bank_catalog(guildA, false), {
                [1] = { mvp.bank_slot(1, 1, 1001, 20) },
            }, mvp.dates.day1Morning))
        end)

        transition("bank changes to guild B only", function()
            test.assert_true(session:scanBank(mvp.bank_catalog(guildB, false), {
                [1] = { mvp.bank_slot(1, 1, 4004, 4) },
            }, mvp.dates.day2))
            test.assert_equal(session.current.roster.guild, guildA)
            test.assert_equal(session.current.bank.guild, guildB)
            test.assert_equal(session.current.bank.slots[1].itemId, 4004)
            test.assert_equal(session.current.ui.windowPosition, position)
            test.assert_equal(
                session.messages[#session.messages - 1],
                "Detected guild change; resetting bank data"
            )
        end)

        transition("roster later changes to guild B", function()
            local snapshot = memberSnapshot(mvp.dates.day3, {
                guild = guildB,
                member = {
                    guid = "Player-0000-00000099",
                    name = "Borealis",
                    realm = "Other Realm",
                    displayName = "Borealis-Other Realm",
                    rankName = "Member",
                    rankIndex = 2,
                    isOnline = true,
                },
            })
            test.assert_true(session:scanRoster(snapshot))
            test.assert_equal(session.current.roster.guild, guildB)
            test.assert_equal(session.current.bank.guild, guildB)
            test.assert_equal(session.current.roster.members[1].displayName, "Borealis-Other Realm")
            test.assert_equal(session.current.bank.slots[1].itemId, 4004)
            test.assert_equal(session.current.ui.windowPosition, position)
            test.assert_equal(
                session.messages[#session.messages - 1],
                "Detected guild change; resetting roster data"
            )
        end)
    end),

    test.case("MVP-E2E-08 reset recovery character isolation and window position", function()
        local position = fixtures.window_position({ x = 333, y = -222 })
        local model = savedData.newModel()
        model.ui.windowPosition = position
        local first = newSession({ model = model })
        local second = newSession()
        test.assert_true(scanInitialRoster(first, mvp.dates.day1Morning))

        transition("characters remain isolated", function()
            test.assert_equal(second.current, savedData.newModel())
            test.assert_equal(#first.current.roster.members, 1)
        end)

        transition("manual reset canceled", function()
            local before = first.current
            local request = first.reset:requestManual()
            test.assert_equal(first.confirmations[#first.confirmations], request)
            first.reset:cancel(request)
            test.assert_equal(first.current, before)
            test.assert_equal(
                first.messages[#first.messages],
                "Reset canceled; no data was changed."
            )
        end)

        transition("manual reset accepted", function()
            local request = first.reset:requestManual()
            test.assert_true(first.reset:confirm(request))
            test.assert_equal(first.current, mvp.empty_model(position))
            test.assert_equal(
                first.messages[#first.messages],
                "Roster and bank observations reset; window position preserved."
            )
        end)

        transition("corrupt recovery declined", function()
            local corrupt = {
                schemaVersion = "invalid",
                ui = { windowPosition = position },
                untouched = "original",
            }
            local recovery = newSession({ model = corrupt })
            local request = recovery.reset:requestRecovery(recovery.state)
            recovery.reset:cancel(request)
            test.assert_equal(recovery.current, corrupt)
            test.assert_false(recovery.state.enabled)
            test.assert_matches(recovery.messages[#recovery.messages], "remains disabled")
        end)

        transition("corrupt recovery accepted", function()
            local corrupt = {
                schemaVersion = "invalid",
                ui = { windowPosition = position },
                untouched = "original",
            }
            local recovery = newSession({ model = corrupt })
            local request = recovery.reset:requestRecovery(recovery.state)
            test.assert_true(recovery.reset:confirm(request))
            test.assert_equal(recovery.current, mvp.empty_model(position))
            test.assert_true(recovery.state.enabled)
            test.assert_equal(recovery.state.recoveredFrom, "corrupt")
            test.assert_equal(
                recovery.messages[#recovery.messages],
                "Saved data reset completed; scans and reports are enabled."
            )
        end)
    end),

    test.case("MVP-E2E-09 slash commands and refresh restrictions share live state", function()
        local session = newSession({ inGuild = false })

        transition("window and help commands", function()
            commands.handle("", session.commandApi)
            test.assert_true(session.ui.windowShown)
            test.assert_equal(session.ui.selectedTab, "roster")
            commands.handle("help", session.commandApi)
            test.assert_equal(
                session.messages[#session.messages],
                commands.HELP_LINES[#commands.HELP_LINES]
            )
        end)

        transition("unguilded roster restrictions", function()
            test.assert_false(session:rosterRefreshEnabled())
            commands.handle("scanroster", session.commandApi)
            test.assert_matches(session.messages[#session.messages], "not in a guild")
        end)

        transition("joined duplicate-scan restriction", function()
            session.inGuild = true
            session.rosterSnapshot = memberSnapshot(mvp.dates.day1Morning, {
                member = { isOnline = true },
            })
            commands.handle("scanroster", session.commandApi)
            test.assert_false(session:rosterRefreshEnabled())
            commands.handle("scanroster", session.commandApi)
            test.assert_matches(session.messages[#session.messages], "already in progress")
            test.assert_true(session.rosterScanner:OnDataUpdated())
            test.assert_true(session:rosterRefreshEnabled())
        end)

        transition("bank-open and in-progress restrictions", function()
            test.assert_false(session:bankRefreshEnabled())
            local started, reason = session.bankScanner:Request("manual")
            test.assert_nil(started)
            test.assert_equal(reason, "bank-closed")
            test.assert_matches(session.messages[#session.messages], "window is closed")

            local catalog = mvp.bank_catalog(nil, false)
            test.assert_true(session:startBankScan(catalog, {
                [1] = { mvp.bank_slot(1, 1, 1001, 20) },
            }, mvp.dates.day2))
            test.assert_false(session:bankRefreshEnabled())
            session.bankScanner:Cancel()
            test.assert_true(session:bankRefreshEnabled())
        end)

        transition("reset command opens confirmation", function()
            commands.handle("reset", session.commandApi)
            test.assert_false(session.confirmations[#session.confirmations].recovery)
        end)

        transition("disabled data disables both refresh controls", function()
            local disabled = newSession({ model = { schemaVersion = "invalid" } })
            disabled.inGuild = true
            disabled.bankOpen = true
            test.assert_false(disabled:rosterRefreshEnabled())
            test.assert_false(disabled:bankRefreshEnabled())
        end)
    end),
}
