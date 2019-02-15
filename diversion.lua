local log = ngx.log
local ERR = ngx.ERR

local requestUri = ngx.var.uri
local uriList = global_configs["uriList"]

--log(ERR, "request uri is"..requestUri)
if not requestUri then
    return
end

if not uriList[requestUri] then
    return
end

if not global_configs["divEnable"] then
    return
end

--if global_configs["newTrafficRate"] <= 0 then
    --return
--end

local cjson = require('cjson')
ngx.req.read_body()
local bodyData = ngx.req.get_body_data()
if not bodyData then
    log(ERR, "ngx.req.get_body_data fail")
    return
end

local bodyArgs = cjson.decode(bodyData)

local function JSHash(str)
    local bit = require "bit"

    local lshift = bit.lshift
    local rshift = bit.rshift
    local bxor = bit.bxor

    local byte = string.byte
    local sub = string.sub
    local len = string.len
    local l = len(str)
    local h = l
    local step = rshift(l, 5) + 1

    for i=l,step,-step do
        h = bxor(h, (lshift(h, 5) + byte(sub(str, i, i)) + rshift(h, 2)))
    end

    return h
end

local uid = bodyArgs["uid"]
if uid and next(global_configs["uids"]) ~= nil then
  --log(ERR, "uid is:"..uid)
  for k,v in ipairs(global_configs["uids"]) do
    --log(ERR, "foreach global config uids:"..v..",type:"..type(v))
    if v == tostring(uid) then
      ngx.var.backend = "upstream_new"
      log(ERR, "set upstream new because uid:"..uid)
      return
    end
  end
end

local uuid = bodyArgs["uuid"]
if uuid then
  --log(ERR, "uuid:", bodyArgs["uuid"])
  local hashcode = JSHash(uuid)
  local remainder = hashcode % 1000
  if remainder and (remainder < global_configs["newTrafficRate"]) then
      log(ERR, "set upstream to upstream_new, uuid:"..uuid, ",newTrafficRate,"..global_configs["newTrafficRate"], ",hashcode:"..hashcode, ",remainder:"..remainder)
      ngx.var.backend = "upstream_new"
  end
end
