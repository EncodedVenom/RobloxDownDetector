--[[
    local DownDetector = require(path.To.DownDetector)

    -- I would use the getter functions instead of this, but for those who like it better.
    DownDetector.Signals: Map<APIName, Signal>
    DownDetector.Values: Map<APIName, Value>

    DownDetector.Getter: DowntimeGetter

    DowntimeGetter:
        function DowntimeGetter.GetSiteStatus(): string
        function DowntimeGetter.GetDevForumStatus(): string
        function DowntimeGetter.GetDevHubStatus(): string
        function DowntimeGetter.GetAvatarAPIStatus(): string
        function DowntimeGetter.GetBadgesAPIStatus(): string
        function DowntimeGetter.GetCDNAPIStatus(): string
        function DowntimeGetter.GetCatalogAPIStatus(): string
        function DowntimeGetter.GetDatastoreAPIStatus(): string
        function DowntimeGetter.GetDevelopAPIStatus(): string
        function DowntimeGetter.GetFriendsAPIStatus(): string
        function DowntimeGetter.GetGameJoinAPIStatus(): string
        function DowntimeGetter.GetGroupsAPIStatus(): string
        function DowntimeGetter.GetInventoryAPIStatus(): string
        function DowntimeGetter.GetTextFilterAPIStatus(): string
        function DowntimeGetter.GetThumbnailsAPIStatus(): string
        function DowntimeGetter.GetStatusForSlug(slug: string): string

    function DownDetector.StringifyEnum(input: Enum<Response>): string
    function DownDetector.GetStateChangedSignal(APIName: string): Signal
    function DownDetector.GetStateCurrentValue(APIName: string): Enum<Response>
    function DownDetector.GetStringifiedCurrentValue(APIName: string): string
]]

local DownDetector = {}

local Knit = require(game:GetService("ReplicatedStorage").Knit)
local Signal = require(Knit.Util.Signal)
local Timer = require(Knit.Util.Timer)
local EnumList = require(Knit.Util.EnumList)

local DowntimeGetter = require(script:WaitForChild("DowntimeGetter")) -- Just in case you call this on the client. Don't know why.

DownDetector.Getter = DowntimeGetter
DownDetector.Response = EnumList.new("Response", {"UP", "DEGRADED", "DOWN"})
DownDetector.ModuleTimer = Timer.new(300)

DownDetector.Signals = {}
DownDetector.Values = {}

local STATUS_CHANGE_WARNING = "[STATUS CHANGED] %s Status: %s (from %s)"
local SIMPLIFY_API_NAMES_ON_WARN = true

local API_LIST = {
    "roblox-site",
    "roblox-devforum",
    "roblox-devhub",
    "avatar-api-endpoint",
    "badges-api-endpoint",
    "cdn-api-endpoint",
    "catalog-api-endpoint",
    "datastore-api-endpoint",
    "develop-api-endpoint",
    "friends-api-endpoint",
    "game-join-api-endpoint",
    "groups-api-endpoint",
    "inventory-api-endpoint",
    "text-filter-api-endpoint",
    "thumbnails-api-endpoint"
}

local STRINGIFIED_API_LIST = { --1st is long name, 2nd is short name.
    {"Roblox Site", "Roblox"},
    {"Roblox Devforum", "Devforum"},
    {"Roblox Devhub", "Devhub"},
    {"Avatar API Endpoint", "Avatar"},
    {"Badges API Endpoint", "Badge"},
    {"CDN API Endpoint", "CDN"},
    {"Catalog API Endpoint", "Catalog"},
    {"Datastore API Endpoint", "Datastore"},
    {"Develop API Endpoint", "Develop"},
    {"Friends API Endpoint", "Friend"},
    {"Game Join API Endpoint", "Game Join"},
    {"Groups API Endpoint", "Group"},
    {"Inventory API Endpoint", "Inventory"},
    {"Text Filter API Endpoint", "Text Filter"},
    {"Thumbnails API Endpoint", "Thumbnail"}
}

local function ConvertStringToEnum(input: string)
    if input == "UP" then
        return DownDetector.Response.UP
    elseif input == "DEGRADED" then
        return DownDetector.Response.DEGRADED
    elseif input == "DOWN" then
        return DownDetector.Response.DOWN
    else
        error("Invalid response: "..input)
    end
end

local function ConvertEnumToString(input): string
    assert(DownDetector.Response:Is(input), "Must be an Enum<Response> value")
    if input == DownDetector.Response.UP then
        return "UP"
    elseif input == DownDetector.Response.DEGRADED then
        return "DEGRADED"
    elseif input == DownDetector.Response.DOWN then
        return "DOWN"
    else
        error("Invalid input: "..input)
        return "null"
    end
end

local function StringifyAPI(input, simple: boolean?): string
    local position = table.find(API_LIST, input)
    if not position then return "null" end
    if simple then
        return STRINGIFIED_API_LIST[position][2]
    else
        return STRINGIFIED_API_LIST[position][1]
    end
end

DownDetector.StringifyEnum = ConvertEnumToString

local done = 0
for _, name in pairs(API_LIST) do
    DownDetector.Signals[name] = Signal.new()
    DownDetector.Signals[name]:Connect(function(newValue)
        DownDetector.Values[name] = newValue
    end)
    task.spawn(function()
        DownDetector.Values[name] = ConvertStringToEnum(DowntimeGetter.GetStatusForSlug(name)) -- May take a bit.
        done += 1
    end)
end

repeat task.wait(1) until done == #API_LIST

local baseForStringResponse = "\tAPI \"%s\" (%s): %s" -- API "roblox-site" (Roblox): UP
local listOfResponses = {}
for index, slug in pairs(API_LIST) do
    table.insert(listOfResponses, baseForStringResponse:format(slug, StringifyAPI(slug, SIMPLIFY_API_NAMES_ON_WARN), ConvertEnumToString(DownDetector.Values[slug])))
end
warn("Roblox API Status: \n".. table.concat(listOfResponses, "\n"))

local function UpdateSpecific(slug)
    local result = ConvertStringToEnum(DowntimeGetter.GetStatusForSlug(slug))
    local previousResult = DownDetector.Values[slug]
    if previousResult ~= result then
        DownDetector.Signals[slug]:Fire(result)
        if previousResult then -- Do not warn for values changing from null to something
            warn(STATUS_CHANGE_WARNING:format(StringifyAPI(slug, SIMPLIFY_API_NAMES_ON_WARN), ConvertEnumToString(result), ConvertEnumToString(previousResult)))
        end
    end
end

local function Update()
    for _, slug in pairs(API_LIST) do
        task.spawn(UpdateSpecific, slug)
    end
end

DownDetector.ModuleTimer.Tick:Connect(Update)
DownDetector.ModuleTimer:Start()

function DownDetector.GetStateChangedSignal(APIName)
    return DownDetector.Signals[APIName]
end

function DownDetector.GetStateCurrentValue(APIName)
    return DownDetector.Values[APIName]
end

function DownDetector.GetStringifiedCurrentValue(APIName)
    return ConvertEnumToString(DownDetector.GetStateCurrentValue(APIName))
end

return DownDetector