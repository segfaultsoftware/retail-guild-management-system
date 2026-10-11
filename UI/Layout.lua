-- Pure layout calculations for the RGMS window. Keeping screen geometry out
-- of the FrameXML adapter makes off-screen recovery deterministic and testable.

local _, RGMS = ...

local Layout = {}

Layout.WINDOW_WIDTH = 420
Layout.WINDOW_HEIGHT = 560
Layout.EDGE_MARGIN = 12

local ANCHOR_FACTORS = {
    TOPLEFT = { 0, 1 },
    TOP = { 0.5, 1 },
    TOPRIGHT = { 1, 1 },
    LEFT = { 0, 0.5 },
    CENTER = { 0.5, 0.5 },
    RIGHT = { 1, 0.5 },
    BOTTOMLEFT = { 0, 0 },
    BOTTOM = { 0.5, 0 },
    BOTTOMRIGHT = { 1, 0 },
}

local function clamp(value, minimum, maximum)
    if maximum < minimum then
        return (minimum + maximum) / 2
    end
    if value < minimum then
        return minimum
    end
    if value > maximum then
        return maximum
    end
    return value
end

function Layout.defaultPosition()
    return {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
    }
end

function Layout.positionToRectangle(position, width, height, screenWidth, screenHeight)
    local pointFactor = ANCHOR_FACTORS[position.point]
    local relativeFactor = ANCHOR_FACTORS[position.relativePoint]
    if not pointFactor or not relativeFactor then
        return nil, "unsupported anchor point"
    end

    local left = screenWidth * relativeFactor[1]
        + position.x
        - width * pointFactor[1]
    local bottom = screenHeight * relativeFactor[2]
        + position.y
        - height * pointFactor[2]

    return {
        left = left,
        bottom = bottom,
        width = width,
        height = height,
    }
end

function Layout.clampRectangle(rectangle, screenWidth, screenHeight, margin)
    margin = margin or Layout.EDGE_MARGIN

    local maximumLeft = screenWidth - margin - rectangle.width
    local maximumBottom = screenHeight - margin - rectangle.height

    return {
        left = clamp(rectangle.left, margin, maximumLeft),
        bottom = clamp(rectangle.bottom, margin, maximumBottom),
        width = rectangle.width,
        height = rectangle.height,
    }
end

-- Returns a canonical BOTTOMLEFT position. Canonical coordinates avoid
-- accumulating anchor-dependent drift across reloads and UI-scale changes.
function Layout.clampPosition(position, width, height, screenWidth, screenHeight, margin)
    local rectangle, positionError = Layout.positionToRectangle(
        position,
        width,
        height,
        screenWidth,
        screenHeight
    )
    if not rectangle then
        return nil, positionError
    end

    local clamped = Layout.clampRectangle(
        rectangle,
        screenWidth,
        screenHeight,
        margin
    )

    return {
        point = "BOTTOMLEFT",
        relativePoint = "BOTTOMLEFT",
        x = clamped.left,
        y = clamped.bottom,
    }
end

function Layout.isFullyVisible(position, width, height, screenWidth, screenHeight, margin)
    margin = margin or Layout.EDGE_MARGIN
    local rectangle = Layout.positionToRectangle(
        position,
        width,
        height,
        screenWidth,
        screenHeight
    )
    if not rectangle then
        return false
    end

    return rectangle.left >= margin
        and rectangle.bottom >= margin
        and rectangle.left + width <= screenWidth - margin
        and rectangle.bottom + height <= screenHeight - margin
end

if type(RGMS) == "table" then
    RGMS.UILayout = Layout
end

return Layout
