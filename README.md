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
	var HBInst = new Heartbeat( { name: "FOO", identifier: "http://www.bar.biz:4223" } );
```

**Options** 

- **name** : *( `String` required )* The name of this current service group. E.g. "restservice"
- **identifier** : *( `String|Function` required )* The identifier of the current server. E.g. "http://api.myresthost.com:8080". If also possible to pass in a function that returnes the identifier.
- **intervalHeartbeat** : *( `Number` optional: default = `5` )* Min. interval time ( in seconds ) to send the heartbeat
- **heartbeatKey** : *( `String` optional: default = `HB` )* Redis key to write the heartbeat. This could be prefixed by `redisprefix`.
- **intervalMetrics** : *( `Number` optional: default = `60` )* Min. interval time ( in seconds ) to send the metrics. If set `<= 0` no metrics will be written
- **metricsKey** : *( `String` optional: default = `HB:METRICS` )* Redis key to write the machine/process metrics. If this is set to `null` no mertics will be written to redis. This could be prefixed by `redisprefix`.
- **metricCount** : *( `Number` optional: default = `5000` )* Metrics will be saved as redis list. The list will be trimed to this length.
- **metricExpire** : *( `Number` optional: default = `172800` 2 days )* Time in seconds until unused metrict will automatically removed. If set to `0` the key will never be removed
- **useRedisTime** : *( `Boolean` optional: default = `true` )* Use redis server time or us the own machine time
- **autostart** : *( `Boolean` optional: default = `true` )* Start the heartbeat on int. Otherwise you have to call the method `.start()` of your instance.
- **host** : *( `String` optional: default = `localhost` )* Redis host name
- **port** : *( `Number` optional: default = `6379` )* Redis port
- **options** : *( `Object` optional: default = `{}` )* Redis options
- **client** : *( `RedicClient` optional: default = `null` )* It also possible to pass in a already existing redis client instance. In this case the options `host`, `port` and `options` ar ignored.
- **redisprefix** : *( `String` optional: default = `{}` )* A general redis key prefix

## Methods

#### `.start()`

Start the heartbeat.

**Return**

*( Booelan )*: If it has been started. Could be `false` if the heartbeat has been already active

#### `.stop()`

Stop the heartbeat.

#### `.isActive()`

Ask if the heartbeat is currently active.

**Return**

*( Booelan )*: Haertbeat is active

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
|0.0.7|2015-04-27|updated dependencies|
|0.0.6|2015-04-27|added option `metricExpire` to autodelete unused metrics|
|0.0.5|2014-11-20|fixed redis key gen method and added ZSET for last active metrics|
|0.0.3|2014-11-19|added methods `.start()`, `.stop()` and `.isActive()` |
|0.0.2|2014-11-19|added autostart option|
|0.0.1|2014-11-18|Initial commit|

## Other projects

|Name|Description|
|:--|:--|
|[**systemhealth**](https://github.com/mpneuried/systemhealth)|Node module to run simple custom checks for your machine or it's connections. It will use [redis-heartbeat](https://github.com/mpneuried/redis-heartbeat) to send the current state to redis.|
|[**rsmq**](https://github.com/smrchy/rsmq)|A really simple message queue based on Redis|
|[**rsmq-cli**](https://github.com/mpneuried/rsmq-cli)|a terminal client for rsmq|
|[**rest-rsmq**](https://github.com/smrchy/rest-rsmq)|REST interface for.|
|[**redis-notifications**](https://github.com/mpneuried/redis-notifications)|A redis based notification engine. It implements the rsmq-worker to safely create notifications and recurring reports.|
|[**node-cache**](https://github.com/tcs-de/nodecache)|Simple and fast NodeJS internal caching. Node internal in memory cache like memcached.|
|[**redis-sessions**](https://github.com/smrchy/redis-sessions)|An advanced session store for NodeJS and Redis|
|[**obj-schema**](https://github.com/mpneuried/obj-schema)|Simple module to validate an object by a predefined schema|
|[**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions)|A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions). With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id.|
|[**task-queue-worker**](https://github.com/smrchy/task-queue-worker)|A powerful tool for background processing of tasks that are run by making standard http requests.|
|[**soyer**](https://github.com/mpneuried/soyer)|Soyer is small lib for serverside use of Google Closure Templates with node.js.|
|[**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)|Compile Goggle Closure Templates ( SOY ) templates inclding the handling of XLIFF language files.|
|[**backlunr**](https://github.com/mpneuried/backlunr)|A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js|

## The MIT License (MIT)

Copyright © 2013 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
