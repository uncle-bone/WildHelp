-- WildHelp: clean-room shared service board foundation.
-- No third-party source has been copied into this build.
local ADDON, WH = ...
WH = WH or {}
_G.WildHelp = WH

local PREFIX = "WHLP"
local PROTOCOL = "1"
local MAX_ROWS = 100
local MAX_TEXT = 100
local EXPIRE_SECONDS = 7 * 24 * 60 * 60
local db
local window
local rowsFrame
local statusLine
local categoryBox
local descriptionBox
local lastSend = 0

local function now() return time and time() or 0 end
local function clean(s, limit)
  s = tostring(s or "")
  s = s:gsub("[|\r\n]", " "):gsub("%c", " "):gsub("%s+", " ")
  s = s:match("^%s*(.-)%s*$") or ""
  if #s > limit then s = s:sub(1, limit) end
  return s
end
local function say(msg)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff7fdfffWildHelp:|r " .. tostring(msg)) end
end
local function localPlayer()
  local name, realm = UnitName("player")
  if not name then return "Player" end
  if realm and realm ~= "" then return name .. "-" .. realm end
  return name
end
local function location()
  local zone = GetRealZoneText and GetRealZoneText() or "Unknown"
  return clean(zone, 40)
end
local function scopeLabel(scope)
  if scope == "GUILD" then return "Guild" end
  if scope == "PARTY" or scope == "RAID" then return "Group" end
  return "Local"
end
local function sortedRows()
  local list = {}
  for _, row in pairs(db.listings) do list[#list + 1] = row end
  table.sort(list, function(a, b) return (a.updated or 0) > (b.updated or 0) end)
  return list
end
local function refresh()
  if not rowsFrame then return end
  for _, child in ipairs({ rowsFrame:GetChildren() }) do child:Hide(); child:SetParent(nil) end
  local rows = sortedRows()
  local y = -4
  for i = 1, #rows do
    local row = rows[i]
    local line = rowsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    line:SetPoint("TOPLEFT", 4, y)
    line:SetWidth(510)
    line:SetJustifyH("LEFT")
    local age = math.max(0, now() - (row.updated or now()))
    local ageText = age < 60 and "just now" or (math.floor(age / 60) .. "m ago")
    line:SetText(string.format("|cffd8b36a[%s]|r %s  |cffaaaaaa- %s � %s � %s|r", row.category or "Service", row.text or "", row.author or "?", row.source or "Local", ageText))
    y = y - 28
  end
  if #rows == 0 then
    local empty = rowsFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    empty:SetPoint("TOPLEFT", 4, -8)
    empty:SetText("No listings yet. Add one below, then share it with your guild or current group.")
  end
end
local function makeButton(parent, label, x, y, width, callback)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width, 24); b:SetPoint("TOPLEFT", x, y); b:SetText(label); b:SetScript("OnClick", callback)
  return b
end
local function createListing()
  local category = clean(categoryBox:GetText(), 20)
  local text = clean(descriptionBox:GetText(), MAX_TEXT)
  if category == "" or text == "" then say("enter a category and description first."); return end
  local id = tostring(now()) .. "-" .. tostring(math.random(1000, 9999))
  db.listings[id] = { id = id, category = category, text = text, author = localPlayer(), source = "Local", scope = "Local", updated = now(), zone = location() }
  db.mine = id
  categoryBox:SetText(""); descriptionBox:SetText("")
  refresh(); say("listing saved locally. Use Share Guild or Share Group to send it to addon users in that scope.")
end
local function sendTo(scope)
  if not db.mine or not db.listings[db.mine] then say("create a listing first."); return end
  if not C_ChatInfo or not C_ChatInfo.SendAddonMessage then say("this client does not expose C_ChatInfo.SendAddonMessage; network sharing is unavailable."); return end
  if now() - lastSend < 2 then say("please wait before sharing again."); return end
  local row = db.listings[db.mine]
  local msg = table.concat({ PROTOCOL, "L", clean(row.category, 20), clean(row.text, 80), clean(row.zone, 30), tostring(now()) }, "|")
  if #msg > 230 then say("listing is too long to share; shorten its text."); return end
  if scope == "GUILD" then
    if not IsInGuild or not IsInGuild() then say("you are not in a guild."); return end
    C_ChatInfo.SendAddonMessage(PREFIX, msg, "GUILD")
  elseif scope == "GROUP" then
    local channel
    if IsInRaid and IsInRaid() then channel = "RAID"
    elseif IsInGroup and IsInGroup() then channel = "PARTY" end
    if not channel then say("you are not in a party or raid."); return end
    C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
  end
  lastSend = now()
  say("shared with addon users in your " .. scopeLabel(scope):lower() .. " channel. This is not realm-wide or cross-layer.")
end
local function onAddonMessage(_, event, prefix, message, channel, sender)
  if prefix ~= PREFIX or type(message) ~= "string" or #message > 230 then return end
  local version, kind, category, text, zone, sent = strsplit("|", message)
  if version ~= PROTOCOL or kind ~= "L" then return end
  category, text, zone = clean(category, 20), clean(text, 80), clean(zone, 30)
  if category == "" or text == "" or not sender or sender == localPlayer() then return end
  local stamp = tonumber(sent) or now()
  local id = clean(sender, 60) .. "-" .. tostring(stamp)
  db.listings[id] = { id = id, category = category, text = text, author = clean(sender, 60), source = "Addon user", scope = scopeLabel(channel), updated = now(), zone = zone }
  refresh()
end
local function openWindow()
  if window then window:SetShown(not window:IsShown()); if window:IsShown() then refresh() end; return end
  window = CreateFrame("Frame", "WildHelpWindow", UIParent, "BasicFrameTemplateWithInset")
  window:SetSize(560, 470); window:SetPoint("CENTER"); window:SetMovable(true); window:EnableMouse(true); window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", window.StartMoving); window:SetScript("OnDragStop", window.StopMovingOrSizing)
  window.TitleText:SetText("WildHelp - Player Services")
  local hint = window:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", 16, -34); hint:SetWidth(525); hint:SetJustifyH("LEFT")
  hint:SetText("Listings are local until you choose to share. Scope is guild or current party/raid; no public chat scanning.")
  local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 16, -60); scroll:SetPoint("BOTTOMRIGHT", -34, 125)
  rowsFrame = CreateFrame("Frame", nil, scroll); rowsFrame:SetSize(500, 1); scroll:SetScrollChild(rowsFrame)
  local label = window:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  label:SetPoint("BOTTOMLEFT", 18, 102); label:SetText("New listing")
  categoryBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
  categoryBox:SetSize(130, 26); categoryBox:SetPoint("BOTTOMLEFT", 24, 70); categoryBox:SetAutoFocus(false); categoryBox:SetMaxLetters(20); categoryBox:SetText("Service")
  descriptionBox = CreateFrame("EditBox", nil, window, "InputBoxTemplate")
  descriptionBox:SetSize(360, 26); descriptionBox:SetPoint("LEFT", categoryBox, "RIGHT", 8, 0); descriptionBox:SetAutoFocus(false); descriptionBox:SetMaxLetters(MAX_TEXT)
  descriptionBox:SetScript("OnEnterPressed", function(self) self:ClearFocus(); createListing() end)
  makeButton(window, "Save Local", 22, 34, 105, createListing)
  makeButton(window, "Share Guild", 138, 34, 120, function() sendTo("GUILD") end)
  makeButton(window, "Share Group", 269, 34, 120, function() sendTo("GROUP") end)
  makeButton(window, "Refresh", 400, 34, 105, refresh)
  statusLine = window:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  statusLine:SetPoint("BOTTOMLEFT", 18, 12); statusLine:SetText("Wildcard networking is limited to guild and current group messages.")
  refresh()
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, name, ...)
  if event == "ADDON_LOADED" and name == ADDON then
    if type(WildHelpDB) ~= "table" then WildHelpDB = {} end
    db = WildHelpDB
    db.listings = type(db.listings) == "table" and db.listings or {}
    db.version = 1
    for id, row in pairs(db.listings) do
      if type(row) ~= "table" or (now() - (tonumber(row.updated) or 0) > EXPIRE_SECONDS) then db.listings[id] = nil end
    end
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(PREFIX) end
    self:RegisterEvent("CHAT_MSG_ADDON")
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
      self:SetScript("OnEvent", function(frame, ev, ...)
        if ev == "CHAT_MSG_ADDON" then onAddonMessage(frame, ev, ...) end
      end)
    end
    SLASH_WILDHELP1 = "/wildhelp"; SLASH_WILDHELP2 = "/wh"
    SlashCmdList.WILDHELP = function() openWindow() end
    self:UnregisterEvent("ADDON_LOADED")
    say("loaded. Type /wh to open the service board.")
  end
end)
