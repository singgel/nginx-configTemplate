local start_delay = 10
local new_timer = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR
local refresh
local get_redis
local close_redis

local switch_key = "abtest:switch:global"
local traffic_key = "abtest:limit:traffic"
local uids = "abtest:limit:uids"

get_redis = function()
  local redis = require "resty.redis"
  local red = redis:new()
  local ok, err = red:connect(global_configs['redis']['ap_host'],global_configs['redis']['ap_port'])
  return red, ok, err
end

close_redis = function(red)
    if not red then
        return
    end
    local ok, err = red:close()
    if not ok then
        ngx.log(ngx.ERR,"fail to close redis connection : ", err)
    end
end

local function stringSplit(input, delimiter)
   local input = tostring(input)
   local delimiter = tostring(delimiter)
   if (delimiter=='') then return false end
   local pos = 0
   local arr = {}
   for st,sp in function() return string.find(input, delimiter, pos, true) end do
     table.insert(arr, string.sub(input, pos, st - 1))
     pos = sp + 1
   end
   table.insert(arr, string.sub(input, pos))
   return arr
end

local function do_refresh()
    local red, ok, err = get_redis()

    if not ok then
        log(ERR, "redis is not ready!")
        return
    end

    local enable, err = red:get(switch_key)
    if err then
        log(ERR, err)
    else
        if ngx.null ~= enable then
            global_configs["divEnable"] = ("true" == enable) and true or false
            log(ERR, "update divEnable: ", global_configs["divEnable"])
        end
    end

    local trafficLimitStr, err = red:get(traffic_key)
    if err then
        log(ERR, err)
    else
        log(ERR, "redis not set")
        if ngx.null ~= trafficLimitStr and tonumber(trafficLimitStr) >= 0  then
            global_configs["newTrafficRate"] = tonumber(trafficLimitStr)
            log(ERR, "update newTrafficRate: ", global_configs["newTrafficRate"])
        end
    end

    local uids, err = red:get(uids)
    if err then
        log(ERR, err)
    else
        if ngx.null ~= uids then
            local redisUids = stringSplit(uids, ",")
            if next(redisUids) ~= nil then 
                 global_configs["uids"] = redisUids 
                 log(ERR, "update uids:", uids);
		 --for k,v in ipairs(global_configs["uids"]) do
                    --log(ERR, "update uids: ", v)
                 --end
            end
        end
    end

    return close_redis(red)
end

refresh = function(premature)
    if not premature then
        do_refresh()

        local ok, e = new_timer(start_delay, refresh)
        if not ok then
            log(ERR, "failed to create timer: ", e)
            return
        end
    end
end


local ok, e = new_timer(start_delay, refresh)
if not ok then
    log(ERR, "failed to create timer: ", e)
    return
end
