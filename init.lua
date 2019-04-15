--- === ReloadConfiguration ===
---
--- Fetch air quality from aqicn and display it in the menubar.
--- Download: 



local obj={}
obj.__index = obj

-- Metadata
obj.name = "Aqicn"
obj.version = "0.1"
obj.author = "holsety <hoooooosety@gmail.com>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.menubar = nil
obj.menudata = {}
obj.menutitle = "😷"

obj.location = "shanghai"
obj.token = nil

local aqiEmoji = {
    {threshold = 50, emoj = '🍀'},
    {threshold = 100, emoj = '☘️'},
    {threshold = 999, emoj = '😷'},
}

local function updateMenubar()
    if obj.menubar == nil then
        print("Won't update to a nil menubar")
    else
        obj.menubar:setTooltip("Air quality")
        obj.menubar:setMenu(obj.menudata)
        obj.menubar:setTitle(obj.menutitle)
    end
end

local function parseResponse(data)
    obj.menudata = {}
    
    table.insert(obj.menudata, {title = string.format("%s - %s", obj.location, data.time.s)})
    table.insert(obj.menudata, {title = '-'})

    for k, v in pairs(data.iaqi) do
        titlestr = string.format("%s: %s", k, v.v)
        row = { title = titlestr }
        table.insert(obj.menudata, row)
    end

    for index, emoj in pairs(aqiEmoji) do
        if data.aqi < emoj.threshold then
            obj.menutitle = emoj.emoj
            break
        end
    end
end

local function aqicnRequest()
    local userAgentStr = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4"
    local jsonReqUrl = string.format("http://api.waqi.info/feed/%s/?token=%s", obj.location, obj.token)
    hs.http.asyncGet(jsonReqUrl, {["User-Agent"]=userAgentStr}, function(stat,body,header)
        if stat == 200 then
            if pcall(function() hs.json.decode(body) end) then
                local decodeData = hs.json.decode(body)
                parseResponse(decodeData.data)
                updateMenubar()
            else
                print("aqicn parse fail")
            end
        else
            print("aqicn request fail")
        end
    end)
end

--- Aqicn:setLocation(location)
--- Method
--- The location of air quality to monitor
---
--- Parameters:
---  * location - A string of the city, e.g. shanghai
function obj:setLocation(location)
    obj.location = location
end

--- Aqicn:setToken(token)
--- Method
--- The token to call the aqicn.org API. 
--- Get your own token here - http://aqicn.org/data-platform/token/#/
---
--- Parameters:
---  * token - A string of token
function obj:setToken(token)
    obj.token = token
end

function obj:start()
    if obj.menubar == nil then
        obj.menubar = hs.menubar.new()
        updateMenubar()
    end
    if obj.timer == nil then
        obj.timer = hs.timer.doEvery(60*60, aqicnRequest)
        obj.timer:setNextTrigger(5)
    else
        obj.timer:start()
    end
end

return obj
