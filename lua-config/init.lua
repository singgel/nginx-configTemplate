global_configs = {
  ["divEnable"] = false,  -- 分流开关，true表示开启
  ["newTrafficRate"] = 100,  -- 分流比例，0-1000， 1000表示全部流量，100%
  ["redis"] = {
    ap_host='192.168.1.43',  -- redis主机ip或者是host
    ap_port=6379            -- redis主机端口
  },
  ["uids"] = {},
  ["uriList"] = {
    ["/rc/v1/infomation"] = 1,
    ["/rc/v1/test"] = 1,
    ["/rcrc/v1/mediaNews"] = 1,
    ["/rc/v1/smallvideo"] = 1,
    ["/rc/v1/video"] = 1,
  }
}
