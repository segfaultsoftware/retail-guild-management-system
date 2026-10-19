local datasetOwnership = require("Core.DatasetOwnership")
local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local savedData = require("Core.SavedData")
local scannerModule = require("Bank.Scanner")
local bankState = require("Bank.State")
local test = require("Tests.lib.runner")

local function tab(index, isViewable, name)
    return fixtures.bank_tab({
        index = index,
        name = name or ("Tab " .. index),
        isViewable = isViewable,
    })
end

local function slot(tabIndex, slotIndex, quantity)
    local value = fixtures.bank_slot({
        tabIndex = tabIndex,
        slotIndex = slotIndex,
        quantity = quantity or 1,
    })
    value.observedAt = nil
    return value
end

local function newHarness(options)
    options = options or {}
    local original = options.model or fixtures.saved_model()
    local current = original
    local messages = {}
    local debugMessages = {}
    local progress = {}
    local requests = {}
    local refreshes = 0
    local commits = 0
    local captures = {}
    local lifecycle = {}

    local ownership = datasetOwnership.create({
        savedData = savedData,
        getSavedData = function()
            return current
        end,
        commit = function(model)
            current = model
            commits = commits + 1
        end,
        print = function(message)
            messages[#messages + 1] = message
        end,
    })

    local catalog = options.catalog or {
        guild = fixtures.guild_identity(),
        tabs = { tab(1, true) },
    }
    local api = {
        isOpen = function()
            return options.bankOpen ~= false
        end,
        captureCatalog = function()
            lifecycle[#lifecycle + 1] = "catalog"
            if options.catalogError then
                error(options.catalogError)
            end
            return catalog
        end,
        requestTab = function(_, tabIndex)
            lifecycle[#lifecycle + 1] = "request"
            requests[#requests + 1] = tabIndex
            if options.requestErrorTab == tabIndex then
                error("simulated request failure")
            end
        end,
        captureTab = function(_, tabIndex)
            captures[tabIndex] = (captures[tabIndex] or 0) + 1
            if options.captureErrorTab == tabIndex then
                error("simulated capture failure")
            end
            if options.partialTab == tabIndex then
                return nil, "incomplete", "slot data is partial"
            end
            if type(options.captureTab) == "function" then
                return options.captureTab(tabIndex, captures[tabIndex])
            end
            return (options.slotsByTab or {})[tabIndex] or {}
        end,
        captureTimestamp = function()
            return options.timestamp or fixtures.timestamp({
                unixSeconds = 1717245356,
                iso8601 = "2024-06-01T12:35:56Z",
            })
        end,
    }

    local scanner = scannerModule.create({
        api = api,
        ownership = ownership,
        reduceBank = function(previousDataset, snapshot)
            return bankState.reduce(previousDataset, snapshot, dateTime)
        end,
        timeoutSeconds = options.timeoutSeconds or 10,
        canScan = function()
            return options.canScan ~= false
        end,
        prepareScan = function(guildIdentity)
            lifecycle[#lifecycle + 1] = "prepare"
            test.assert_equal(guildIdentity, catalog.guild)
            if options.prepareError then
                return nil, options.prepareError
            end
            return true
        end,
        print = function(message)
            messages[#messages + 1] = message
        end,
        debug = function(message)
            debugMessages[#debugMessages + 1] = message
        end,
        setInProgress = function(inProgress)
            progress[#progress + 1] = inProgress
        end,
        refreshStatus = function()
            refreshes = refreshes + 1
        end,
        beginScan = options.beginScan,
        isScanLocked = options.isScanLocked,
        endScan = options.endScan,
        rejectConcurrentScan = options.rejectConcurrentScan,
    })

    return {
        scanner = scanner,
        original = original,
        current = function()
            return current
        end,
        messages = messages,
        debugMessages = debugMessages,
        progress = progress,
        requests = requests,
        commits = function()
            return commits
        end,
        refreshes = function()
            return refreshes
        end,
        captures = captures,
        lifecycle = lifecycle,
    }
end

local function completeEmptyTab(harness)
    for _ = 1, 3 do
        local completed, state = harness.scanner:OnSlotsChanged()
        test.assert_false(completed)
        test.assert_equal(state, "empty-retry")
        test.assert_true(harness.scanner:Update(1))
    end
    return harness.scanner:OnSlotsChanged()
end

return {
    test.case("bank preparation runs only after the open bank identifies its guild", function()
        local closed = newHarness({ bankOpen = false })
        local started, reason = closed.scanner:Request("manual")
        test.assert_nil(started)
        test.assert_equal(reason, "bank-closed")
        test.assert_equal(closed.lifecycle, {})

        local open = newHarness()
        test.assert_true(open.scanner:Request("manual"))
        test.assert_equal(open.lifecycle, { "catalog", "prepare", "request" })
    end),

    test.case("bank preparation failures stop before slot collection", function()
        local harness = newHarness({ prepareError = "cannot migrate bank" })
        local started, reason = harness.scanner:Request("automatic")

        test.assert_nil(started)
        test.assert_equal(reason, "migration-failure")
        test.assert_equal(harness.lifecycle, { "catalog", "prepare" })
        test.assert_equal(harness.requests, {})
        test.assert_equal(harness.commits(), 0)
    end),

    test.case("full success commits only after every accessible tab is complete", function()
        local harness = newHarness({
            catalog = {
                guild = fixtures.guild_identity(),
                tabs = { tab(1, true), tab(2, true) },
            },
            slotsByTab = {
                [1] = { slot(1, 4, 8) },
                [2] = { slot(2, 9, 3) },
            },
        })

        test.assert_true(harness.scanner:Request("automatic"))
        test.assert_equal(harness.requests, { 1 })
        test.assert_equal(harness.current(), harness.original)

        test.assert_true(harness.scanner:OnSlotsChanged())
        test.assert_equal(harness.requests, { 1, 2 })
        test.assert_equal(harness.current(), harness.original)

        test.assert_true(harness.scanner:OnSlotsChanged())
        test.assert_equal(harness.commits(), 1)
        test.assert_equal(#harness.current().bank.tabs, 2)
        test.assert_equal(#harness.current().bank.slots, 2)
        test.assert_equal(harness.current().bank.slots[1].tabIndex, 1)
        test.assert_equal(harness.current().bank.slots[2].tabIndex, 2)
        test.assert_equal(
            harness.current().bank.slots[1].observedAt,
            harness.current().bank.scannedAt
        )
        test.assert_equal(harness.progress, { true, false })
        test.assert_matches(harness.messages[1], "scan complete")
    end),

    test.case("mixed access records every tab and queries accessible tabs in order", function()
        local harness = newHarness({
            catalog = {
                guild = fixtures.guild_identity(),
                tabs = {
                    tab(1, true),
                    tab(2, false),
                    tab(3, true),
                    tab(4, false),
                },
            },
            slotsByTab = {
                [1] = { slot(1, 1) },
                [3] = { slot(3, 7) },
            },
        })

        test.assert_true(harness.scanner:Request("manual"))
        test.assert_true(harness.scanner:OnSlotsChanged())
        test.assert_true(harness.scanner:OnSlotsChanged())

        test.assert_equal(harness.requests, { 1, 3 })
        test.assert_equal(#harness.current().bank.tabs, 4)
        test.assert_false(harness.current().bank.tabs[2].isViewable)
        test.assert_false(harness.current().bank.tabs[4].isViewable)
        test.assert_equal(#harness.current().bank.slots, 2)
    end),

    test.case("all inaccessible tabs are a successful transaction", function()
        local harness = newHarness({
            catalog = {
                guild = fixtures.guild_identity(),
                tabs = { tab(1, false), tab(2, false) },
            },
        })

        test.assert_true(harness.scanner:Request("automatic"))

        test.assert_equal(harness.requests, {})
        test.assert_equal(harness.commits(), 1)
        test.assert_equal(#harness.current().bank.tabs, 2)
        test.assert_equal(#harness.current().bank.slots, 1)
        test.assert_equal(
            harness.current().bank.slots[1],
            harness.original.bank.slots[1]
        )
        test.assert_matches(harness.messages[1], "0 accessible")
        test.assert_false(harness.scanner:IsInProgress())
    end),

    test.case("empty tab reads retry after one second and accept later data", function()
        local expectedSlot = slot(1, 4, 8)
        local harness = newHarness({
            captureTab = function(_, attempt)
                if attempt < 3 then
                    return {}
                end
                return { expectedSlot }
            end,
        })

        test.assert_true(harness.scanner:Request("manual"))
        local completed, state = harness.scanner:OnSlotsChanged()
        test.assert_false(completed)
        test.assert_equal(state, "empty-retry")
        test.assert_equal(harness.requests, { 1 })

        test.assert_false(harness.scanner:Update(0.5))
        test.assert_equal(harness.requests, { 1 })
        completed, state = harness.scanner:OnSlotsChanged()
        test.assert_false(completed)
        test.assert_equal(state, "empty-retry")
        test.assert_equal(harness.captures[1], 1)

        test.assert_true(harness.scanner:Update(0.5))
        test.assert_equal(harness.requests, { 1, 1 })
        completed, state = harness.scanner:OnSlotsChanged()
        test.assert_false(completed)
        test.assert_equal(state, "empty-retry")

        test.assert_true(harness.scanner:Update(1))
        test.assert_equal(harness.requests, { 1, 1, 1 })
        test.assert_true(harness.scanner:OnSlotsChanged())

        test.assert_equal(harness.captures[1], 3)
        test.assert_equal(harness.commits(), 1)
        test.assert_equal(#harness.current().bank.slots, 1)
        test.assert_equal(harness.current().bank.slots[1].slotIndex, 4)
        local debugText = table.concat(harness.debugMessages, "\n")
        test.assert_matches(
            debugText,
            "attempt 1/4 returned 0 occupied slots; retrying"
        )
        test.assert_matches(
            debugText,
            "attempt 3/4 returned 1 occupied slot; accepting the retry result"
        )
        test.assert_matches(
            debugText,
            "final counts: tab 1=1"
        )
    end),

    test.case("four empty reads are accepted as a successful empty tab", function()
        local harness = newHarness()

        test.assert_true(harness.scanner:Request("manual"))
        for attempt = 1, 3 do
            local completed, state = harness.scanner:OnSlotsChanged()
            test.assert_false(completed)
            test.assert_equal(state, "empty-retry")
            test.assert_true(harness.scanner:Update(1))
            test.assert_equal(#harness.requests, attempt + 1)
        end
        test.assert_true(harness.scanner:OnSlotsChanged())

        test.assert_equal(harness.captures[1], 4)
        test.assert_equal(harness.requests, { 1, 1, 1, 1 })
        test.assert_equal(harness.commits(), 1)
        test.assert_equal(#harness.current().bank.slots, 0)
        test.assert_matches(
            harness.debugMessages[#harness.debugMessages - 1],
            "attempt 4/4 returned 0 occupied slots; accepting the tab as empty"
        )
        test.assert_matches(
            harness.debugMessages[#harness.debugMessages],
            "final counts: tab 1=0"
        )
    end),

    test.case("intentional retry waits do not consume the scan timeout", function()
        local harness = newHarness({ timeoutSeconds = 1 })

        test.assert_true(harness.scanner:Request("manual"))
        test.assert_false(harness.scanner:OnSlotsChanged())
        test.assert_true(harness.scanner:Update(1))
        test.assert_true(harness.scanner:IsInProgress())

        local completed, reason = harness.scanner:Update(1)
        test.assert_nil(completed)
        test.assert_equal(reason, "timeout")
        test.assert_false(harness.scanner:IsInProgress())
    end),

    test.case("empty retry attempts reset for each accessible tab", function()
        local harness = newHarness({
            catalog = {
                guild = fixtures.guild_identity(),
                tabs = { tab(1, true), tab(2, true) },
            },
        })

        test.assert_true(harness.scanner:Request("manual"))
        for _ = 1, 3 do
            test.assert_false(harness.scanner:OnSlotsChanged())
            test.assert_true(harness.scanner:Update(1))
        end
        test.assert_true(harness.scanner:OnSlotsChanged())
        test.assert_equal(harness.requests, { 1, 1, 1, 1, 2 })

        local completed, state = harness.scanner:OnSlotsChanged()
        test.assert_false(completed)
        test.assert_equal(state, "empty-retry")
        test.assert_equal(harness.captures[2], 1)
        test.assert_equal(harness.commits(), 0)
    end),

    test.case("timeout discards all partial tab results and preserves prior state", function()
        local harness = newHarness({
            catalog = {
                guild = fixtures.guild_identity(),
                tabs = { tab(1, true), tab(2, true) },
            },
            slotsByTab = {
                [1] = { slot(1, 1, 50) },
            },
            timeoutSeconds = 2,
        })

        test.assert_true(harness.scanner:Request("manual"))
        test.assert_true(harness.scanner:OnSlotsChanged())
        local completed, reason = harness.scanner:Update(2)

        test.assert_nil(completed)
        test.assert_equal(reason, "timeout")
        test.assert_equal(harness.current(), harness.original)
        test.assert_equal(harness.commits(), 0)
        test.assert_matches(harness.messages[1], "timed out")
    end),

    test.case("partial reads wait for completion and cannot leak into saved state", function()
        local harness = newHarness({ partialTab = 1, timeoutSeconds = 1 })

        test.assert_true(harness.scanner:Request("manual"))
        local completed, state = harness.scanner:OnSlotsChanged()

        test.assert_false(completed)
        test.assert_equal(state, "incomplete")
        test.assert_equal(harness.current(), harness.original)
        test.assert_true(harness.scanner:IsInProgress())

        harness.scanner:Update(1)
        test.assert_equal(harness.current(), harness.original)
        test.assert_equal(harness.commits(), 0)
    end),

    test.case("API failures discard the transaction and report an error", function()
        local harness = newHarness({ captureErrorTab = 1 })
        test.assert_true(harness.scanner:Request("manual"))

        local completed, reason = harness.scanner:OnSlotsChanged()

        test.assert_nil(completed)
        test.assert_equal(reason, "api-failure")
        test.assert_equal(harness.current(), harness.original)
        test.assert_equal(harness.commits(), 0)
        test.assert_matches(harness.messages[1], "simulated capture failure")
    end),

    test.case("cancellation is silent and preserves the prior report", function()
        local harness = newHarness({
            catalog = {
                guild = fixtures.guild_identity(),
                tabs = { tab(1, true), tab(2, true) },
            },
            slotsByTab = {
                [1] = { slot(1, 1, 99) },
            },
        })
        test.assert_true(harness.scanner:Request("manual"))
        test.assert_true(harness.scanner:OnSlotsChanged())

        test.assert_true(harness.scanner:Cancel())

        test.assert_equal(harness.current(), harness.original)
        test.assert_equal(harness.commits(), 0)
        test.assert_equal(harness.messages, {})
        test.assert_equal(harness.progress, { true, false })
    end),

    test.case("successes on one Pacific date retain the latest observation", function()
        local first = newHarness({
            timestamp = fixtures.timestamp({
                unixSeconds = 1717245300,
                iso8601 = "2024-06-01T12:35:00Z",
            }),
        })
        test.assert_true(first.scanner:Request("manual"))
        test.assert_true(completeEmptyTab(first))

        local second = newHarness({
            model = first.current(),
            timestamp = fixtures.timestamp({
                unixSeconds = 1717248900,
                iso8601 = "2024-06-01T13:35:00Z",
            }),
        })
        test.assert_true(second.scanner:Request("manual"))
        test.assert_true(completeEmptyTab(second))

        test.assert_equal(second.current().bank.scannedAt.unixSeconds, 1717248900)
    end),

    test.case("a different guild transaction replaces prior bank state", function()
        local original = fixtures.saved_model()
        local otherGuild = fixtures.guild_identity({
            id = "99999",
            name = "Other Guild",
        })
        local harness = newHarness({
            model = original,
            catalog = {
                guild = otherGuild,
                tabs = { tab(1, true) },
            },
            slotsByTab = {
                [1] = { slot(1, 1, 7) },
            },
            timestamp = fixtures.timestamp({
                unixSeconds = 1717331756,
                iso8601 = "2024-06-02T12:35:56Z",
            }),
        })

        test.assert_true(harness.scanner:Request("manual"))
        test.assert_true(harness.scanner:OnSlotsChanged())

        test.assert_equal(harness.current().bank.guild, otherGuild)
        test.assert_equal(#harness.current().bank.slots, 1)
        test.assert_equal(
            harness.current().bank.slots[1].stableSinceDate,
            "2024-06-02"
        )
        test.assert_equal(harness.current().roster, original.roster)
        test.assert_equal(harness.messages[1], "Detected guild change; resetting bank data")
        test.assert_matches(harness.messages[2], "scan complete")
    end),
}
