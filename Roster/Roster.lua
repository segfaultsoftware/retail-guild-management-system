local _, RGMS = ...

-- Guild roster collection and reporting will live in this module.
RGMS.Roster = RGMS.Roster or {}

function RGMS.Roster.CanScan()
    return RGMS.Reset:canScan("the guild roster")
end

function RGMS.Roster.CanReport()
    return RGMS.Reset:canReport("the roster report")
end
