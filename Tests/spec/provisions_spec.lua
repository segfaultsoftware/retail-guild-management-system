local accountData = require("Core.AccountData")
local dateTime = require("Core.DateTime")
local fixtures = require("Tests.fixtures")
local model = require("Provisions.Model")
local savedData = require("Core.SavedData")
local test = require("Tests.lib.runner")

local function newHarness(initialProvisions)
    local identity = fixtures.guild_identity()
    local account = accountData.newModel()
    account = assert(accountData.replaceProvisions(
        account,
        identity,
        initialProvisions or {},
        #(initialProvisions or {}) + 1
    ))
    local messages = {}
    local editorStates = {}
    local reports = {}
    local toasts = {}
    local dragCancellations = 0
    local locked = false
    local rgms = {
        AccountData = accountData,
        AccountDataState = { enabled = true, model = account },
        ActiveGuildIdentity = identity,
        SavedDataState = { enabled = true, model = savedData.newModel() },
        DB = accountData.view(account, identity, {}),
        DateTime = dateTime,
        Portal = { bankTimestamp = function(value) return "Last scan: " .. value end },
        Bank = {
            IsScanInProgress = function() return false end,
            IsAvailable = function() return true end,
        },
        ProvisionModel = model,
        IsScanLocked = function() return locked end,
        Print = function(message) messages[#messages + 1] = message end,
        UI = {
            SetProvisionsEditor = function(state)
                editorStates[#editorStates + 1] = state
            end,
            SetProvisionsReport = function(report, selectedId)
                reports[#reports + 1] = { report = report, selectedId = selectedId }
            end,
            SetViewStatus = function() end,
            SelectProvisionRow = function() end,
            ShowToast = function(message)
                toasts[#toasts + 1] = message
            end,
            CancelProvisionDrag = function()
                dragCancellations = dragCancellations + 1
            end,
        },
    }
    local chunk = assert(loadfile("Provisions/Provisions.lua"))
    local provisions = chunk("RGMS", rgms)
    rgms.Provisions = provisions
    return {
        rgms = rgms,
        provisions = provisions,
        messages = messages,
        editorStates = editorStates,
        reports = reports,
        toasts = toasts,
        dragCancellations = function() return dragCancellations end,
        setLocked = function(value) locked = value == true end,
    }
end

local function saved(id, name, quality, target)
    return { id = id, name = name, quality = quality, target = target }
end

return {
    test.case("new save update and delete publish atomic account replacements", function()
        local harness = newHarness()
        harness.provisions.SetDraft({
            name = "  Feast  ",
            silver = true,
            gold = true,
            targetText = "20",
        })
        local savedOk, id = harness.provisions.Save()
        test.assert_true(savedOk)
        test.assert_equal(id, 1)
        test.assert_equal(harness.rgms.DB.provisions, {
            saved(1, "Feast", "either", 20),
        })
        test.assert_equal(harness.rgms.DB.nextProvisionId, 2)
        test.assert_nil(harness.provisions.selectedId)
        test.assert_equal(harness.toasts[1], "Successfully added Feast")
        test.assert_equal(harness.provisions.draft, {
            name = "",
            silver = false,
            gold = false,
            targetText = "",
        })

        harness.provisions.New()
        harness.provisions.SetDraft({
            name = "Feast",
            silver = true,
            gold = true,
            targetText = "20",
        })
        test.assert_true(harness.provisions.Save())
        test.assert_equal(#harness.rgms.DB.provisions, 2)
        test.assert_equal(harness.rgms.DB.provisions[2].id, 2)

        harness.provisions.Select(1)
        harness.provisions.SetDraft({
            name = "Updated Feast",
            gold = true,
            targetText = "30",
        })
        test.assert_true(harness.provisions.Save())
        test.assert_equal(harness.rgms.DB.provisions[1], {
            id = 1,
            name = "Updated Feast",
            quality = "gold",
            target = 30,
        })
        test.assert_nil(harness.provisions.selectedId)
        test.assert_equal(harness.toasts[3], "Successfully updated Updated Feast")
        test.assert_true(harness.provisions.Delete(1))
        test.assert_equal(harness.rgms.DB.provisions, {
            saved(2, "Feast", "either", 20),
        })
        test.assert_nil(harness.provisions.selectedId)
        test.assert_equal(harness.toasts[4], "Removed Updated Feast from Provisions")
        test.assert_equal(#harness.messages, 0)
    end),

    test.case("selection reload discards drafts while close clears the session", function()
        local harness = newHarness({ saved(1, "Feast", "silver", 10) })
        test.assert_true(harness.provisions.Select(1))
        harness.provisions.SetDraft({
            name = "Unsaved",
            gold = true,
            targetText = "99",
        })
        test.assert_equal(harness.provisions.draft.name, "Unsaved")
        harness.provisions.OnTabSelected()
        test.assert_equal(harness.provisions.draft, {
            name = "Feast",
            silver = true,
            gold = false,
            targetText = "10",
        })
        harness.provisions.OnWindowClosed()
        test.assert_nil(harness.provisions.selectedId)
        test.assert_equal(harness.provisions.draft.name, "")
    end),

    test.case("guild changes cancel an active provision drag before refreshing", function()
        local harness = newHarness({ saved(1, "Feast", "silver", 10) })

        test.assert_true(harness.provisions.OnGuildChanged())

        test.assert_equal(harness.dragCancellations(), 1)
        test.assert_equal(harness.rgms.DB.provisions[1].id, 1)
    end),

    test.case("row deletion preserves a different selected provision and draft", function()
        local harness = newHarness({
            saved(1, "Feast", "silver", 10),
            saved(2, "Flask", "gold", 20),
        })
        harness.provisions.Select(1)
        harness.provisions.SetDraft({
            name = "Unsaved Feast",
            silver = true,
            targetText = "11",
        })

        test.assert_true(harness.provisions.Delete(2))

        test.assert_equal(harness.rgms.DB.provisions, {
            saved(1, "Feast", "silver", 10),
        })
        test.assert_equal(harness.provisions.selectedId, 1)
        test.assert_equal(harness.provisions.draft.name, "Unsaved Feast")
    end),

    test.case("scan locks reject every provision mutation without losing draft", function()
        local harness = newHarness({ saved(1, "Feast", "silver", 10) })
        harness.provisions.Select(1)
        harness.provisions.SetDraft({
            name = "Unsaved Feast",
            silver = true,
            targetText = "11",
        })
        harness.setLocked(true)
        test.assert_nil(harness.provisions.New())
        test.assert_nil(harness.provisions.Select(1))
        test.assert_nil(harness.provisions.Save())
        test.assert_nil(harness.provisions.Delete())
        test.assert_nil(harness.provisions.Reorder({ 1 }))
        test.assert_equal(harness.provisions.draft.name, "Unsaved Feast")
        test.assert_equal(harness.rgms.DB.provisions[1].name, "Feast")
        test.assert_equal(#harness.toasts, 0)
    end),

    test.case("reorder atomically preserves values next ID selection and draft", function()
        local harness = newHarness({
            saved(1, "Feast", "either", 10),
            saved(2, "Feast", "either", 20),
            saved(3, "Flask", "gold", 30),
        })
        harness.provisions.Select(2)
        harness.provisions.SetDraft({
            name = "Unsaved Feast",
            silver = true,
            gold = true,
            targetText = "21",
        })
        local calls = 0
        local originalReplace = harness.rgms.AccountData.replaceProvisions
        harness.rgms.AccountData.replaceProvisions = function(...)
            calls = calls + 1
            return originalReplace(...)
        end

        test.assert_true(harness.provisions.Reorder({ 3, 2, 1 }))

        test.assert_equal(calls, 1)
        test.assert_equal(harness.rgms.DB.provisions, {
            saved(3, "Flask", "gold", 30),
            saved(2, "Feast", "either", 20),
            saved(1, "Feast", "either", 10),
        })
        test.assert_equal(harness.rgms.DB.nextProvisionId, 4)
        test.assert_equal(harness.provisions.selectedId, 2)
        test.assert_equal(harness.provisions.draft.name, "Unsaved Feast")
        test.assert_equal(#harness.toasts, 0)
    end),

    test.case("reorder persistence failure leaves saved state selection and draft unchanged", function()
        local harness = newHarness({
            saved(1, "Feast", "silver", 10),
            saved(2, "Flask", "gold", 20),
        })
        harness.provisions.Select(1)
        harness.provisions.SetDraft({
            name = "Unsaved Feast",
            silver = true,
            targetText = "11",
        })
        local originalAccount = harness.rgms.AccountDataState.model
        local originalReplace = harness.rgms.AccountData.replaceProvisions
        harness.rgms.AccountData.replaceProvisions = function()
            return nil, "simulated storage failure"
        end

        local result, message = harness.provisions.Reorder({ 2, 1 })

        test.assert_nil(result)
        test.assert_equal(message, "simulated storage failure")
        test.assert_true(harness.rgms.AccountDataState.model == originalAccount)
        test.assert_equal(harness.rgms.DB.provisions[1].id, 1)
        test.assert_equal(harness.provisions.selectedId, 1)
        test.assert_equal(harness.provisions.draft.name, "Unsaved Feast")
        test.assert_matches(harness.messages[1], "Could not reorder provision")
        test.assert_equal(#harness.toasts, 0)
        harness.rgms.AccountData.replaceProvisions = originalReplace
    end),

    test.case("persistence failures retain selection draft and saved data", function()
        local harness = newHarness({ saved(1, "Feast", "silver", 10) })
        harness.provisions.Select(1)
        harness.provisions.SetDraft({
            name = "Unsaved Feast",
            gold = true,
            targetText = "25",
        })
        local originalAccount = harness.rgms.AccountDataState.model
        local originalReplace = harness.rgms.AccountData.replaceProvisions
        harness.rgms.AccountData.replaceProvisions = function()
            return nil, "simulated storage failure"
        end

        local result, message = harness.provisions.Save()
        test.assert_nil(result)
        test.assert_equal(message, "simulated storage failure")
        test.assert_true(harness.rgms.AccountDataState.model == originalAccount)
        test.assert_equal(harness.rgms.DB.provisions[1].name, "Feast")
        test.assert_equal(harness.provisions.selectedId, 1)
        test.assert_equal(harness.provisions.draft.name, "Unsaved Feast")
        test.assert_matches(harness.messages[1], "Could not save provision")
        test.assert_equal(#harness.toasts, 0)

        result, message = harness.provisions.Delete()
        test.assert_nil(result)
        test.assert_equal(message, "simulated storage failure")
        test.assert_matches(harness.messages[2], "Could not delete provision")
        test.assert_equal(#harness.toasts, 0)

        harness.rgms.AccountData.replaceProvisions = originalReplace
    end),

    test.case("selected deletion reports the removed saved name only after persistence", function()
        local harness = newHarness({ saved(1, "Feast Platter", "silver", 10) })
        test.assert_true(harness.provisions.Select(1))
        harness.provisions.SetDraft({
            name = "Unsaved rename",
            silver = true,
            targetText = "10",
        })

        test.assert_true(harness.provisions.Delete())
        test.assert_equal(harness.toasts, {
            "Removed Feast Platter from Provisions",
        })
        test.assert_equal(#harness.messages, 0)
    end),

    test.case("validation rejection produces no success toast", function()
        local harness = newHarness()
        harness.provisions.SetDraft({
            name = "x",
            silver = true,
            targetText = "10",
        })

        local result, message = harness.provisions.Save()
        test.assert_nil(result)
        test.assert_equal(message, "item name must contain 3 through 100 characters")
        test.assert_equal(#harness.toasts, 0)
        test.assert_equal(#harness.messages, 0)
    end),
}
