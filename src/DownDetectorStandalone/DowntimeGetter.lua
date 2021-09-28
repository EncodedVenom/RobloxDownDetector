local DowntimeGetter = {}

local HttpService = game:GetService("HttpService")
local sumurl = "https://raw.githubusercontent.com/Status-Plus/StatusPlus/master/history/summary.json" -- Respect to this person who made this

local function ReturnTableThroughSlug(slug, data)
	if data then
		for _, value in ipairs(data) do
			if value["slug"] == slug then
				return value
			end
            if string.find(value.slug, slug:gsub("-", "%%-")) then -- In case of weird things
                return value
            end
		end
	end
end

function DowntimeGetter.GetSiteStatus()
	return DowntimeGetter.GetStatusForSlug("roblox-site")
end

function DowntimeGetter.GetDevForumStatus()
	return DowntimeGetter.GetStatusForSlug("roblox-devforum")
end

function DowntimeGetter.GetDevHubStatus()
	return DowntimeGetter.GetStatusForSlug("roblox-devhub")
end

function DowntimeGetter.GetAvatarAPIStatus()
	return DowntimeGetter.GetStatusForSlug("avatar-api-endpoint")
end

function DowntimeGetter.GetBadgesAPIStatus()
	return DowntimeGetter.GetStatusForSlug("badges-api-endpoint")
end

function DowntimeGetter.GetCDNAPIStatus()
	return DowntimeGetter.GetStatusForSlug("cdn-api-endpoint")
end

function DowntimeGetter.GetCatalogAPIStatus()
	return DowntimeGetter.GetStatusForSlug("catalog-api-endpoint")
end

function DowntimeGetter.GetDatastoreAPIStatus()
	return DowntimeGetter.GetStatusForSlug("datastore-api-endpoint")
end

function DowntimeGetter.GetDevelopAPIStatus()
	return DowntimeGetter.GetStatusForSlug("develop-api-endpoint")
end

function DowntimeGetter.GetFriendsAPIStatus()
	return DowntimeGetter.GetStatusForSlug("friends-api-endpoint")
end

function DowntimeGetter.GetGameJoinAPIStatus()
	return DowntimeGetter.GetStatusForSlug("game-join-api-endpoint")
end

function DowntimeGetter.GetGroupsAPIStatus()
	return DowntimeGetter.GetStatusForSlug("groups-api-endpoint")
end

function DowntimeGetter.GetInventoryAPIStatus()
	return DowntimeGetter.GetStatusForSlug("inventory-api-endpoint")
end

function DowntimeGetter.GetTextFilterAPIStatus()
    return DowntimeGetter.GetStatusForSlug("text-filter-api-endpoint")
end

function DowntimeGetter.GetThumbnailsAPIStatus()
    return DowntimeGetter.GetStatusForSlug("thumbnails-api-endpoint")
end

function DowntimeGetter.GetStatusForSlug(slug)
    local GetStatus = HttpService:GetAsync(sumurl)

	local Data = HttpService:JSONDecode(GetStatus)
	local Table = ReturnTableThroughSlug(slug, Data)

    if not Table then warn(slug.." does not have a table!") return "DOWN" end

	return Table.status:upper() -- Will return "UP", "DEGRADED" or "DOWN"
end

return DowntimeGetter
