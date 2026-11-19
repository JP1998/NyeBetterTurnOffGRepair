local app = select(2, ...);
local L = app.L;

local initialized = false;

app.Settings = {};
local settings = app.Settings;

local settingsFrame = CreateFrame("FRAME", app:GetName() .. "-Settings", UIParent);
settings.Frame = settingsFrame;

settingsFrame.name = app:GetName();
settingsFrame.MostRecentTab = nil;
settingsFrame.Tabs = {};
settingsFrame.ModifierKeys = { "None", "Shift", "Ctrl", "Alt" };

local mainCategory = Settings.RegisterCanvasLayoutCategory(settingsFrame, settingsFrame.name, settingsFrame.name);
mainCategory.ID = settingsFrame.name;
Settings.RegisterAddOnCategory(mainCategory);

settings.Open = function(self)
    -- Open the Options menu.
    if not SettingsPanel:IsVisible() then
        SettingsPanel:Show();
    end

    Settings.OpenToCategory(app:GetName());
end

local SettingsBase = {
    ["Debug"] = {
        ["Enabled"] = false,
    },
    ["Position"] = {
        ["Horizontal"] = 0,
        ["Vertical"] = 0,
    },
    -- TODO: Save whether to show reminder (per character?)
    ["General"] = {
        ["GuildRank"] = 6,
        ["Timeout"] = 60, --?
    },
};

settings.Initialize = function(self)
    PanelTemplates_SetNumTabs(self.Frame, #self.Frame.Tabs);

    if not NyeBetterTurnOffGRepairSettings then
        NyeBetterTurnOffGRepairSettings = CopyTable(SettingsBase);
    end

    settings.Data = NyeBetterTurnOffGRepairSettings;

    app.Settings.Debug.EnabledCheckBox:SetChecked(NyeBetterTurnOffGRepairSettings["Debug"]["Enabled"]);

    app.Settings.Position.XSlider:SetValue(NyeBetterTurnOffGRepairSettings["Position"]["Horizontal"]);
    app.Settings.Position.YSlider:SetValue(NyeBetterTurnOffGRepairSettings["Position"]["Vertical"]);

    self.Frame:Refresh();

    initialized = true;
end
settings.Get = function(self, category, option)
    if category == nil then
        return self.Data;
    elseif option == nil then
        return self.Data and self.Data[category];
    else
        return self.Data and self.Data[category][option];
    end
end
settings.Set = function(self, category, option, value)
    self.Data[category][option] = value;

    self.Frame:Refresh();
end

settingsFrame.AddObject = function(self, obj)
    if not self.objects then
        self.objects = {};
    end

    table.insert(self.objects, obj);
end
settingsFrame.Refresh = function(self)
    if not self.objects then
        return;
    end

    for i,obj in ipairs(self.objects) do
        if obj.OnRefresh then
            obj:OnRefresh();
        end
    end
end
settingsFrame.CreateCheckBox = function(self, parent, text, OnRefresh, OnClick)
    local cb = CreateFrame("CheckButton", self:GetName() .. "-" .. text, parent, "InterfaceOptionsCheckButtonTemplate");

    cb:SetScript("OnClick", OnClick);
    cb.OnRefresh = OnRefresh;
    cb.Text:SetText(text);
    cb:SetHitRectInsets(0,0 - cb.Text:GetWidth(),0,0);
    cb:Show();

    return cb;
end
settingsFrame.CreateTab = function(self, text, scroll)
    local id = #self.Tabs + 1;

    local settingsPanel;
    local subcategoryPanel;

    if scroll then
        local scrollFrame = CreateFrame("ScrollFrame", self:GetName() .. "-Tab" .. id .. "-Scroll", self, "ScrollFrameTemplate");
        settingsPanel = CreateFrame("Frame", self:GetName() .. "-Tab" .. id);

        scrollFrame:SetScrollChild(settingsPanel);
        settingsPanel:SetID(id);
        settingsPanel:SetWidth(1);    -- This is automatically defined, so long as the attribute exists at all
        settingsPanel:SetHeight(1);   -- This is automatically defined, so long as the attribute exists at all

        -- Move the scrollbar to its proper position (only needed for subcategories)
        scrollFrame.ScrollBar:ClearPoint("RIGHT");
        scrollFrame.ScrollBar:SetPoint("RIGHT", -36, 0);

        scrollFrame.Content = settingsPanel;

        -- Create the nested subcategory
        subcategoryPanel = scrollFrame;
    else
        settingsPanel = CreateFrame("Frame", self:GetName() .. "-Tab" .. id);

        settingsPanel:SetID(id);

        subcategoryPanel = settingsPanel;
    end

    subcategoryPanel.name = text;
    subcategoryPanel.parent = app:GetName();

    local subcategory = Settings.RegisterCanvasLayoutSubcategory(mainCategory, subcategoryPanel, text)

    table.insert(self.Tabs, settingsPanel);

    return subcategoryPanel;
end

local f = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
f:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 12, -12);
f:SetJustifyH("LEFT");
f:SetText(L["TITLE"]);
f:SetScale(1.5);
f:Show();
settingsFrame.title = f;

f = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
f:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -12, -12);
f:SetJustifyH("RIGHT");
f:SetText("v" .. C_AddOns.GetAddOnMetadata(app:GetName(), "Version"));
f:Show();
settingsFrame.version = f;

app.Settings.Debug = {};

local Debug_Enabled_Checkbox = CreateFrame("CheckButton", "NyeBetterTurnOffGRepair_Debug_Enabled_Checkbox", settingsFrame, "InterfaceOptionsCheckButtonTemplate");
Debug_Enabled_Checkbox:SetPoint("TOPLEFT", settingsFrame.title, "BOTTOMLEFT", 0, -6);
Debug_Enabled_Checkbox.Text:SetText("Debug mode");
Debug_Enabled_Checkbox.Text:SetTextColor(1, 1, 1, 1);
Debug_Enabled_Checkbox:SetScript("OnClick", function(self, button, down)
    app.Settings:Set("Debug", "Enabled", self:GetChecked());
    app.CheckStatus();
end);
Debug_Enabled_Checkbox:Show();

app.Settings.Debug.EnabledCheckBox = Debug_Enabled_Checkbox;

local General_Label = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite");
General_Label:SetPoint("TOPLEFT", app.Settings.Debug.EnabledCheckBox, "BOTTOMLEFT", 0, -24);
General_Label:SetJustifyH("LEFT");
General_Label:SetTextColor(1, 0.82, 0, 1);
General_Label:SetText("General");
General_Label:Show();

app.Settings.Position = {};

local Position_XSlider = CreateFrame("Slider", "NyeBetterTurnOffGRepair-Settings-Position_XSlider", settingsFrame, "MinimalSliderTemplate");

Position_XSlider:SetPoint("TOPLEFT", General_Label, "BOTTOMLEFT", 0, -18);
Position_XSlider:SetPoint("RIGHT", settingsFrame, "RIGHT", -12, 0);
Position_XSlider:SetHeight(17);
Position_XSlider:SetMinMaxValues(-math.floor(GetScreenWidth()), math.ceil(GetScreenWidth()));
Position_XSlider:SetValueStep(1);
Position_XSlider:SetObeyStepOnDrag(true);

local Position_XSlider_Label = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite");
Position_XSlider_Label:SetPoint("CENTER", Position_XSlider, "CENTER", 0, 12);
Position_XSlider_Label:SetJustifyH("LEFT");
Position_XSlider_Label:SetText("Horizontal Position");
Position_XSlider_Label:Show();

local Position_XSlider_ValueLabel = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite");
Position_XSlider_ValueLabel:SetPoint("TOPLEFT", Position_XSlider, "BOTTOMLEFT", 0, 0);
Position_XSlider_ValueLabel:SetJustifyH("LEFT");
Position_XSlider_ValueLabel:SetText("0");
Position_XSlider_ValueLabel:Show();

Position_XSlider:SetScript("OnValueChanged", function(self, value, userInput)
    Position_XSlider_ValueLabel:SetText("" .. value);

    if userInput then
        app.Settings:Set("Position", "Horizontal", value);
        app:UpdateFramePosition();
    end
end)

app.Settings.Position.XSlider = Position_XSlider;

local Position_YSlider = CreateFrame("Slider", "NyeBetterTurnOffGRepair-Settings-Position_YSlider", settingsFrame, "MinimalSliderTemplate");

Position_YSlider:SetPoint("TOPLEFT", Position_XSlider, "BOTTOMLEFT", 0, -18);
Position_YSlider:SetPoint("RIGHT", settingsFrame, "RIGHT", -12, 0);
Position_YSlider:SetHeight(17);
Position_YSlider:SetMinMaxValues(-math.floor(GetScreenHeight()), math.ceil(GetScreenHeight()));
Position_YSlider:SetValueStep(1);
Position_YSlider:SetObeyStepOnDrag(true);

local Position_YSlider_Label = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite");
Position_YSlider_Label:SetPoint("CENTER", Position_YSlider, "CENTER", 0, 12);
Position_YSlider_Label:SetJustifyH("LEFT");
Position_YSlider_Label:SetText("Vertical Position");
Position_YSlider_Label:Show();

local Position_YSlider_ValueLabel = settingsFrame:CreateFontString(nil, "ARTWORK", "GameFontWhite");
Position_YSlider_ValueLabel:SetPoint("TOPLEFT", Position_YSlider, "BOTTOMLEFT", 0, 0);
Position_YSlider_ValueLabel:SetJustifyH("LEFT");
Position_YSlider_ValueLabel:SetText("0");
Position_YSlider_ValueLabel:Show();

Position_YSlider:SetScript("OnValueChanged", function(self, value, userInput)
    Position_YSlider_ValueLabel:SetText("" .. value);

    if userInput then
        app.Settings:Set("Position", "Vertical", value);
        app:UpdateFramePosition();
    end
end)

app.Settings.Position.YSlider = Position_YSlider;






