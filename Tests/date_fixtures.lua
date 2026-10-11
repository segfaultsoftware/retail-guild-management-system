-- Fixed Unix timestamps around Pacific midnight and daylight-saving changes.
-- These values keep date behavior deterministic in every machine timezone.

return {
    pacificMidnight = {
        before = 1717225199, -- 2024-05-31 23:59:59 PDT
        after = 1717225200, -- 2024-06-01 00:00:00 PDT
    },
    springForward = {
        beforeTransition = 1710064799, -- 2024-03-10 01:59:59 PST
        afterTransition = 1710064800, -- 2024-03-10 03:00:00 PDT
        firstMidnight = 1710057600, -- 2024-03-10 00:00:00 PST
        nextMidnight = 1710140400, -- 2024-03-11 00:00:00 PDT (23 hours)
    },
    fallBack = {
        beforeTransition = 1730624399, -- 2024-11-03 01:59:59 PDT
        afterTransition = 1730624400, -- 2024-11-03 01:00:00 PST
        firstMidnight = 1730617200, -- 2024-11-03 00:00:00 PDT
        nextMidnight = 1730707200, -- 2024-11-04 00:00:00 PST (25 hours)
    },
}
