DmtHelper = CreateFrame("Frame")

DmtHelper.enabled = false
DmtHelper.roster = {}
DmtHelper.line = {}
DmtHelper.ignore = {}

local function table_contains(table, key)
    for k, _ in pairs(table) do
        if key == k then
            return true
        end
    end
    return false
end

local function array_contains(array, value)
    for _, v in ipairs(array) do
        if value == v then
            return true
        end
    end
    return false
end

local function remove_by_value(array, value)
    local newarray = {}
    for _, v in ipairs(array) do
        if value ~= v then
            table.insert(newarray, v)
        end
    end
    return newarray
end

function DmtHelper:Print(msg)
    print("[DmtHelper] " .. msg)
end

function DmtHelper:SendChatMessage(msg)
    SendChatMessage("[DmtHelper] " .. msg, "RAID")
end

function DmtHelper:Init()
    self:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...)
    end)
    self:RegisterEvent("ADDON_LOADED")
end

function DmtHelper:ADDON_LOADED(name)
    if name == "DmtHelper" then
        self:OnAddonLoaded()
    end
end

function DmtHelper:GROUP_ROSTER_UPDATE()
    self:OnGroupRosterUpdate()
end

function DmtHelper:RegisterSlashCommand()
    SLASH_DMTHELPER1 = "/dmt"
    SlashCmdList["DMTHELPER"] = function(msg)
        local _, _, command, args = string.find(msg, "%s?(%w+)%s?(.*)")
        if command then
            self:OnSlashCommand(command, args)
        end
    end
end

function DmtHelper:OnSlashCommand(command, args)
    command = string.lower(command)
    if command == "on" then
        self:On()
    elseif command == "off" then
        self:Off()
    elseif command == "print" then
        self:PrintState()
    elseif command == "announce" then
        self:Announce()
    elseif command == "clear" then
        self:Clear()
    elseif command == "ignore" then
        self:Ignore(args)
    elseif command == "unignore" then
        self:Unignore(args)
    else
        self:Print("Unknown command.")
    end
end

function DmtHelper:On()
    self.enabled = true
    self:Clear()
    self:Update()
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
    self:Print("Enabled.")
end

function DmtHelper:Off()
    self.enabled = false
    self:UnregisterEvent("GROUP_ROSTER_UPDATE")
    self:Clear()
    self:Print("Disabled.")
end

function DmtHelper:PrintState()
    self:Print("------------------------------")
    self:Print("Enabled: " .. self.enabled)
    self:Print("Line:")
    for i, guid in ipairs(self.line) do
        self:Print("  " .. i .. "  " .. self.roster[guid])
    end
    self:Print("Ignore:")
    for _, guid in ipairs(self.ignore) do
        self:Print("  " .. self.roster[guid])
    end
    self:Print("------------------------------")
end

function DmtHelper:Announce()
    self:SendChatMessage("Line:")
    for i, guid in ipairs(self.line) do
        self:SendChatMessage("  " .. i .. "  " .. self.roster[guid])
    end
end

function DmtHelper:GetGuid(name)
    for guid, n in pairs(self.roster) do
        if name == n then
            return guid
        end
    end
    return nil
end

function DmtHelper:IsIgnored(guid)
    return array_contains(self.ignore, guid)
end

function DmtHelper:IsInRaid(guid)
    return table_contains(self.roster, guid)
end

function DmtHelper:Ignore(name)
    guid = self:GetGuid(name)
    if guid then
        table.insert(self.ignore, guid)
        self:Print("Ignoring " .. name)
    else
        self:Print(name .. " not found")
    end
    self:UpdateLine()
end

function DmtHelper:Unignore(name)
    guid = self:GetGuid(name)
    if guid then
        self.ignore = remove_by_value(self.ignore, guid)
        self:Print("Unignoring " .. name)
    else
        self:Print(name .. " not found")
    end
    self:UpdateLine()
end

function DmtHelper:OnAddonLoaded()
    self:RegisterSlashCommand()
    self:Print("Loaded.")
end

function DmtHelper:OnGroupRosterUpdate()
    self:Print("OnGroupRosterUpdate")
    self:Update()
    self:PrintState()
end

function DmtHelper:Update()
    self:UpdateGroupMembers()
    self:UpdateLine()
end

function DmtHelper:Clear()
    wipe(self.roster)
    wipe(self.line)
    wipe(self.ignore)
end

function DmtHelper:UpdateGroupMembers()
    if not IsInRaid() then
        self:Clear()
        return
    end
    local newroster = {}
    local n = GetNumGroupMembers()
    for i = 1, n do
        local unit = "raid" .. i
        local guid = UnitGUID(unit)
        local name, _ = UnitName(unit)
        if name and name ~= UNKNOWNOBJECT then
            newroster[guid] = name
        end
    end
    self.roster = newroster
end

function DmtHelper:UpdateLine()
    local newline = {}
    for _, guid in ipairs(self.line) do
        if not self:IsIgnored(guid) and self:IsInRaid(guid) then
            table.insert(newline, guid)
        end
    end
    for guid, _ in pairs(self.roster) do
        if not self:IsIgnored(guid) and not array_contains(newline, guid) then
            table.insert(newline, guid)
        end
    end
    self.line = newline
end

DmtHelper:Init()
