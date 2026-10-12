local datasetOwnership = require("Core.DatasetOwnership")
local fixtures = require("Tests.fixtures")
local savedData = require("Core.SavedData")
local scannerModule = require("Roster.Scanner")
local test = require("Tests.lib.runner")

local function successfulSnapshot(memberName)
    local guild = fixtures.guild_identity()
    local scannedAt = fixtures.timestamp({
        unixSeconds = 1717245356,
        iso8601 = "2024-06-01T12:35:56Z",
    })
    return {
        guild = guild,
        scannedAt = scannedAt,
        ranks = {
            fixtures.roster_rank({ index = 1, name = "Officer" }),
            fixtures.roster_rank({ index = 2, name = "Member" }),
            fixtures.roster_rank({ index = 3, name = "Empty Rank" }),
        },
        members = {
            fixtures.roster_member({
                name = memberName or "Newmember",
                displayName = (memberName or "Newmember") .. "-Example Realm",
                rankName = "Member",
                rankIndex = 2,
                observedAt = scannedAt,
            }),
        },
    }
end

local function newHarness(options)
    options = options or {}
    local original = options.model or fixtures.saved_model()
    local current = original
    local messages = {}
    local progress = {}
    local requests = 0
    local refreshes = 0
    local windowOpen = true

    local ownership = datasetOwnership.create({
        savedData = savedData,
        getSavedData = function()
            return current
        end,
        commit = function(model)
            current = model
        end,
        print = function(message)
            messages[#messages + 1] = message
        end,
    })

    local api = {
        isInGuild = function()
            return options.inGuild ~= false
        end,
        requestRoster = function()
            requests = requests + 1
            if options.requestError then
                error(options.requestError)
            end
        end,
        captureSnapshot = function()
            if options.captureError then
                error(options.captureError)
            end
            if options.partial then
                return nil, "incomplete", "member list is partial"
            end
            return successfulSnapshot(options.memberName)
        end,
    }

    local scanner = scannerModule.create({
        api = api,
        ownership = ownership,
        timeoutSeconds = options.timeoutSeconds or 10,
        canScan = function()
            return options.canScan ~= false
        end,
        print = function(message)
            messages[#messages + 1] = message
        end,
        setInProgress = function(inProgress)
            progress[#progress + 1] = inProgress
        end,
        refreshStatus = function()
            refreshes = refreshes + 1
        end,
    })

    return {
        scanner = scanner,
        original = original,
        current = function()
            return current
        end,
        messages = messages,
        progress = progress,
        requests = function()
            return requests
        end,
        refreshes = function()
            return refreshes
        end,
        closeWindow = function()
            windowOpen = false
        end,
        windowIsOpen = function()
            return windowOpen
        end,
    }
end

return {
    test.case("successful scan atomically replaces the current roster snapshot", function()
        local harness = newHarness({ memberName = "Latest" })

        test.assert_true(harness.scanner:Request("automatic"))
        test.assert_equal(harness.current(), harness.original)
        test.assert_true(harness.scanner:OnDataUpdated())

        test.assert_equal(harness.current().roster.members[1].displayName, "Latest-Example Realm")
        test.assert_equal(#harness.current().roster.ranks, 3)
        test.assert_equal(harness.current().roster.ranks[3].name, "Empty Rank")
        test.assert_equal(harness.current().roster.scannedAt.unixSeconds, 1717245356)
        test.assert_equal(harness.progress, { true, false })
        test.assert_matches(harness.messages[1], "scan complete")
    end),

    test.case("unguilded automatic scan is silent and manual scan reports an error", function()
        local harness = newHarness({ inGuild = false })

        local started, reason = harness.scanner:Request("automatic")
        test.assert_nil(started)
        test.assert_equal(reason, "not-in-guild")
        test.assert_equal(harness.messages, {})

        started, reason = harness.scanner:Request("manual")
        test.assert_nil(started)
        test.assert_equal(reason, "not-in-guild")
        test.assert_matches(harness.messages[1], "not in a guild")
        test.assert_equal(harness.requests(), 0)
        test.assert_equal(harness.current(), harness.original)
    end),

    test.case("timeout preserves the last successful roster and reports failure", function()
        local harness = newHarness({ timeoutSeconds = 10 })
        test.assert_true(harness.scanner:Request("manual"))

        test.assert_false(harness.scanner:Update(9.5))
        local finished, reason = harness.scanner:Update(0.5)

        test.assert_nil(finished)
        test.assert_equal(reason, "timeout")
        test.assert_equal(harness.current(), harness.original)
        test.assert_matches(harness.messages[1], "timed out")
        test.assert_false(harness.scanner:IsInProgress())
    end),

    test.case("partial roster data waits and is discarded on timeout", function()
        local harness = newHarness({ partial = true, timeoutSeconds = 2 })
        test.assert_true(harness.scanner:Request("manual"))

        local completed, state = harness.scanner:OnDataUpdated()
        test.assert_false(completed)
        test.assert_equal(state, "incomplete")
        test.assert_equal(harness.current(), harness.original)
        test.assert_true(harness.scanner:IsInProgress())

        harness.scanner:Update(2)
        test.assert_equal(harness.current(), harness.original)
        test.assert_matches(harness.messages[1], "timed out")
    end),

    test.case("duplicate requests are rejected by the shared scanner", function()
        local harness = newHarness()
        test.assert_true(harness.scanner:Request("manual"))

        local started, reason = harness.scanner:Request("manual")

        test.assert_nil(started)
        test.assert_equal(reason, "scan-in-progress")
        test.assert_equal(harness.requests(), 1)
        test.assert_matches(harness.messages[1], "already in progress")
    end),

    test.case("closing the window does not cancel an in-progress scan", function()
        local harness = newHarness({ memberName = "Background" })
        test.assert_true(harness.scanner:Request("manual"))
        harness.closeWindow()

        test.assert_false(harness.windowIsOpen())
        test.assert_true(harness.scanner:IsInProgress())
        test.assert_true(harness.scanner:OnDataUpdated())
        test.assert_equal(
            harness.current().roster.members[1].displayName,
            "Background-Example Realm"
        )
    end),

    test.case("API failures preserve prior data and finish without retrying", function()
        local harness = newHarness({ captureError = "simulated client failure" })
        test.assert_true(harness.scanner:Request("automatic"))

        local completed, reason = harness.scanner:OnDataUpdated()

        test.assert_nil(completed)
        test.assert_equal(reason, "api-failure")
        test.assert_equal(harness.current(), harness.original)
        test.assert_equal(harness.requests(), 1)
        test.assert_matches(harness.messages[1], "simulated client failure")
    end),
}
