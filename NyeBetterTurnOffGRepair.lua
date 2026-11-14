
local app = select(2, ...);
local L = app.L;

--[[
 --
 -- General Utility stuff
 --
--]]

app.print = function(self, msg, ...)
    self:_print("", msg, ...);
end
app.log = function(self, msg, ...)
    if app.Data.Debug then
        self:_print("DEBUG ", msg, ...);
    end
end
app._print = function(self, prefix, msg, ...)
    local args = {...};
    local lines = { strsplit("\n", type(msg) == "string" and msg or tostring(msg)) };

    for _,line in ipairs(lines) do
        print(string.format("%s[%s]: %s", prefix, L["TITLE"], line));
    end

    if args and #args > 0 then
        self:_print(prefix, unpack(args));
    end
end
app.stringify = function(t)
    if type(t) == "table" then
        local text = "{ ";
        local first = true;

        for k,v in pairs(t) do
            if not first then
                text = text .. ", ";
            end

            first = false;
            text = text .. string.format("[%s] = %s", app.stringify(k), app.stringify(v));
        end

        text = text .. " }";

        return text;
    elseif type(t) == "boolean" then
        return t and "true" or "false"
    elseif type(t) == "number" then
        return "" .. t;
    elseif type(t) == "string" then
        return app.stringEscape(t);
    elseif type(t) == "function" then
        if debug then
            local info = debug.getinfo(t, "S");

            if info.what == "Lua" then
                local where, _ = info.source:gsub("(@)(.*" .. app:GetName() .. ")(.*)", "%1%3");

                return string.format("<function%s:%s>", where, info.linedefined);
            else
                return "<C function:?>";
            end
        else
            return "<function>";
        end
    elseif type(t) == "nil" then
        return "nil";
    end
end

app.stringEscape = function(str)
    return string.gsub(string.format("%q", str), "\n", "n");
end
app.stringTrim = function(str)
    return (string.gsub(str, "^%s*(.-)%s*$", "%1"));
end
app.eliminateEmptyStrings = function(list)
    local result = {};

    for i,s in ipairs(list) do
        if s ~= "" then
            table.insert(result, s);
        end
    end

    return result;
end

local createSlashCommand = (function()
    local function parseSlashCommandArgs(cmd)
        return app.eliminateEmptyStrings({ strsplit(" ", cmd) });
    end

    return function(func, id, ...)
        local slashes = { ... };
        if #slashes == 0 then
            return; -- cant create slash command without slashes
        end

        if type(id) ~= "string" or id == "" then
            return; -- need id that is a non-empty string
        end

        for i,slash in ipairs(slashes) do
            setglobal(string.format("SLASH_%s%d", id, i), slash);
        end
        _G.SlashCmdList[id] = function(cmd, msgBox)
            func(parseSlashCommandArgs(cmd), msgBox);
        end
    end
end)();

local grep_commandHandler = function(args)
    app.ToggleReminder();
end

app:RegisterEvent("ADDON_LOADED", "NyeBetterTurnOffGRepair", function(addon)
    if addon ~= app:GetName() then
        return;
    end

    app.Version = C_AddOns.GetAddOnMetadata(app:GetName(), "Version");

    app:UnregisterEvent("ADDON_LOADED", "NyeBetterTurnOffGRepair");

    app.ReminderText = UIParent:CreateFontString(nil, "OVERLAY");
    app.ReminderText:SetFont("Fonts/FRIZQT__.TTF", 36, "THICKOUTLINE");
    app.ReminderText:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
    app.ReminderText:SetTextColor(1, 1, 1);
    app.ReminderText:SetShadowColor(0, 0, 0);
    app.ReminderText:SetText("");
    app.ReminderText:Show();
    app.ReminderText:SetScript("OnMouseUp", function(self, button)
        if self:IsMouseOver() and button == "RightButton" then
            app.ToggleReminder();
        end
    end)

    app:RegisterEvent("GUILD_PARTY_STATE_UPDATED", "NyeBetterTurnOffGRepair", app.Events.GUILD_PARTY_STATE_UPDATED);
    app:RegisterEvent("PLAYER_ENTERING_WORLD", "NyeBetterTurnOffGRepair", app.Events.PLAYER_ENTERING_WORLD);
    app:RegisterEvent("GUILDBANK_UPDATE_WITHDRAWMONEY", "NyeBetterTurnOffGRepair", app.Events.GUILDBANK_UPDATE_WITHDRAWMONEY);

    createSlashCommand(grep_commandHandler, "NyeBetterTurnOffGRepair", "/grep", "/guildrep", "/guildrepair" );
end);

app.Data = {};

app.Data.Debug = false;

app.Data.GuildGroup = false;
app.Data.ValidInstance = false;
app.Data.AnyInstance = false;
app.Data.GuildRepair = false;

app.Data.ValidRaids = {
    -- 2912, -- The Voidspire
    -- 2939, -- The Dreamrift
    -- 2913, -- March on Quel'Danas
    -- 1592, -- Sporefall (???)

    2987, -- Tidebound Grotto
    3004, -- The Venomous Abyss
    3095, -- The Unbinding of Kith'ix
};
app.Data.OutsideInstances = {
    "none", -- when outside an instance
    -- "pvp", -- when in a battleground
    -- "arena", -- when in an arena
    -- "party", -- when in a 5-man instance (dungeon)
    -- "raid", -- when in a raid instance
    -- "scenario", -- when in a scenario
    "neighborhood", -- when in a housing neighborhood
    "interior", -- when inside a player house
};

app.Events = {};
app.Events.GUILD_PARTY_STATE_UPDATED = function(isInGuildGroup)
    app.CheckStatus();
end
app.Events.PLAYER_ENTERING_WORLD = function(isInitialLogin, isReloadingUi)
    app.CheckStatus();
end
app.Events.GUILDBANK_UPDATE_WITHDRAWMONEY = function(isInitialLogin, isReloadingUi)
    app.CheckStatus();
end

app.CheckInstanceStatus = function()
    local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, lfgDungeonID, hasWorldTier = GetInstanceInfo()

    local valid = instanceType == "raid" and table.contains(app.Data.ValidRaids, instanceID)
    app:log("Currently in " .. name .. " (" .. instanceID .. ") on difficulty " .. difficultyName .. " (" .. difficultyID .. "). Checking validity: " .. tostring(valid));

    local any = table.contains(app.Data.OutsideInstances, instanceType);

    app.Data.ValidInstance = valid;
    app.Data.AnyInstance = any;
end
app.CheckGuildGroupStatus = function()
    app.Data.GuildGroup = IsInGuildGroup();
    app:log("Currently in a guild group?: " .. tostring(app.Data.GuildGroup));
end
app.CheckGuildRepairStatus = function()
    -- TODO: Make guild rank for this query changeable
    app.Data.GuildRepair = C_GuildInfo.GuildControlGetRankFlags(6)[15]; -- CanGuildBankRepair()
    app:log("Currently guild repairs turned on?: " .. tostring(app.Data.GuildRepair));
end
app.SetReminder = function(text)
    app.ReminderText:SetText(text);
    app:log(text);
    -- TODO: Implement automatic clearing of the reminder after a certain time
end
app.ClearReminder = function()
    app.ReminderText:SetText("");
end
app.ToggleReminder = function()
    if app.ReminderText:IsShown() then
        app.ReminderText:Hide();
        app:print(L["REMINDER_HIDDEN"]);
    else
        app.ReminderText:Show();
    end
end

app.CheckStatus = function()
    app:log("Checking guild repair status:");

    app.CheckInstanceStatus();
    app.CheckGuildGroupStatus();
    app.CheckGuildRepairStatus();

    local showedReminder = false;

    if app.Data.GuildGroup and app.Data.ValidInstance and not app.Data.GuildRepair then
        app.SetReminder(L["REMINDER_TURNON"]);
        showedReminder = true;
    end

    if app.Data.GuildRepair and (not app.Data.ValidInstance or not app.Data.GuildGroup) then
        app.SetReminder(L["REMINDER_TURNOFF"]);
        showedReminder = true;
    end

    if not showedReminder then
        app.ClearReminder();
    end
end

