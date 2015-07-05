ShadowSocks
===========

A ShadowSocks server implemented in Elixir

This is only a server. You still need a [client](https://github.com/shadowsocks/shadowsocks/wiki/Ports-and-Clients)


Usage
-----

Simple run:

```
$ mix run --no-halt

# or in console
$ iex -S mix
```

Make a package:

```
$ mix deps.get
$ MIX_ENV=prod mix release
$ cp rel/shadowsocks
$ bin/shadowsocks start
```

See also: [exrm](https://github.com/bitwalker/exrm#deployment)


Configuration
-------------

Config   | Name        | Default value
-------- | ----------- | -------------
port     | SHADOW_PORT | 8388
password | SHADOW_PASS | "password"

You can do config while:

```
# releasing
$ SHADOW_PORT=8388 MIX_ENV=prod mix release

# or running
$ SHADOW_PASS=mypass bin/shadowsocks start
```


Limitation
----------

- The only encryption method supported is `aes_cfb`, the default method is `aes-128-cfb`
- Only support TCP (for now)


TODO
----

- [ ] Make encryption as protocol
- [ ] Add more encryption methods
- [ ] Support UDP
