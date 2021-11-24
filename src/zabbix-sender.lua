local socket = require('socket')
local json do
    for _, mod in ipairs({'cjson', 'lunajson', 'dkjson'}) do
        local ok, j = pcall(require, mod)
        if ok then
            json = j
        end
    end

    assert(json, "Couldn't load any of the following JSON modules: cjson, lunajson, dkjson")
end

local zabbix_sender = {
    _VERSION      = '1.0.0-0',
    _DESCRIPTION  = 'A zabbix sender protocol implementation in Lua.',
    _URL          = 'https://git.kokolor.es/imo/lua-zabbix-sender',
    _LICENCE      = 'MIT'
}

-- protocol + flag
local ZHEAD_START = 'ZBXD\x01'

--- Privat functions

-- returns epoch and nanoseconds (I dunno how precise this is)
local function get_time()
    local time = socket.gettime()

    return math.floor(time), math.floor(( time % 1 ) * 10^9 )
end

-- set timestamp and nanoseconds if wanted
local function set_ts_and_ns(self, data)
    if self.timestamps then
        local ts, ns = get_time()
        data.clock = ts

        if self.nanoseconds then
            data.ns = ns
        end
    end
end

-- creates the payload as described in the docs
-- https://www.zabbix.com/documentation/5.0/manual/appendix/protocols/header_datalen
local function build_payload(self)
    local data = {
        request = 'sender data',
        data = self._items
    }
    set_ts_and_ns(self, data)
    self:clear()

    local jdata = json.encode(data)
    return string.format('%s%s%s', ZHEAD_START, string.pack('<L', jdata:len()), jdata)
end

-- parses the JSON response and returns only the data from then
-- info string
local function parse_response_data(resp)
    local resp_info = {}

    local ok, data = pcall(json.decode, resp)
    if not ok then
        return ok, data
    end

    data.info:gsub('(%w+):%s(%d+);', function(k, v)
        resp_info[k] = tonumber(v)
    end)

    return resp_info
end

local function receive_response(client)
    -- Note: maybe just use *a, because according to the docs the server
    -- closes the connection after it sent the status back
    local resp_head, err = client:receive(13)

    if not resp_head then
        client:close()
        return false, err
    elseif not resp_head:find('^' .. ZHEAD_START) or resp_head:len() ~= 13 then
        client:close()
        return false, 'Got invalid response from server'
    end

    local resp_data_len = string.unpack('<L', resp_head:sub(6))
    local resp_data = client:receive(resp_data_len)

    client:close()
    return parse_response_data(resp_data)
end


--- Main methods

local ZabbixSender = {}

function ZabbixSender:add_item(key, value, mhost)
    assert(key and value, 'Needs at least two arguments - key and value')
    mhost = mhost or self.monitored_host
    assert(mhost, 'No monitored host was given and no fallback was set')

    local item = {
        key = key,
        value = value,
        host = mhost
    }

    set_ts_and_ns(self, item)

    table.insert(self._items, item)

    return self
end

function ZabbixSender:add_items(items)
    assert(items and type(items) == 'table', 'Needs at least one argument - a table')

    for _, tbl in ipairs(items) do
        self:add_item(tbl[1], tbl[2], tbl[3])
    end

    return self
end

function ZabbixSender:clear()
    self._items = {}

    return self
end

function ZabbixSender:has_unsent_items()
    return #self._items ~= 0
end

function ZabbixSender:_connect()
    local client = self._socket()
    client:settimeout(self.timeout)

    local ok, err = client:connect(self.server, self.port)
    if not ok then
        client:close()
        return false, err
    end

    return client
end

function ZabbixSender:send()
    local items = self._items
    local data = build_payload(self)

    local client, err = self:_connect()
    if not client then
        self._items = items
        return client, err
    end

    local ok, err = client:send(data) -- luacheck: ignore 411/ok err
    if not ok then
        client:close()
        self._items = items
        return false, err
    end

    local resp, err = receive_response(client) -- luacheck: ignore 411/err
    if not resp then
        return resp, err
    end

    return resp
end


--- Public functions

function zabbix_sender.new(opts)
    opts = opts or {}
    local self = {
        server = opts.server or 'localhost',
        port = tonumber(opts.port) or 10051,
        monitored_host = opts.monitored_host,
        timestamps = opts.timestamps or opts.nanoseconds or false,
        nanoseconds = opts.nanoseconds or false,
        timeout = opts.timeout or 0.5,
        _socket = opts.socket or socket.tcp,
        _items = {}
    }

    return setmetatable(self, { __index = ZabbixSender })
end

return zabbix_sender
