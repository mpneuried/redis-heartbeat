redis-heartbeat
===============

[![Build Status](https://secure.travis-ci.org/mpneuried/redis-heartbeat.png?branch=master)](http://travis-ci.org/mpneuried/redis-heartbeat)
[![Build Status](https://david-dm.org/mpneuried/redis-heartbeat.png)](https://david-dm.org/mpneuried/redis-heartbeat)
[![NPM version](https://badge.fury.io/js/redis-heartbeat.png)](http://badge.fury.io/js/redis-heartbeat)

Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.

*Written in coffee-script*

**INFO: all examples are written in coffee-script**

## Install

```
  npm install redis-heartbeat
```

## Initialize

```
	var Heartbeat = require( "redis-heartbeat" );
	new Heartbeat( { name: "FOO", identifier: "http://www.bar.biz:4223" } );
```

**Options** 

- **name** : *( `String` required )* The name of this current service group. E.g. "restservice"
- **identifier** : *( `String|Function` required )* The identifier of the current server. E.g. "http://api.myresthost.com:8080". If also possible to pass in a function that returnes the identifier.
- **intervalHeartbeat** : *( `Number` optional: default = `5` )* Min. interval time ( in seconds ) to send the heartbeat
- **heartbeatKey** : *( `String` optional: default = `HB` )* Redis key to write the heartbeat. This could be prefixed by `redisprefix`.
- **intervalMetrics** : *( `Number` optional: default = `60` )* Min. interval time ( in seconds ) to send the metrics. If set `<= 0` no metrics will be written
- **metricsKey** : *( `String` optional: default = `HB:METRICS` )* Redis key to write the machine/process metrics. If this is set to `null` no mertics will be written to redis. This could be prefixed by `redisprefix`.
- **metricCount** : *( `Number` optional: default = `5000` )* Metrics will be saved as redis list. The list will be trimed to this length.
- **useRedisTime** : *( `Boolean` optional: default = `true` )* Use redis server time or us the own machine time
- **host** : *( `String` optional: default = `localhost` )* Redis host name
- **port** : *( `Number` optional: default = `6379` )* Redis port
- **options** : *( `Object` optional: default = `{}` )* Redis options
- **client** : *( `RedicClient` optional: default = `null` )* It also possible to pass in a already existing redis client instance. In this case the options `host`, `port` and `options` ar ignored.
- **redisprefix** : *( `String` optional: default = `{}` )* A general redis key prefix

## Events

#### `started`

Emitted on start of the intervals

#### `beforeHeartbeat`

Emitted before heartbeat write.
With this event it's possible to change the heartbeat content in operation

**Arguments** 

- **identifier** : *( `String` )* The current identifier

#### `beforeMetric`

Emitted before metric write.
With this event it's possible to change the heartbeat content in operation

**Arguments** 

- **metric** : *( `Object` )* The current machine/process metrics
	- **metric.g_cpu** : *( `Number` )* The avarage machine cpu useage for the last minute in percent
	- **metric.g_mem** : *( `Number` )* The current machine memory useage in percent.
	- **metric.g_memtotal** : *( `Number` )* The current machine memory useage in bytes.
	- **metric.p_id** : *( `Number` )* The current process id.
	- **metric.p_uptime** : *( `Number` )* The current process uptime in seconds.
	- **metric.p_mem** : *( `Object` )* The current machine memory useage of the process.
		- **metric.p_mem.heapTotal** : *( `Number` )* The current total heap in bytes.
		- **metric.p_mem.heapUsed** : *( `Number` )* The current used heap in bytes.
		- **metric.p_mem.rss** : *( `Number` )* The current ram usage in bytes.

#### `connected`

Emitted on connection to redis

#### `disconnect`

Emitted on a disconnect of redis

#### `redis:error`

Emitted on general redis error

**Arguments** 

- **err** : *( `Error|String` )* The error details

## TODO 

* add free disk space to metrics
* add content tests

## Release History
|Version|Date|Description|
|:--:|:--:|:--|
|0.0.1|2014-11-18|Initial commit|

## The MIT License (MIT)

Copyright © 2013 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
