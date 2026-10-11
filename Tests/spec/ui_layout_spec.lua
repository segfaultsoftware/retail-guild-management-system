local layout = require("UI.Layout")
local test = require("Tests.lib.runner")

local function assertClose(actual, expected)
    test.assert_true(
        math.abs(actual - expected) < 0.0001,
        "expected " .. tostring(expected) .. ", got " .. tostring(actual)
    )
end

return {
    test.case("default dimensions fit a 1920 by 1080 screen", function()
        test.assert_true(layout.WINDOW_WIDTH < 1920 / 2)
        test.assert_true(layout.WINDOW_HEIGHT < 1080)

        local position = layout.clampPosition(
            layout.defaultPosition(),
            layout.WINDOW_WIDTH,
            layout.WINDOW_HEIGHT,
            1920,
            1080
        )

        assertClose(position.x, 750)
        assertClose(position.y, 260)
        test.assert_true(layout.isFullyVisible(
            position,
            layout.WINDOW_WIDTH,
            layout.WINDOW_HEIGHT,
            1920,
            1080
        ))
    end),

    test.case("valid positions preserve their rendered location", function()
        local position = layout.clampPosition({
            point = "TOPLEFT",
            relativePoint = "TOPLEFT",
            x = 120,
            y = -80,
        }, 420, 560, 1920, 1080)

        test.assert_equal(position.point, "BOTTOMLEFT")
        test.assert_equal(position.relativePoint, "BOTTOMLEFT")
        assertClose(position.x, 120)
        assertClose(position.y, 440)
    end),

    test.case("off-screen positions recover to a fully visible location", function()
        local position = layout.clampPosition({
            point = "BOTTOMLEFT",
            relativePoint = "BOTTOMLEFT",
            x = 9000,
            y = -4000,
        }, 420, 560, 1280, 720)

        assertClose(position.x, 848)
        assertClose(position.y, 12)
        test.assert_true(layout.isFullyVisible(position, 420, 560, 1280, 720))
    end),

    test.case("each edge is clamped with a consistent margin", function()
        local cases = {
            { x = -200, y = 100, expectedX = 12, expectedY = 100 },
            { x = 100, y = -200, expectedX = 100, expectedY = 12 },
            { x = 1200, y = 100, expectedX = 848, expectedY = 100 },
            { x = 100, y = 600, expectedX = 100, expectedY = 148 },
        }

        for _, fixture in ipairs(cases) do
            local position = layout.clampPosition({
                point = "BOTTOMLEFT",
                relativePoint = "BOTTOMLEFT",
                x = fixture.x,
                y = fixture.y,
            }, 420, 560, 1280, 720)
            assertClose(position.x, fixture.expectedX)
            assertClose(position.y, fixture.expectedY)
            test.assert_true(layout.isFullyVisible(position, 420, 560, 1280, 720))
        end
    end),

    test.case("all supported anchor combinations resolve consistently", function()
        local centered = layout.positionToRectangle({
            point = "CENTER",
            relativePoint = "CENTER",
            x = 20,
            y = -30,
        }, 420, 560, 1920, 1080)

        assertClose(centered.left, 770)
        assertClose(centered.bottom, 230)

        local bottomRight = layout.positionToRectangle({
            point = "BOTTOMRIGHT",
            relativePoint = "BOTTOMRIGHT",
            x = -12,
            y = 12,
        }, 420, 560, 1920, 1080)

        assertClose(bottomRight.left, 1488)
        assertClose(bottomRight.bottom, 12)
    end),
}
