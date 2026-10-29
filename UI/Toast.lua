local _, RGMS = ...

local Runtime = assert(RGMS.UIRuntime, "UI/Widgets.lua must load first")

Runtime.Register("Toast", function()
function ProvisionUI.toastWidth(frame)
    local innerWidth = frame:GetWidth() - ProvisionUI.TOAST_BORDER_INSET * 2
    return math.min(ProvisionUI.TOAST_MAX_WIDTH, math.max(1, innerWidth))
end

function ProvisionUI.reflowToasts(frame)
    for index, toast in ipairs(frame.toasts or {}) do
        toast:ClearAllPoints()
        if index == 1 then
            toast:SetPoint(
                "TOP",
                frame.header,
                "TOP",
                0,
                ProvisionUI.TOAST_TOP_OFFSET
            )
        else
            toast:SetPoint(
                "TOP",
                frame.toasts[index - 1],
                "BOTTOM",
                0,
                -ProvisionUI.TOAST_GAP
            )
        end
    end
end

function ProvisionUI.removeToast(frame, toast)
    if toast.removed then
        return
    end
    toast.removed = true
    toast:SetScript("OnUpdate", nil)
    toast:Hide()
    for index, current in ipairs(frame.toasts or {}) do
        if current == toast then
            table.remove(frame.toasts, index)
            break
        end
    end
    ProvisionUI.reflowToasts(frame)
end


function UI.ShowToast(message)
    if not UI.frame then
        return nil, "the RGMS window has not been initialized"
    end
    if type(message) ~= "string" or message == "" then
        return nil, "toast message must be a non-empty string"
    end

    local frame = UI.frame
    local toast = createFrame("Frame", nil, frame, "BackdropTemplate")
    local width = ProvisionUI.toastWidth(frame)
    toast:SetWidth(width)
    toast:SetFrameLevel(
        frame:GetFrameLevel() + ProvisionUI.TOAST_FRAME_LEVEL_OFFSET
    )
    toast:EnableMouse(false)
    toast:SetAlpha(1)
    flatBackdrop(toast, PALETTE.shell, PALETTE.border)

    toast.accent = toast:CreateTexture(nil, "ARTWORK")
    toast.accent:SetTexture(WHITE_TEXTURE)
    toast.accent:SetVertexColor(unpackColor(PALETTE.pink))
    toast.accent:SetPoint("TOPLEFT", toast, "TOPLEFT", 1, -1)
    toast.accent:SetPoint("BOTTOMLEFT", toast, "BOTTOMLEFT", 1, 1)
    toast.accent:SetWidth(3)

    toast.text = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toast.text:SetWidth(width - ProvisionUI.TOAST_TEXT_HORIZONTAL_PADDING * 2)
    toast.text:SetPoint(
        "TOP",
        toast,
        "TOP",
        0,
        -ProvisionUI.TOAST_TEXT_VERTICAL_PADDING
    )
    toast.text:SetJustifyH("CENTER")
    toast.text:SetJustifyV("MIDDLE")
    toast.text:SetWordWrap(true)
    toast.text:SetNonSpaceWrap(true)
    toast.text:SetMaxLines(0)
    toast.text:SetText(message)
    setFont(toast.text, FONT_REGULAR, 12)
    setTextColor(toast.text, PALETTE.text)
    toast:SetHeight(math.max(
        ProvisionUI.TOAST_MIN_HEIGHT,
        toast.text:GetStringHeight()
            + ProvisionUI.TOAST_TEXT_VERTICAL_PADDING * 2
    ))

    toast.elapsed = 0
    toast:SetScript("OnUpdate", function(current, elapsed)
        current.elapsed = current.elapsed + elapsed
        if current.elapsed <= ProvisionUI.TOAST_HOLD_SECONDS then
            current:SetAlpha(1)
            return
        end
        local fadeElapsed = current.elapsed - ProvisionUI.TOAST_HOLD_SECONDS
        if fadeElapsed < ProvisionUI.TOAST_FADE_SECONDS then
            current:SetAlpha(1 - fadeElapsed / ProvisionUI.TOAST_FADE_SECONDS)
            return
        end
        current:SetAlpha(0)
        ProvisionUI.removeToast(frame, current)
    end)

    table.insert(frame.toasts, 1, toast)
    ProvisionUI.reflowToasts(frame)
    return toast
end

function UI.ClearToasts()
    if not UI.frame then
        return true
    end
    for _, toast in ipairs(UI.frame.toasts or {}) do
        toast.removed = true
        toast:SetScript("OnUpdate", nil)
        toast:Hide()
    end
    UI.frame.toasts = {}
    return true
end


end, {
    "ShowToast",
    "ClearToasts",
})

