redis-heartbeat
===============

[![Build Status](https://secure.travis-ci.org/mpneuried/redis-heartbeat.png?branch=master)](http://travis-ci.org/mpneuried/redis-heartbeat)
[![Windows Tests](https://img.shields.io/appveyor/ci/mpneuried/redis-heartbeat.svg?label=WindowsTest)](https://ci.appveyor.com/project/mpneuried/redis-heartbeat)
[![Coveralls Coverage](https://img.shields.io/coveralls/mpneuried/redis-heartbeat.svg)](https://coveralls.io/github/mpneuried/redis-heartbeat)

[![Deps Status](https://david-dm.org/mpneuried/redis-heartbeat.png)](https://david-dm.org/mpneuried/redis-heartbeat)
[![npm version](https://badge.fury.io/js/redis-heartbeat.png)](http://badge.fury.io/js/redis-heartbeat)
[![npm downloads](https://img.shields.io/npm/dt/redis-heartbeat.svg?maxAge=2592000)](https://nodei.co/npm/redis-heartbeat/)

Pulse a heartbeat to redis. This can be used to detach or attach servers to nginx or similar problems.

## Breaking changes

**Version `1.0.0`** Since this version th emetrics are removed, to be able to install it for node 10.

## Install

```
  npm install redis-heartbeat
```

## Initialize

```js
	var Heartbeat = require( "redis-heartbeat" );
	var HBInst = new Heartbeat( { name: "FOO", identifier: "http://www.bar.biz:4223" } );
	HBInst.on( "error", function( err ){
		// Init errors 
	} )
```

**Options**

- **name** : *( `String` required )* The name of this current service group. E.g. "restservice"
- **identifier** : *( `String|Function` required )* The identifier of the current server. E.g. "http://api.myresthost.com:8080". If also possible to pass in a function that returnes the identifier.
- **intervalHeartbeat** : *( `Number` optional: default = `5` )* Min. interval time ( in seconds ) to send the heartbeat. If set `<= 0` the heartbeat will be deactivated.
- **heartbeatKey** : *( `String` optional: default = `HB` )* Redis key to write the heartbeat. This could be prefixed by `redisprefix`.
- **heartbeatExpire** : *( `Number` optional: default = `172800` 2 days )* Time in seconds until unused heartbeat will automatically removed. If set to `0` the key will never be removed
- **useRedisTime** : *( `Boolean` optional: default = `true` )* Use redis server time or us the own machine time
- **autostart** : *( `Boolean` optional: default = `true` )* Start the heartbeat on int. Otherwise you have to call the method `.start()` of your instance.
- **localtime** : *( `Boolean` optional: default = `false` )* Force the module to use the local time instead of a server independent local machine time
- **host** : *( `String` optional: default = `localhost` )* Redis host name
- **port** : *( `Number` optional: default = `6379` )* Redis port
- **options** : *( `Object` optional: default = `{}` )* Redis options
- **client** : *( `RedicClient` optional: default = `null` )* It also possible to pass in a already existing redis client instance. In this case the options `host`, `port` and `options` ar ignored.
- **redisprefix** : *( `String` optional: default = `{}` )* A general redis key prefix
- **diskCheckPath** : *( `String` optional: default = `/` or `c:` for win32 )* The disk path to ckeck for free space. If `null` or empty this check will be skipped. More details see [module diskusage](https://www.npmjs.com/package/diskusage)

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

#### `.quit()`

Stop the heartbeat anc close the internal connection to redis.  
After this this instance cannot be reused.

## Events

#### `started`

Emitted on start of the intervals

#### `beforeHeartbeat`

Emitted before heartbeat write.
With this event it's possible to change the heartbeat content in operation

**Arguments**

- **identifier** : *( `String` )* The current identifier

#### `connected`

Emitted on connection to redis

#### `disconnect`

Emitted on a disconnect of redis

#### `error`

An internal error occoured.

#### `redis:error`

Emitted on general redis error

**Arguments**

- **err** : *( `Error|String` )* The error details

## TODO

* add content tests

## Release History
|Version|Date|Description|
|:--:|:--:|:--|
|1.0.0|2018-05-07|removed metric, to use the heartbeat from node 10|
|0.3.1|2017-09-05|fixed compiled files|
|0.3.0|2017-08-11|be able to disable heartbeat with `intervalHeartbeat = 0`; updated deps; added coverage report|
|0.2.1|2016-05-19|optimized tests and event handling on quit|
|0.2.0|2016-05-18|usable from windows; added error event; updated dependencies; better tests|
|0.1.0|2016-01-07|Added metric `p_cpu` to measure the process cpu load. Added optional `d_avail` with the current free disk space. Trigger `beforeMetric` even if no `metricsKey` is defined. So you can grab the data without saving it to redis (eg. writing it to elasticsearch or a queue)|
|0.0.9|2015-12-15|updated dependencies to be used with node 4.2|
|0.0.8|2015-05-06|fixed time retrieval to use redis time and added a option `localtime` to force local time. By default it'll use the redis time if connected|
|0.0.7|2015-04-27|updated dependencies|
|0.0.6|2015-04-27|added option `metricExpire` to auto delete unused metrics|
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
|[**nsq-logger**](https://github.com/mpneuried/nsq-logger)|Nsq service to read messages from all topics listed within a list of nsqlookupd services.|
|[**nsq-topics**](https://github.com/mpneuried/nsq-topics)|Nsq helper to poll a nsqlookupd service for all it's topics and mirror it locally.|
|[**nsq-nodes**](https://github.com/mpneuried/nsq-nodes)|Nsq helper to poll a nsqlookupd service for all it's nodes and mirror it locally.|
|[**nsq-watch**](https://github.com/mpneuried/nsq-watch)|Watch one or many topics for unprocessed messages.|
|[**node-cache**](https://github.com/tcs-de/nodecache)|Simple and fast NodeJS internal caching. Node internal in memory cache like memcached.|
|[**redis-sessions**](https://github.com/smrchy/redis-sessions)|An advanced session store for NodeJS and Redis|
|[**obj-schema**](https://github.com/mpneuried/obj-schema)|Simple module to validate an object by a predefined schema|
|[**connect-redis-sessions**](https://github.com/mpneuried/connect-redis-sessions)|A connect or express middleware to simply use the [redis sessions](https://github.com/smrchy/redis-sessions). With [redis sessions](https://github.com/smrchy/redis-sessions) you can handle multiple sessions per user_id.|
|[**task-queue-worker**](https://github.com/smrchy/task-queue-worker)|A powerful tool for background processing of tasks that are run by making standard http requests.|
|[**soyer**](https://github.com/mpneuried/soyer)|Soyer is small lib for serverside use of Google Closure Templates with node.js.|
|[**grunt-soy-compile**](https://github.com/mpneuried/grunt-soy-compile)|Compile Goggle Closure Templates ( SOY ) templates including the handling of XLIFF language files.|
|[**backlunr**](https://github.com/mpneuried/backlunr)|A solution to bring Backbone Collections together with the browser fulltext search engine Lunr.js|

## The MIT License (MIT)

Copyright © 2013 Mathias Peter, http://www.tcs.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
