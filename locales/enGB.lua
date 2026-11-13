

if GetLocale() ~= "enGB" then
    return;
end

local _, app = ...;
local L = app.L;

for key, value in pairs({
    -- ["TITLE"] = "|cFFD13653 Nye Better Turn off Guild Repairs|r";
    -- ["DESCRIPTION"] = "or the guild will go broke. :c";
})
do L[key] = value; end
