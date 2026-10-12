-- User-confirmed observation reset and unusable-data recovery. The controller
-- accepts its dependencies so every state transition can be tested outside
-- the WoW client.

local _, RGMS = ...

local Reset = {}

local function disabledReason(state)
    if type(state) ~= "table" then
        return "saved data is unavailable"
    end

    local reason = "saved data is " .. tostring(state.status or "unavailable")
    if type(state.error) == "string" and state.error ~= "" then
        reason = reason .. ": " .. state.error
    end
    return reason
end

function Reset.create(dependencies)
    local controller = {}

    function controller:requestManual()
        local request = {
            recovery = false,
        }
        dependencies.showConfirmation(request)
        return request
    end

    function controller:requestRecovery(state)
        local request = {
            recovery = true,
            state = state,
        }
        dependencies.showConfirmation(request)
        return request
    end

    function controller:confirm(request)
        request = request or { recovery = false }

        local model, resetError = dependencies.savedData.resetObservations(
            dependencies.getSavedData()
        )
        if not model then
            dependencies.print("Reset failed: " .. tostring(resetError) .. ".")
            return nil, resetError
        end

        local state = {
            enabled = true,
            status = "ready",
            model = model,
        }
        if request.recovery and type(request.state) == "table" then
            state.recoveredFrom = request.state.status
        end

        dependencies.commit(model, state)
        if type(dependencies.setDataState) == "function" then
            dependencies.setDataState(true)
        end
        if type(dependencies.refreshViews) == "function" then
            dependencies.refreshViews()
        end
        if request.recovery then
            dependencies.print(
                "Saved data reset completed; scans and reports are enabled."
            )
        else
            dependencies.print(
                "Roster and bank observations reset; window position preserved."
            )
        end

        return true
    end

    function controller:cancel(request)
        if request and request.recovery then
            dependencies.print(
                "Reset canceled. RGMS remains disabled because "
                    .. disabledReason(request.state)
                    .. ". Use /rgms reset and accept the confirmation to recover."
            )
        else
            dependencies.print("Reset canceled; no data was changed.")
        end
    end

    function controller:canUse(action)
        local state = dependencies.getState()
        if type(state) == "table" and state.enabled then
            return true
        end

        dependencies.print(
            "Cannot "
                .. tostring(action or "use RGMS data")
                .. " because "
                .. disabledReason(state)
                .. ". Scans and reports are disabled until /rgms reset is accepted."
        )
        return false
    end

    function controller:canScan(datasetName)
        return self:canUse("scan " .. tostring(datasetName or "guild data"))
    end

    function controller:canReport(reportName)
        return self:canUse("show " .. tostring(reportName or "an RGMS report"))
    end

    return controller
end

local DIALOG_KEY = "RGMS_CONFIRM_OBSERVATION_RESET"

if type(RGMS) == "table" then
    local controller

    StaticPopupDialogs[DIALOG_KEY] = {
        text = "%s",
        button1 = ACCEPT,
        button2 = CANCEL,
        OnAccept = function(_, request)
            controller:confirm(request)
        end,
        OnCancel = function(_, request)
            controller:cancel(request)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local function showConfirmation(request)
        local message
        if request.recovery then
            message = "RGMS cannot use this character's saved data because it is "
                .. tostring(request.state and request.state.status or "unavailable")
                .. ". Reset all roster and bank observations for this character? "
                .. "The original data will be replaced." 
        else
            message = "Reset all RGMS roster and bank observations for this character? "
                .. "This cannot be undone."
        end

        local popup = StaticPopup_Show(DIALOG_KEY, message, nil, request)
        if not popup then
            RGMS.Print(
                "Could not open the reset confirmation. No data was changed; try /rgms reset again."
            )
        end
    end

    controller = Reset.create({
        savedData = RGMS.SavedData,
        getSavedData = function()
            return RGMSCharacterDB
        end,
        getState = function()
            return RGMS.SavedDataState
        end,
        commit = function(model, state)
            RGMSCharacterDB = model
            RGMS.DB = model
            RGMS.SavedDataState = state
        end,
        showConfirmation = showConfirmation,
        print = RGMS.Print,
        setDataState = function(enabled)
            if type(RGMS.UI) == "table"
                and type(RGMS.UI.SetDataState) == "function" then
                RGMS.UI.SetDataState(enabled)
            end
        end,
        refreshViews = function()
            if type(RGMS.Roster) == "table"
                and type(RGMS.Roster.RefreshStatus) == "function" then
                RGMS.Roster.RefreshStatus()
            end
            if type(RGMS.Bank) == "table"
                and type(RGMS.Bank.RefreshStatus) == "function" then
                RGMS.Bank.RefreshStatus()
            end
        end,
    })

    RGMS.Reset = controller
end

return Reset
