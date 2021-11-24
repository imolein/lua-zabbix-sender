# lua-zabbix-sender

A zabbix sender protocol implementation in Lua, for pushing monitoring data to Zabbix trapper items directly from your Lua code.

## Warning

I am not a programmer, so here’s a warning: **This code was written in an exploratory way**. If you encounter problems, see something wrong or something was implemented in a weird way, I would be happy if you tell me about it or create a pull request. Thank you. :)

## Example

```lua
local inspect = require('inspect')
local zbx_sender = require('zabbix-sender')
local sender = zbx_sender.new({
    server = 'localhost',
    port = 10051,
    monitored_host = 'node01'
  })

local resp = sender:add_item('trap1', 'test1')
  :add_item('trap2', 'test2')
  :add_item('trap1', 'test1', 'node02')
  :send()

print(inspect(resp))

{
  failed = 0,
  processed = 3,
  total = 3
}
```

```lua
local socket = require('socket')
local copas = require('copas')
local zbx_sender = require('zabbix-sender')

local sender = zbx_sender.new({
    server = 'localhost',
    port = 10051,
    monitored_host = 'node01',
    socket = function() return copas.wrap(socket.tcp()) end
  })

copas.addthread(function()
  sender:add_item('trap1', 'test1')
    :add_item('trap2', 'test2')

  copas.sleep(1)

  sender:add_item('trap1', 'test1', 'node02')
end)

copas.addthread(function()
  while sender:has_unsent_items() do
    sender:send()
    copas.sleep(2)
  end
end)

copas.loop()
```

## Documentation

* [Dependencies](#dependencies)
* [Functions](#functions)
   * [new](#newopts)
* [Methods](#methods)
   * [add_item](#add_itemkey-value-mhost)
   * [add_items](#add_itemsitems)
   * [clear](#clear)
   * [has_unsent_items](#has-unsent-items)
   * [send](#send)

## Dependencies

* lua >=5.1
* [luasocket](https://github.com/diegonehab/luasocket)
* [cjson](https://github.com/openresty/lua-cjson), [lunajson](https://github.com/grafi-tt/lunajson) or [dkjson](http://dkolf.de/src/dkjson-lua.fsl/home)
* [copas](https://github.com/keplerproject/copas) >=3.0.0 (**optional**)


## Functions

### `new([opts])`

Creates a new zabbix sender.

**Parameter:**

* *opts*: (**table**) options (**opt**)
* *opts.server*: (**string**) Zabbix server URL/IP (**default**=`localhost`)
* *opts.port*: (**number**) Zabbix server port (**default**=`10051`)
* *opts.monitored_host*: (**string**) The hostname the items belongs to. (**default**=`nil`)
* *opts.timestamps*: (**boolean**) Whether or not add timestamps to items - if `opts.nanoseconds` is set to `true` `opts.timestamps` is set to `true` too (**default**=`false`)
* *opts.nanoseconds*: (**boolean**) Whether or not add nanoseconds to items (**default**=`false`)
* *opts.timeout*: (**number**) connection timeout (**default**=`0.5`)
* *opts.socket*: (**function**) a function which returns a [LuaSocket TCP master object](https://w3.impa.br/~diego/software/luasocket/tcp.html). For example this can be used to wrap the socket with **copas**. (**default**=`socket.tcp`)

**Returns:**

(**table**) zabbix sender

## Methods

### `add_item(key, value[, mhost])`

Adds an item to the request payload. The item(s) are stored until `send()` is invoked. Multiple calls to `add_item()` can be chained and completed by a final call to `send()`. See example above.

**Parameter:**

* *key*: (**string**) the items key
* *value*: (**string** | **number**) the items value
* *mhost*: (**string**) Is needed if [monitored_host](#newopts) was not set at creation or if the monitoring data is ment for another host.

**Returns:**

(**table**) self

**Raises:**

1. Error if `key` or `value` is missing
2. Error if `host` is missing and `monitored_host` was not set

### `add_items(items)`

Adds multiple items from a given table. The `items` table is an array of tables in the format of:

```lua
{
  { 'key1', 'val1', 'host1' },
  { 'key2', 'val2', 'host2' },
  ...
}
```

**Parameter:**

* *items*: (**table**) 

**Returns:**

(**table**) self

**Raises:**

1. Error if `items` is not given or not a `table`

### `clear()`

Removes all unsent items.

**Returns:**

(**self**)

### `has_unsent_items()`

Returns if there are unsent items and the number of unset items.

**Returns:**

1. (**boolean**)

### `send()`

Sends all added items.

**Returns:**

1. (**table** | **false**) response from server | `false` in case of error
2. (**string**) error message in case of error
