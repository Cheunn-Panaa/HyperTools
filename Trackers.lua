WM = GetWindowManager()

local function DisplayGroupControl(number)
    if not DoesUnitExist("group" .. number) then
        return true
    end
    if IsUnitDead("group" .. number) then
        return true
    end
    if GetUnitName("group" .. number) == GetUnitName("player") then
        return true
    end
    if GetGroupMemberSelectedRole("group" .. number) == 0 then
        return true
    end
    if GetUnitZoneIndex("group" .. number) ~= GetUnitZoneIndex("player") then
        return true
    end
    return false
end

local function createProgressBar(parent, t, i)

    local container, bar, backdrop, label, icon, _, timer, stacks, iconOutline

    if parent:GetNamedChild(t.name .. "_Progress Bar"..(i or "")) then
        container = parent:GetNamedChild(t.name .. "_Progress Bar"..(i or ""))
        backdrop = container:GetNamedChild("backdrop")
        icon = container:GetNamedChild("icon")
        bar = icon:GetNamedChild("bar")
        label = container:GetNamedChild("label")
        timer = container:GetNamedChild("timer")
        stacks = icon:GetNamedChild("stacks")
        iconOutline = icon:GetNamedChild("iconOutline")

    else
        container = createContainer(parent, t.name .. "_Progress Bar"..(i or ""), t.sizeX, t.sizeY, t.xOffset, t.yOffset, TOPLEFT, TOPLEFT)
        backdrop = WM:CreateControl("$(parent)backdrop", container, CT_BACKDROP, 4)
        icon = createTexture(container, "icon", t.sizeY - (t.outlineThickness * 2), t.sizeY - (t.outlineThickness * 2), 0, 0, CENTER, CENTER, t.icon)
        bar = createTexture(icon, "bar", t.sizeX - t.sizeY - t.outlineThickness, t.sizeY, t.outlineThickness, 0, LEFT, RIGHT)
        label = createLabel(container, "label", t.sizeX - t.sizeY, t.sizeY, (t.sizeX / 20) + t.sizeY, 0, LEFT, LEFT, t.text, 0, 1, t.font, t.fontSize, "thick-outline")
        timer = createLabel(container, "timer", t.sizeX - t.sizeY, t.sizeY, t.sizeX / (-20), 0, RIGHT, RIGHT, "0.0", 2, 1, t.font, t.fontSize, "thick-outline")
        stacks = createLabel(icon, "stacks", t.sizeY - t.outlineThickness, t.sizeY - t.outlineThickness, 0, 0, TOPLEFT, TOPLEFT, "0", 1, 1, t.font, t.fontSize, "thick-outline")
        iconOutline = WM:CreateControl("$(parent)iconOutline", icon, CT_TEXTURE, 4)
    end

    container:SetHandler("OnMoveStop", function(_)
        t.xOffset = container:GetLeft() - parent:GetLeft()
        t.yOffset = container:GetTop() - parent:GetTop()
        container:ClearAnchors()
        container:SetAnchor(TOPLEFT, parent, TOPLEFT, t.xOffset, t.yOffset)
    end)

    iconOutline:SetTexture("")
    container:SetMovable(true)
    container:SetMouseEnabled(true)
    container.delete = false
    timer:SetHorizontalAlignment(1)
    timer:SetVerticalAlignment(1)
    local function Process()
        local override = {
            text = t.text,
            barColor = t.barColor,
            textColor = t.textColor,
            timeColor = t.timeColor,
            stacksColor = t.stacksColor,
            backgroundColor = t.backgroundColor,
            outlineColor = t.outlineColor,
            show = true,
            targetNumber = i or t.targetNumber,
            target = t.target,
        }
        if i then
            override.target = "Group"
        end
        for _, condition in pairs(t.conditions) do
            if operators[condition.operator](conditionArgs1[condition.arg1](t, override), condition.arg2) then
                conditionResults[condition.result](override, condition.resultArguments)
            end
        end

        if i then
            container:SetHidden((not override.show and not t.load.always) or DisplayGroupControl(i))
        else
            container:SetHidden((not override.show and not t.load.always))
        end
        local remainingTime = math.max((t.expiresAt[HT_targets[override.target](override.targetNumber)] or 0) - GetGameTimeSeconds(), 0)
        local duration = math.max((t.duration[HT_targets[override.target](override.targetNumber)] or 0), 0)
        local stacksCount = t.stacks[HT_targets[override.target](override.targetNumber)] or 0
        if remainingTime == 0 then
            stacksCount = 0
            if t.vertical then
                bar:SetDimensions(t.sizeX, 0)
            else
                bar:SetDimensions(0, t.sizeY)
            end
        end

        if t.vertical then
            bar:SetDimensions(t.sizeX, (t.sizeY- t.sizeX)*(remainingTime/duration))
        else
            bar:SetDimensions((t.sizeX-t.sizeY)*(remainingTime/duration), t.sizeY)
        end

        bar:SetColor(unpack(override.barColor))
        timer:SetText(HT_getDecimals(remainingTime, t.decimals))
        label:SetText(override.text)
        stacks:SetText(stacksCount)
        backdrop:SetCenterColor(unpack(override.backgroundColor))
        backdrop:SetEdgeColor(unpack(override.outlineColor))
    end

    local function Update(_, data, groupAnchor)
        if not container.delete then
            if HT_processLoad(data.load) then
                EVENT_MANAGER:RegisterForUpdate("HT_ProgressBar" .. data.name .. (i or ""), 100, Process)
            else
                EVENT_MANAGER:UnregisterForUpdate("HT_ProgressBar" .. data.name .. (i or ""), 100)
                container:SetHidden(true)
            end
        end

        for key, event in pairs(data.events) do
            HT_eventFunctions[event.type](key, event, data)
        end

        container:SetDimensions(data.sizeX, data.sizeY)

        icon:SetTexture(data.icon)
        if data.hideIcon then
            icon:SetDimensions(0, 0)
        end
        backdrop:SetCenterColor(unpack(data.backgroundColor))
        backdrop:ClearAnchors()
        backdrop:SetAnchor(CENTER, container, CENTER, 0, 0)
        backdrop:SetDimensions(data.sizeX + (data.outlineThickness * 2), data.sizeY + (data.outlineThickness * 2))
        backdrop:SetEdgeColor(unpack(data.outlineColor))
        backdrop:SetEdgeTexture("", data.outlineThickness, data.outlineThickness)

        --bar:SetColor(unpack(data.barColor))
        label:SetText(data.text)
        label:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        label:SetColor(unpack(data.textColor))
        stacks:SetDimensions(data.sizeY, data.sizeY)
        stacks:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        stacks:SetColor(unpack(data.stacksColor))
        timer:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        timer:SetColor(unpack(data.timeColor))

        iconOutline:SetColor(unpack(data.outlineColor))
        iconOutline:ClearAnchors()
        if data.vertical then
            icon:SetDimensions(data.sizeX, data.sizeX)
            timer:SetDimensions(data.sizeX, data.sizeX*4)
            timer:SetHorizontalAlignment(1)
            label:SetHorizontalAlignment(1)
            label:SetDimensions(data.sizeX, data.sizeY - (2*data.sizeX))
            iconOutline:SetDimensions(data.sizeX, data.outlineThickness)
            if data.inverse then
                iconOutline:SetAnchor(TOP, icon, BOTTOM, 0, 0)
                label:SetVerticalAlignment(3)
                timer:SetVerticalAlignment(4)
                icon:ClearAnchors()
                icon:SetAnchor(TOP, container, TOP, 0, 0)
                bar:ClearAnchors()
                bar:SetAnchor(TOP, icon, BOTTOM, 0, 0)
                label:ClearAnchors()
                label:SetAnchor(TOP, container, TOP,0, data.sizeX*1.4)
                timer:ClearAnchors()
                timer:SetAnchor(BOTTOM, container, BOTTOM, 0, 0)
            else
                iconOutline:SetAnchor(BOTTOM, icon, TOP, 0, 0)
                label:SetVerticalAlignment(4)
                timer:SetVerticalAlignment(3)
                icon:ClearAnchors()
                icon:SetAnchor(BOTTOM, container, BOTTOM, 0, 0)
                bar:ClearAnchors()
                bar:SetAnchor(BOTTOM, icon, TOP, 0, 0)
                label:ClearAnchors()
                label:SetAnchor(BOTTOM, container, BOTTOM,0, -data.sizeX*1.4)
                timer:ClearAnchors()
                timer:SetAnchor(TOP, container, TOP,0, 0)
            end
        else
            icon:SetDimensions(data.sizeY, data.sizeY)
            timer:SetDimensions(data.sizeY*4, data.sizeY)
            timer:SetVerticalAlignment(1)
            label:SetVerticalAlignment(1)
            label:SetDimensions(data.sizeX - data.sizeY, data.sizeY)
            iconOutline:SetDimensions(data.outlineThickness, data.sizeY)
            if data.inverse then
                iconOutline:SetAnchor(RIGHT, icon, LEFT, 0, 0)
                label:SetHorizontalAlignment(2)
                timer:SetHorizontalAlignment(0)
                icon:ClearAnchors()
                icon:SetAnchor(TOPRIGHT, container, TOPRIGHT, 0, 0)
                bar:ClearAnchors()
                bar:SetAnchor(RIGHT, icon, LEFT, 0, 0)
                label:ClearAnchors()
                label:SetAnchor(RIGHT, container, RIGHT, -data.sizeY*1.4, 0)
                timer:ClearAnchors()
                timer:SetAnchor(LEFT, container, LEFT, data.sizeY*0.4, 0)
            else
                iconOutline:SetAnchor(LEFT, icon, RIGHT, 0, 0)
                label:SetHorizontalAlignment(0)
                timer:SetHorizontalAlignment(2)
                icon:ClearAnchors()
                icon:SetAnchor(TOPLEFT, container, TOPLEFT, 0, 0)
                bar:ClearAnchors()
                bar:SetAnchor(LEFT, icon, RIGHT, 0, 0)
                label:ClearAnchors()
                label:SetAnchor(LEFT, container, LEFT, data.sizeY*1.4, 0)
                timer:ClearAnchors()
                timer:SetAnchor(RIGHT, container, RIGHT, -data.sizeY*0.4, 0)
            end
        end
        container:ClearAnchors()

        if data.parent == "HT_Trackers" then
            container:SetAnchor(TOPLEFT, HT_Trackers, TOPLEFT, data.xOffset, data.yOffset)
        elseif HT_getTrackerFromName(data.parent, HTSV.trackers).type == "Group Member" and groupAnchor then
            container:SetAnchor(TOPLEFT, HT_findContainer(HT_getTrackerFromName(data.parent, HTSV.trackers)):GetNamedChild(HT_getTrackerFromName(data.parent, HTSV.trackers).name .. "Group" .. groupAnchor), TOPLEFT, data.xOffset, data.yOffset)
        else
            container:SetAnchor(TOPLEFT, HT_findContainer(HT_getTrackerFromName(data.parent, HTSV.trackers)), TOPLEFT, data.xOffset, data.yOffset)
        end
        timer:SetHidden(not data.timer1)
        stacks:SetHidden(not data.timer2)
    end
    container.Update = Update
    container:Update(t)

    container.Process = Process

    local function UnregisterEvents(_)
        for key, event in pairs(t.events) do
            HT_unregisterEventFunctions[event.type](key, event, t)
        end
    end
    container.UnregisterEvents = UnregisterEvents

    local function Delete(self)
        self:UnregisterEvents()
        EVENT_MANAGER:UnregisterForUpdate("HT_ProgressBar" .. t.name..(i or ""), 100)
        container.delete = true
        self:SetHidden(true)
    end
    container.Delete = Delete

    return container
end

--layer
--level
--tier

local function createIconTracker(parent, t, i)

    local container, icon, background, animationTexture, timer, stacks, outline, cooldown, isChildrenOfGroupMember

    if parent:GetNamedChild(t.name .. "_Icon Tracker"..(i or "")) then
        container = parent:GetNamedChild(t.name .. "_Icon Tracker"..(i or ""))
        icon = container:GetNamedChild("icon")
        background = container:GetNamedChild("background")
        timer = icon:GetNamedChild("timer")
        stacks = icon:GetNamedChild("stacks")
        animationTexture = icon:GetNamedChild("animationTexture")
        outline = container:GetNamedChild("outline")
        cooldown = icon:GetNamedChild("cooldown")
    else
        container = createContainer(parent, t.name .. "_Icon Tracker"..(i or ""), t.sizeX, t.sizeY, t.xOffset, t.yOffset, TOPLEFT, TOPLEFT)
        icon = createTexture(container, "icon", t.sizeX, t.sizeY, 1, 1, TOPLEFT, TOPLEFT, t.icon)
        background = WM:CreateControl("$(parent)background", container, CT_TEXTURE, 4)
        timer = createLabel(icon, "timer", t.sizeX, t.sizeY / 2, 0, 0, BOTTOM, BOTTOM, "0.0", 1, 1, t.font, t.fontSize, "thick-outline")
        stacks = createLabel(icon, "stacks", t.sizeX, t.sizeY / 2, 0, 0, TOP, TOP, "0.0", 1, 1, t.font, t.fontSize, "thick-outline")
        animationTexture = WM:CreateControl("$(parent)animationTexture", icon, CT_TEXTURE, 4)
        outline = WM:CreateControl("$(parent)outline", container, CT_BACKDROP, 4)
        cooldown = createTexture(icon, "cooldown", t.sizeX, t.sizeY, 1, 1, BOTTOM, BOTTOM, "")
    end
    local timeline = ANIMATION_MANAGER:CreateTimeline()
    local animation = timeline:InsertAnimation(ANIMATION_TEXTURE, animationTexture)

    background:ClearAnchors()
    background:SetAnchor(CENTER, icon, CENTER, 0, 0)
    background:SetTexture("HyperTools/icons/regularBackground.dds")
    background:SetDrawLayer(0)

    icon:SetDrawLayer(1)
    cooldown:SetDrawLayer(2)

    animationTexture:ClearAnchors()
    animationTexture:SetAnchor(CENTER, icon, CENTER, 0, 0)
    animationTexture:SetAnchorFill()
    animationTexture:SetDrawLayer(3)
    animationTexture:SetHidden(true)
    animationTexture:SetTexture("/esoui/art/actionbar/abilityhighlight_mage_med.dds")

    animation:SetImageData(64, 1)
    animation:SetFramerate(64)

    timeline:SetEnabled(true)
    timeline:SetPlaybackType(ANIMATION_PLAYBACK_LOOP, LOOP_INDEFINITELY)
    timeline:PlayFromStart()

    outline:SetAnchor(CENTER, icon, CENTER, 0, 0)
    outline:SetDrawLayer(4)

    container:SetHandler("OnMoveStop", function(_)
        t.xOffset = container:GetLeft() - parent:GetLeft()
        t.yOffset = container:GetTop() - parent:GetTop()
        container:ClearAnchors()
        container:SetAnchor(TOPLEFT, parent, TOPLEFT, t.xOffset, t.yOffset)
    end)

    container.timer = timer
    container.stacks = stacks
    container:SetMovable(true)
    container:SetMouseEnabled(true)

    local function Process()
        local override = {
            text = t.text,
            barColor = t.barColor,
            textColor = t.textColor,
            timeColor = t.timeColor,
            stacksColor = t.stacksColor,
            backgroundColor = t.backgroundColor,
            outlineColor = t.outlineColor,
            show = true,
            targetNumber = i or t.targetNumber,
            showProc = false,
            target = t.target
        }
        if i then
            override.target = "Group"
        end
        for _, condition in pairs(t.conditions) do
            if operators[condition.operator](conditionArgs1[condition.arg1](t, override), condition.arg2) then
                conditionResults[condition.result](override, condition.resultArguments)
            end
        end
        if i then
            container:SetHidden((not override.show and not t.load.always) or DisplayGroupControl(i))
        else
            container:SetHidden((not override.show and not t.load.always))
        end
        local remainingTime = math.max((t.expiresAt[HT_targets[override.target](override.targetNumber)] or 0) - GetGameTimeSeconds(), 0)
        local duration = math.max((t.duration[HT_targets[override.target](override.targetNumber)] or 0), 0)
        local stacksCount = t.stacks[HT_targets[override.target](override.targetNumber)] or 0
        if remainingTime == 0 then
            cooldown:SetDimensions(t.sizeX, 0)
            --stacksCount = 0
        else
            cooldown:SetDimensions(t.sizeX, t.sizeY * (remainingTime / duration))
        end
        timer:SetColor(unpack(override.timeColor))
        timer:SetText(HT_getDecimals(remainingTime, t.decimals))
        stacks:SetColor(unpack(override.stacksColor))
        stacks:SetText(stacksCount)
        icon:SetColor(unpack(override.barColor))
        animationTexture:SetHidden(not override.showProc)
        background:SetColor(unpack(override.backgroundColor))
        background:SetTexture("")
        outline:SetEdgeColor(unpack(override.outlineColor))
    end

    local function Update(_, data, groupAnchor)
        if not container.delete then
            if HT_processLoad(data.load) then
                EVENT_MANAGER:RegisterForUpdate("HT_IconTracker" .. data.name..(i or ""), 100, Process)
                for key, event in pairs(data.events) do
                    HT_eventFunctions[event.type](key, event, data)
                end
            else
                EVENT_MANAGER:UnregisterForUpdate("HT_IconTracker" .. data.name..(i or ""), 100)
                container:SetHidden(true)
                for key, event in pairs(data.events) do
                    HT_unregisterEventFunctions[event.type](key, event, data)
                end
            end
        end


        container:SetDrawLayer(data.drawLevel)
        container:SetDimensions(data.sizeX, data.sizeY)
        icon:SetDimensions(data.sizeX, data.sizeY)
        icon:SetTexture(data.icon)
        icon:SetColor(unpack(data.barColor))
        cooldown:SetColor(unpack(data.cooldownColor))

        outline:SetDimensions(data.sizeX + (data.outlineThickness * 2), data.sizeY + (data.outlineThickness * 2))
        outline:SetEdgeColor(unpack(data.outlineColor))
        outline:SetCenterColor(0, 0, 0, 0)
        outline:SetEdgeTexture("", data.outlineThickness * 2, data.outlineThickness * 2)
        background:SetDimensions(data.sizeX, data.sizeY)
        background:SetColor(unpack(data.backgroundColor))
        timer:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        stacks:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        container:ClearAnchors()
        if data.parent == "HT_Trackers" then
            container:SetAnchor(TOPLEFT, HT_Trackers, TOPLEFT, data.xOffset, data.yOffset)
        elseif HT_getTrackerFromName(data.parent, HTSV.trackers).type == "Group Member" and groupAnchor then
            container:SetAnchor(TOPLEFT, HT_findContainer(HT_getTrackerFromName(data.parent, HTSV.trackers)):GetNamedChild(HT_getTrackerFromName(data.parent, HTSV.trackers).name .. "Group" .. groupAnchor), TOPLEFT, data.xOffset, data.yOffset)
        else
            container:SetAnchor(TOPLEFT, HT_findContainer(HT_getTrackerFromName(data.parent, HTSV.trackers)), TOPLEFT, data.xOffset, data.yOffset)
        end
        if data.timer1 and data.timer2 then
            timer:SetDimensions(data.sizeX, data.sizeY / 2)
            stacks:SetDimensions(data.sizeX, data.sizeY / 2)
        else
            timer:SetDimensions(data.sizeX, data.sizeY)
            stacks:SetDimensions(data.sizeX, data.sizeY)
        end
        timer:SetHidden(not data.timer1)
        stacks:SetHidden(not data.timer2)
    end
    container.Update = Update
    container:Update(t)
    container.Process = Process

    local function UnregisterEvents(_)
        for key, event in pairs(t.events) do
            HT_unregisterEventFunctions[event.type](key, event, t)
        end
    end
    container.UnregisterEvents = UnregisterEvents

    local function Delete(self)
        self:UnregisterEvents()
        EVENT_MANAGER:UnregisterForUpdate("HT_IconTracker" .. t.name..(i or ""), 100)
        self:SetHidden(true)
    end
    container.Delete = Delete

    return container
end


local function createProgressTexture(parent, t, i)

    local container, backdrop, label, icon, _, timer, stacks, iconOutline

    if parent:GetNamedChild(t.name .. "_Progress Texture"..(i or "")) then
        container = parent:GetNamedChild(t.name .. "_Progress Texture"..(i or ""))
        backdrop = container:GetNamedChild("backdrop")
        icon = container:GetNamedChild("icon")
        label = container:GetNamedChild("label")
        timer = container:GetNamedChild("timer")
        stacks = icon:GetNamedChild("stacks")
        iconOutline = icon:GetNamedChild("iconOutline")

    else
        container = createContainer(parent, t.name .. "_Progress Texture"..(i or ""), t.sizeX, t.sizeY, t.xOffset, t.yOffset, TOPLEFT, TOPLEFT)
        backdrop = WM:CreateControl("$(parent)backdrop", container, CT_BACKDROP, 4)
        icon = createTexture(container, "icon", t.sizeY - (t.outlineThickness * 2), t.sizeY - (t.outlineThickness * 2), 0, 0, CENTER, CENTER, t.icon)
        label = createLabel(container, "label", t.sizeX - t.sizeY, t.sizeY, (t.sizeX / 20) + t.sizeY, 0, LEFT, LEFT, t.text, 0, 1, t.font, t.fontSize, "thick-outline")
        timer = createLabel(container, "timer", t.sizeX - t.sizeY, t.sizeY, t.sizeX / (-20), 0, RIGHT, RIGHT, "0.0", 2, 1, t.font, t.fontSize, "thick-outline")
        stacks = createLabel(icon, "stacks", t.sizeY - t.outlineThickness, t.sizeY - t.outlineThickness, 0, 0, TOPLEFT, TOPLEFT, "0", 1, 1, t.font, t.fontSize, "thick-outline")
        iconOutline = WM:CreateControl("$(parent)iconOutline", icon, CT_TEXTURE, 4)
    end

    container:SetHandler("OnMoveStop", function(_)
        t.xOffset = container:GetLeft() - parent:GetLeft()
        t.yOffset = container:GetTop() - parent:GetTop()
        container:ClearAnchors()
        container:SetAnchor(TOPLEFT, parent, TOPLEFT, t.xOffset, t.yOffset)
    end)

    iconOutline:SetAnchor(LEFT, icon, RIGHT, 0, 0)
    iconOutline:SetTexture("")
    container:SetMovable(true)
    container:SetMouseEnabled(true)
    container.delete = false
    local function Process()
        local override = {
            text = t.text,
            barColor = t.barColor,
            textColor = t.textColor,
            timeColor = t.timeColor,
            stacksColor = t.stacksColor,
            backgroundColor = t.backgroundColor,
            outlineColor = t.outlineColor,
            show = true,
            targetNumber = i or t.targetNumber,
            target = t.target,
        }
        if i then
            override.target = "Group"
        end
        for _, condition in pairs(t.conditions) do
            if operators[condition.operator](conditionArgs1[condition.arg1](t, override), condition.arg2) then
                conditionResults[condition.result](override, condition.resultArguments)
            end
        end

        if i then
            container:SetHidden((not override.show and not t.load.always) or DisplayGroupControl(i))
        else
            container:SetHidden((not override.show and not t.load.always))
        end
        local remainingTime = math.max((t.expiresAt[HT_targets[override.target](override.targetNumber)] or 0) - GetGameTimeSeconds(), 0)
        local duration = math.max((t.duration[HT_targets[override.target](override.targetNumber)] or 0), 0)
        local stacksCount = t.stacks[HT_targets[override.target](override.targetNumber)] or 0
        if remainingTime == 0 then
            stacksCount = 0
        end
        if t.vertical then
            icon:SetDimensions(t.sizeX, t.sizeY*(remainingTime/duration))
            if t.inverse then
                icon:SetTextureCoords(0,1,0,(remainingTime/duration))
            else
                icon:SetTextureCoords(0,1,(remainingTime/duration),1)
            end
        else
            icon:SetDimensions(t.sizeX*(remainingTime/duration), t.sizeY)
            if t.inverse then
                icon:SetTextureCoords(0,(remainingTime/duration),0,1)
            else
                icon:SetTextureCoords((remainingTime/duration),1,0,1)
            end
        end

        icon:SetColor(unpack(override.barColor))
        timer:SetText(HT_getDecimals(remainingTime, t.decimals))
        label:SetText(override.text)
        stacks:SetText(stacksCount)
        backdrop:SetCenterColor(unpack(override.backgroundColor))
        backdrop:SetEdgeColor(unpack(override.outlineColor))

    end

    local function Update(_, data, groupAnchor)
        if not container.delete then
            if HT_processLoad(data.load) then
                EVENT_MANAGER:RegisterForUpdate("HT_ProgressTexture" .. data.name .. (i or ""), 100, Process)
            else
                EVENT_MANAGER:UnregisterForUpdate("HT_ProgressTexture" .. data.name .. (i or ""), 100)
                container:SetHidden(true)
            end
        end

        for key, event in pairs(data.events) do
            HT_eventFunctions[event.type](key, event, data)
        end

        container:SetDimensions(data.sizeX, data.sizeY)
        icon:SetDimensions(data.sizeX, data.sizeY)
        icon:SetTexture(data.icon)
        if data.hideIcon then
            icon:SetDimensions(0, 0)
        end
        backdrop:SetCenterColor(unpack(data.backgroundColor))
        backdrop:ClearAnchors()
        backdrop:SetAnchor(CENTER, container, CENTER, 0, 0)
        backdrop:SetDimensions(data.sizeX + (data.outlineThickness * 2), data.sizeY + (data.outlineThickness * 2))
        backdrop:SetEdgeColor(unpack(data.outlineColor))
        backdrop:SetEdgeTexture("", data.outlineThickness, data.outlineThickness)
        iconOutline:SetDimensions(data.outlineThickness, data.sizeY)
        iconOutline:SetColor(unpack(data.outlineColor))
        --bar:SetColor(unpack(data.barColor))
        label:SetDimensions(data.sizeX - data.sizeY, data.sizeY)
        label:SetText(data.text)
        label:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        label:SetColor(unpack(data.textColor))
        stacks:SetDimensions(data.sizeY, data.sizeY)
        stacks:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        stacks:SetColor(unpack(data.stacksColor))
        timer:SetDimensions(data.sizeX - data.sizeY, data.sizeY)
        timer:SetFont(string.format("$(%s)|$(KB_%s)|%s", data.font, data.fontSize, data.fontWeight))
        timer:SetColor(unpack(data.timeColor))
        icon:ClearAnchors()
        if data.vertical then
            if data.inverse then
                icon:SetAnchor(TOP, container, TOP, 0, 0)
            else
                icon:SetAnchor(BOTTOM, container, BOTTOM, 0, 0)
            end
        else
            if data.inverse then
                icon:SetAnchor(RIGHT, container, RIGHT, 0, 0)
            else
                icon:SetAnchor(LEFT, container, LEFT, 0, 0)
            end
        end

        label:ClearAnchors()
        label:SetAnchor(LEFT, container, LEFT, (data.sizeX / 20) + data.sizeY, 0)
        stacks:ClearAnchors()
        stacks:SetAnchor(LEFT, container, LEFT, (data.sizeX / 20) + data.sizeY, 0)
        timer:ClearAnchors()
        timer:SetAnchor(RIGHT, container, RIGHT, (data.sizeX / -20), 0)
        container:ClearAnchors()

        if data.parent == "HT_Trackers" then
            container:SetAnchor(TOPLEFT, HT_Trackers, TOPLEFT, data.xOffset, data.yOffset)
        elseif HT_getTrackerFromName(data.parent, HTSV.trackers).type == "Group Member" and groupAnchor then
            container:SetAnchor(TOPLEFT, HT_findContainer(HT_getTrackerFromName(data.parent, HTSV.trackers)):GetNamedChild(HT_getTrackerFromName(data.parent, HTSV.trackers).name .. "Group" .. groupAnchor), TOPLEFT, data.xOffset, data.yOffset)
        else
            container:SetAnchor(TOPLEFT, HT_findContainer(HT_getTrackerFromName(data.parent, HTSV.trackers)), TOPLEFT, data.xOffset, data.yOffset)
        end
        timer:SetHidden(not data.timer1)
        stacks:SetHidden(not data.timer2)
    end
    container.Update = Update
    container:Update(t)

    container.Process = Process

    local function UnregisterEvents(_)
        for key, event in pairs(t.events) do
            HT_unregisterEventFunctions[event.type](key, event, t)
        end
    end
    container.UnregisterEvents = UnregisterEvents

    local function Delete(self)
        self:UnregisterEvents()
        EVENT_MANAGER:UnregisterForUpdate("HT_ProgressTexture" .. t.name..(i or ""), 100)
        container.delete = true
        self:SetHidden(true)
    end
    container.Delete = Delete

    return container
end



local function createGroup(parent, t, i)

    local container, backdrop
    if parent:GetNamedChild(t.name .. "_Group" .. (i or "")) then
        container = parent:GetNamedChild(t.name .. "_Group" .. (i or ""))
        backdrop = container:GetNamedChild("backdrop")
    else
        container = createContainer(parent, t.name .. "_Group" .. (i or ""), t.sizeX, t.sizeY, t.xOffset, t.yOffset, TOPLEFT, TOPLEFT)
        backdrop = WM:CreateControl("$(parent)backdrop", container, CT_BACKDROP, 4)
    end

    container:SetHandler("OnMoveStop", function(_)
        if i then
            t.xOffset = container:GetLeft() - HT_3D:GetNamedChild(i):GetLeft()
            t.yOffset = container:GetTop() - HT_3D:GetNamedChild(i):GetTop()
            container:ClearAnchors()
            container:SetAnchor(TOPLEFT, HT_3D:GetNamedChild(i), TOPLEFT, t.xOffset, t.yOffset)
            HT_findContainer(t):Update(t)
        else
            t.xOffset = container:GetLeft() - parent:GetLeft()
            t.yOffset = container:GetTop() - parent:GetTop()
            container:ClearAnchors()
            container:SetAnchor(TOPLEFT, parent, TOPLEFT, t.xOffset, t.yOffset)
        end

    end)

    container:SetMovable(true)
    container:SetMouseEnabled(true)
    for _, childName in pairs(t.children) do
        initializeTrackerFunctions[childName.type](container, childName,i)
    end

    local function Process()
        local override = {
            text = t.text,
            barColor = t.barColor,
            textColor = t.textColor,
            timeColor = t.timeColor,
            stacksColor = t.stacksColor,
            backgroundColor = t.backgroundColor,
            outlineColor = t.outlineColor,
            show = true,
            targetNumber = i or t.targetNumber
        }
        for _, condition in pairs(t.conditions) do
            if operators[condition.operator](conditionArgs1[condition.arg1](t, override), condition.arg2) then
                conditionResults[condition.result](override, condition.resultArguments)
            end
        end

        if i then
            container:SetHidden((not override.show and not t.load.always) or DisplayGroupControl(i))
            override.target = "Group"
        else
            container:SetHidden((not override.show and not t.load.always))
        end

        backdrop:SetCenterColor(unpack(override.backgroundColor))
        backdrop:SetEdgeColor(unpack(override.outlineColor))

        if CST.name == t.name and HT_settingsVisible then
            -- If the group is currently selected in settings
            backdrop:SetCenterColor(0.5, 0.9, 1, 0.3)
            backdrop:SetEdgeColor(0.5, 0.9, 1, 1)
        else
            backdrop:SetCenterColor(unpack(t.backgroundColor))
            backdrop:SetEdgeColor(unpack(t.outlineColor))
        end
    end
    local function Update(_, data, groupAnchor)
        for _, childTracker in pairs(data.children) do
            if not HT_findContainer(childTracker, (i or "")) then
                initializeTrackerFunctions[childTracker.type](container, childTracker,i)
            end
            HT_findContainer(childTracker, (i or "")):Update(childTracker)
        end
        if not container.delete then
            if HT_processLoad(data.load) then
                EVENT_MANAGER:RegisterForUpdate("HT_Group" .. data.name .. (i or ""), 100, Process)
            else
                EVENT_MANAGER:UnregisterForUpdate("HT_Group" .. data.name .. (i or ""), 100)
                container:SetHidden(true)
            end
        end

        for key, event in pairs(data.events) do
            HT_eventFunctions[event.type](key, event, data)
        end

        container:SetDimensions(data.sizeX, data.sizeY)
        container:ClearAnchors()
        backdrop:SetCenterColor(unpack(data.backgroundColor))
        backdrop:ClearAnchors()
        backdrop:SetAnchor(CENTER, container, CENTER, 0, 0)
        backdrop:SetDimensions(data.sizeX + (data.outlineThickness * 2), data.sizeY + (data.outlineThickness * 2))
        backdrop:SetEdgeColor(unpack(data.outlineColor))
        backdrop:SetEdgeTexture("", data.outlineThickness, data.outlineThickness)

        if groupAnchor then
            container:SetAnchor(TOPLEFT, HT_3D:GetNamedChild(groupAnchor), TOPLEFT, data.xOffset, data.yOffset)
            container:SetHidden(DisplayGroupControl(groupAnchor))
        elseif data.parent == "HT_Trackers" then
            container:SetAnchor(TOPLEFT, HT_Trackers, TOPLEFT, data.xOffset, data.yOffset)
        else
            container:SetAnchor(TOPLEFT, HT_findContainer(HT_getTrackerFromName(data.parent, HTSV.trackers)), TOPLEFT, data.xOffset, data.yOffset)
        end
        for _, childName in pairs(data.children) do
            HT_findContainer(childName, i):Update(childName, groupAnchor)
        end
    end
    container.Update = Update
    container:Update(t)
    container.Process = Process

    local function UnregisterEvents(_)
        for key, event in pairs(t.events) do
            HT_unregisterEventFunctions[event.type](key, event, t)
        end
        for _, childName in pairs(t.children) do
            HT_findContainer(childName, i):UnregisterEvents()
        end
    end
    container.UnregisterEvents = UnregisterEvents

    local function Delete(self)
        self:UnregisterEvents()
        EVENT_MANAGER:UnregisterForUpdate("HT_Group" .. t.name .. (i or ""), 100)
        self:SetHidden(true)
        for _, childName in pairs(t.children) do
            HT_findContainer(childName, i):Delete()
        end
    end
    container.Delete = Delete

    return container
end

local function createGroupMemberGroup(parent, t)

    local container

    if parent:GetNamedChild(t.name .. "_Group Member") then
        container = parent:GetNamedChild(t.name .. "_Group Member")
    else
        container = createContainer(parent, t.name .. "_Group Member", 0, 0, 0, 0, TOPLEFT, TOPLEFT)
    end

    container.group = {}
    for i = 1, 12 do
        local newGroup = createGroup(parent, t, i)

        container.group[i] = newGroup
    end

    local function Process()
        if HT_processLoad(t.load) then
            for i = 1, 12 do
                container.group[i]:Process()
            end
        else
            container:SetHidden(true)
        end
    end
    container.Process = Process
    local function Update(_, data)
        for i = 1, 12 do
            container.group[i]:Update(data, i)
        end
    end
    container.Update = Update
    container:Update(t)
    local function Delete(_)
        for i = 1, 12 do
            container.group[i]:Delete()
        end
    end

    local function UnregisterEvents(_)
        for i = 1, 12 do
            container.group[i]:UnregisterEvents()
        end
    end
    container.UnregisterEvents = UnregisterEvents
    container.Delete = Delete

    return container
end

initializeTrackerFunctions = {
    ["Icon Tracker"] = createIconTracker,
    ["Progress Bar"] = createProgressBar,
    ["Group"] = createGroup,
    ["Group Member"] = createGroupMemberGroup,
    ["Progress Texture"] = createProgressTexture,
}