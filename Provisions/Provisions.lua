local _, RGMS = ...

local Provisions = RGMS.Provisions or {}
local Model = type(RGMS.ProvisionModel) == "table"
    and RGMS.ProvisionModel
    or require("Provisions.Model")
local AuctionatorIntegration = type(RGMS.AuctionatorIntegration) == "table"
    and RGMS.AuctionatorIntegration
    or require("Provisions.Auctionator")

Provisions.selectedId = nil
Provisions.draft = Model.toDraft(nil)
Provisions.activeGuildKey = nil

local function currentGuildKey()
    if type(RGMS.ActiveGuildIdentity) ~= "table"
        or type(RGMS.AccountData) ~= "table" then
        return nil
    end
    return RGMS.AccountData.guildKey(RGMS.ActiveGuildIdentity)
end

local function clearSession()
    Provisions.selectedId = nil
    Provisions.draft = Model.toDraft(nil)
end

local function ensureGuildSession()
    local key = currentGuildKey()
    if key ~= Provisions.activeGuildKey then
        Provisions.activeGuildKey = key
        clearSession()
    end
end

local function currentList()
    return type(RGMS.DB) == "table" and RGMS.DB.provisions or {}
end

local function editorState()
    local normalized, validationError = Model.normalizeDraft(Provisions.draft)
    local selected = Model.find(currentList(), Provisions.selectedId)
    return {
        selectedId = selected and selected.id or nil,
        draft = Provisions.draft,
        valid = normalized ~= nil,
        changed = normalized ~= nil and (selected == nil or not Model.same(normalized, selected)),
        validationError = validationError,
    }
end

local function renderEditor()
    if type(RGMS.UI) == "table"
        and type(RGMS.UI.SetProvisionsEditor) == "function" then
        RGMS.UI.SetProvisionsEditor(editorState())
    end
end

function Provisions.RefreshStatus()
    ensureGuildSession()
    if Provisions.selectedId ~= nil
        and Model.find(currentList(), Provisions.selectedId) == nil then
        clearSession()
    end
    if type(RGMS.UI) ~= "table" then
        return true
    end
    local bank = type(RGMS.DB) == "table" and RGMS.DB.bank or {}
    local report = Model.buildReport(currentList(), bank)
    if type(RGMS.UI.SetProvisionsReport) == "function" then
        RGMS.UI.SetProvisionsReport(report, Provisions.selectedId)
    end
    local status = "No bank scan yet"
    if type(bank.scannedAt) == "table"
        and type(RGMS.DateTime) == "table"
        and type(RGMS.DateTime.formatPacificTimestamp) == "function" then
        local formatted = RGMS.DateTime.formatPacificTimestamp(bank.scannedAt.unixSeconds)
        if formatted then
            status = type(RGMS.Portal) == "table"
                and RGMS.Portal.bankTimestamp(formatted)
                or ("Last scan: " .. formatted)
        end
    end
    if type(RGMS.Bank) == "table"
        and type(RGMS.Bank.IsScanInProgress) == "function"
        and RGMS.Bank.IsScanInProgress() then
        status = "Scanning... " .. status
    elseif type(RGMS.Bank) == "table"
        and type(RGMS.Bank.IsAvailable) == "function"
        and not RGMS.Bank.IsAvailable() then
        status = "Guild bank closed. " .. status
    end
    if type(RGMS.UI.SetViewStatus) == "function" then
        RGMS.UI.SetViewStatus("provisions", status)
    end
    renderEditor()
    return true
end

function Provisions.New()
    if type(RGMS.IsScanLocked) == "function" and RGMS.IsScanLocked() then
        return nil, "scan-locked"
    end
    clearSession()
    renderEditor()
    if type(RGMS.UI) == "table" and type(RGMS.UI.SelectProvisionRow) == "function" then
        RGMS.UI.SelectProvisionRow(nil)
    end
    return true
end

function Provisions.Select(id)
    if type(RGMS.IsScanLocked) == "function" and RGMS.IsScanLocked() then
        return nil, "scan-locked"
    end
    ensureGuildSession()
    local provision = Model.find(currentList(), id)
    if not provision then
        return nil, "provision was not found"
    end
    Provisions.selectedId = id
    Provisions.draft = Model.toDraft(provision)
    renderEditor()
    if type(RGMS.UI) == "table" and type(RGMS.UI.SelectProvisionRow) == "function" then
        RGMS.UI.SelectProvisionRow(id)
    end
    return true
end

function Provisions.SetDraft(draft)
    ensureGuildSession()
    Provisions.draft = {
        name = type(draft) == "table" and tostring(draft.name or "") or "",
        silver = type(draft) == "table" and draft.silver == true,
        gold = type(draft) == "table" and draft.gold == true,
        targetText = type(draft) == "table" and tostring(draft.targetText or "") or "",
    }
    renderEditor()
    return editorState()
end

local function persist(items, nextId)
    if type(RGMS.AccountDataState) ~= "table"
        or RGMS.AccountDataState.enabled ~= true
        or type(RGMS.ActiveGuildIdentity) ~= "table" then
        return nil, "saved data is unavailable"
    end
    local replacement, guildOrError = RGMS.AccountData.replaceProvisions(
        RGMS.AccountDataState.model,
        RGMS.ActiveGuildIdentity,
        items,
        nextId
    )
    if not replacement then
        return nil, guildOrError
    end
    RGMSAccountDB = replacement
    RGMS.AccountDataState.model = replacement
    RGMS.DB = RGMS.AccountData.view(
        replacement,
        RGMS.ActiveGuildIdentity,
        RGMS.SavedDataState.model.ui
    )
    return true
end

local function reportFailure(action, message)
    if type(RGMS.Print) == "function" then
        RGMS.Print("Could not " .. action .. " provision: " .. tostring(message) .. ".")
    end
    return nil, message
end

local function showSuccess(message)
    if type(RGMS.UI) == "table" and type(RGMS.UI.ShowToast) == "function" then
        RGMS.UI.ShowToast(message)
    end
end

local function reportAuctionatorFailure(message)
    if type(RGMS.Print) == "function" then
        RGMS.Print(
            "Could not create Auctionator shopping list: "
                .. tostring(message)
                .. "."
        )
    end
    return nil, message
end

function Provisions.CreateAuctionatorShoppingList()
    if type(RGMS.IsScanLocked) == "function" and RGMS.IsScanLocked() then
        return nil, "scan-locked"
    end
    ensureGuildSession()
    if type(RGMS.AccountDataState) ~= "table"
        or RGMS.AccountDataState.enabled ~= true
        or type(RGMS.ActiveGuildIdentity) ~= "table" then
        return nil, "saved data is unavailable"
    end
    if not AuctionatorIntegration.IsAvailable() then
        return reportAuctionatorFailure(
            "Auctionator v1 shopping-list API is unavailable"
        )
    end

    local bank = type(RGMS.DB) == "table" and RGMS.DB.bank or {}
    if type(bank.scannedAt) ~= "table" then
        return nil, "the active guild has no successful bank scan"
    end
    if #currentList() == 0 then
        return nil, "there are no saved provisions"
    end
    local terms = Model.buildAuctionatorTerms(currentList(), bank)
    if #terms == 0 then
        return nil, "every provision target is satisfied"
    end

    local created, creationError = AuctionatorIntegration.CreateShoppingList(terms)
    if not created then
        return reportAuctionatorFailure(creationError)
    end
    showSuccess("Successfully created RGMS Provisions shopping list")
    return true
end

function Provisions.Save()
    if type(RGMS.IsScanLocked) == "function" and RGMS.IsScanLocked() then
        return nil, "scan-locked"
    end
    ensureGuildSession()
    local creating = Provisions.selectedId == nil
    local normalized, validationError = Model.normalizeDraft(Provisions.draft)
    if not normalized then
        return nil, validationError
    end
    local items, nextId, selectedId
    if creating then
        items, nextId, selectedId = Model.add(
            currentList(),
            RGMS.DB.nextProvisionId,
            normalized
        )
    else
        items, selectedId = Model.update(
            currentList(),
            Provisions.selectedId,
            normalized
        )
        nextId = RGMS.DB.nextProvisionId
    end
    if not items then
        return reportFailure("save", selectedId)
    end
    local saved, saveError = persist(items, nextId)
    if not saved then
        return reportFailure("save", saveError)
    end
    clearSession()
    Provisions.RefreshStatus()
    showSuccess(
        (creating and "Successfully added " or "Successfully updated ")
            .. normalized.name
    )
    return true, selectedId
end

function Provisions.Delete(id)
    if type(RGMS.IsScanLocked) == "function" and RGMS.IsScanLocked() then
        return nil, "scan-locked"
    end
    ensureGuildSession()
    local deleteId = id or Provisions.selectedId
    if deleteId == nil then
        return nil, "no provision is selected"
    end
    local provision = Model.find(currentList(), deleteId)
    local items, deleteError = Model.delete(currentList(), deleteId)
    if not items then
        return reportFailure("delete", deleteError)
    end
    local deleted, persistenceError = persist(items, RGMS.DB.nextProvisionId)
    if not deleted then
        return reportFailure("delete", persistenceError)
    end
    if Provisions.selectedId == deleteId then
        clearSession()
    end
    Provisions.RefreshStatus()
    showSuccess("Removed " .. provision.name .. " from Provisions")
    return true
end

function Provisions.Reorder(orderedIds)
    if type(RGMS.IsScanLocked) == "function" and RGMS.IsScanLocked() then
        return nil, "scan-locked"
    end
    ensureGuildSession()
    local items, reorderError = Model.reorder(currentList(), orderedIds)
    if not items then
        return reportFailure("reorder", reorderError)
    end
    local reordered, persistenceError = persist(items, RGMS.DB.nextProvisionId)
    if not reordered then
        return reportFailure("reorder", persistenceError)
    end
    Provisions.RefreshStatus()
    return true
end

function Provisions.OnTabSelected()
    ensureGuildSession()
    local selected = Model.find(currentList(), Provisions.selectedId)
    if selected then
        Provisions.draft = Model.toDraft(selected)
    else
        clearSession()
    end
    return Provisions.RefreshStatus()
end

function Provisions.OnWindowClosed()
    clearSession()
    return true
end

function Provisions.OnGuildChanged()
    if type(RGMS.UI) == "table"
        and type(RGMS.UI.CancelProvisionDrag) == "function" then
        RGMS.UI.CancelProvisionDrag()
    end
    Provisions.activeGuildKey = nil
    ensureGuildSession()
    return Provisions.RefreshStatus()
end

RGMS.Provisions = Provisions

return Provisions
