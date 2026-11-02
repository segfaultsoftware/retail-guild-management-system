-- Runtime adapter that presents the active guild's account-wide chart history.

local _, RGMS = ...

local Charts = {}

function Charts.RefreshStatus()
    if type(RGMS.UI) ~= "table"
        or type(RGMS.UI.SetChartsHistory) ~= "function" then
        return false
    end
    local history = type(RGMS.DB) == "table" and RGMS.DB.chartHistory or nil
    if type(history) ~= "table" then
        history = RGMS.ChartModel.newHistory()
    end
    local today, dateError = RGMS.DateTime.currentPacificDate()
    if not today then
        return nil, dateError
    end
    return RGMS.UI.SetChartsHistory(history, today)
end

function Charts.OnGuildChanged()
    if type(RGMS.UI) == "table"
        and type(RGMS.UI.ResetCharts) == "function" then
        RGMS.UI.ResetCharts()
    end
    return Charts.RefreshStatus()
end

RGMS.Charts = Charts

return Charts
