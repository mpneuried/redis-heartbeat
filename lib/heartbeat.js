(function() {
  var Heartbeat, Redisconnector, lodash, os,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  os = require("os");

  lodash = require("lodash");

  Redisconnector = require("./redisconnector");

  Heartbeat = (function(_super) {
    __extends(Heartbeat, _super);

    Heartbeat.prototype.defaults = function() {
      return this.extend(Heartbeat.__super__.defaults.apply(this, arguments), {
        name: null,
        identifier: null,
        intervalHeartbeat: 5,
        heartbeatKey: "HB",
        intervalMetrics: 60,
        metricsKey: "HB:METRICS",
        metricCount: 5000,
        useRedisTime: true,
        autostart: true
      });
    };


    /*	
    	 *# constructor
     */

    function Heartbeat(options) {
      this.ERRORS = __bind(this.ERRORS, this);
      this._getRedisTime = __bind(this._getRedisTime, this);
      this._getTime = __bind(this._getTime, this);
      this._content = __bind(this._content, this);
      this._send = __bind(this._send, this);
      this.metrics = __bind(this.metrics, this);
      this.heartbeat = __bind(this.heartbeat, this);
      this.isActive = __bind(this.isActive, this);
      this.stop = __bind(this.stop, this);
      this._start = __bind(this._start, this);
      this.defaults = __bind(this.defaults, this);
      Heartbeat.__super__.constructor.apply(this, arguments);
      this.start = this._waitUntil(this._start, "connected");
      this.active = false;
      if (this.config.autostart) {
        this.start();
      }
      this.connect();
      return;
    }


    /*
    	 *# _start
    	
    	`heartbeat._start()`
    	
    	Start the heartbeat and metric send
    
    	@return { Boolean } If it has been started. Could be `false` if the heartbeat has been already active
    	
    	@api private
     */

    Heartbeat.prototype._start = function() {
      var _ref, _ref1;
      if (this.active) {
        return false;
      }
      this.active = true;
      if (!((_ref = this.config.name) != null ? _ref.length : void 0)) {
        this._handleError(false, "ENONAME");
        return;
      }
      if (!lodash.isFunction(this.config.identifier) && !((_ref1 = this.config.identifier) != null ? _ref1.length : void 0)) {
        this._handleError(false, "ENOIDENTIFIER");
        return;
      }
      this._sendHeartbeat = this._send("heartbeat", this.heartbeat);
      if (this.config.metricsKey && this.config.intervalMetrics > 0) {
        this.debug("_start: metrics deactivated");
        this._sendMetrics = this._send("metric", this.metrics);
      }
      this._sendHeartbeat();
      if (this._sendMetrics != null) {
        this._sendMetrics();
      }
      this.emit("started");
      return true;
    };


    /*
    	 *# stop
    	
    	`heartbeat.stop()`
    	
    	Stop sending a heartbeat and clear all active timeouts
    	
    	@api public
     */

    Heartbeat.prototype.stop = function() {
      this.active = false;
      if (this._timerHeartbeat) {
        clearTimeout(this._timerHeartbeat);
      }
      if (this._timerMetrics) {
        clearTimeout(this._timerMetrics);
      }
    };


    /*
    	 *# isActive
    	
    	`heartbeat.isActive()`
    	
    	Ask if the heartbeat is currently active
    	
    	@return { Boolean } Is heartbeat active 
    	
    	@api public
     */

    Heartbeat.prototype.isActive = function() {
      return this.active;
    };


    /*
    	 *# heartbeat
    	
    	`heartbeat.heartbeat( id, cb )`
    	
    	send a heartbeat and init the timeout for the next beat
    	
    	@api private
     */

    Heartbeat.prototype.heartbeat = function() {
      if (!this.active) {
        return;
      }
      if (this._timerHeartbeat) {
        clearTimeout(this._timerHeartbeat);
      }
      this._timerHeartbeat = setTimeout(this._sendHeartbeat, this.config.intervalHeartbeat * 1000);
    };


    /*
    	 *# heartbeat
    	
    	`heartbeat.heartbeat( id, cb )`
    	
    	send a heartbeat and init the timeout for the next beat
    	
    	@api private
     */

    Heartbeat.prototype.metrics = function() {
      if (!this.active) {
        return;
      }
      if ((this._sendMetrics == null) || this.config.intervalMetrics <= 0) {
        this.debug("metrics: metrics deactivated");
        return;
      }
      if (this._timerMetrics) {
        clearTimeout(this._timerMetrics);
      }
      this._timerMetrics = setTimeout(this._sendMetrics, this.config.intervalMetrics * 1000);
    };


    /*
    	 *# _send
    	
    	`heartbeat._send( [cb] )`
    	
    	Write the heartbeat to redis
    	
    	@param { String } type The type to send. *( enum: "heartbeat", "metric" )*
    	@param { Function } next Function called on finish or error 
    	
    	@return { Self } itself
    	
    	@api private
     */

    Heartbeat.prototype._send = function(type, next) {
      this.debug("generate send function", type, next);
      return (function(_this) {
        return function() {
          _this._content(type, function(err, rStmnts) {
            if (err) {
              _this.error("_send: get content", err);
              next();
              return;
            }
            _this.debug("send `" + type + "`", rStmnts);
            _this.redis.multi(rStmnts).exec(function(err, result) {
              if (err) {
                _this.error("_send: write redis", err);
              } else {
                _this.debug("_send: write redis", result);
              }
              next();
            });
          });
        };
      })(this);
    };


    /*
    	 *# _content
    	
    	`heartbeat._content( cb )`
    	
    	Generate the heartbeat content
    
    	@param { String } type The type to send. *( enum: "heartbeat", "metric" )*
    	@param { Object } [options] Optional options. 
    	@param { Function } cb Callback function 
    	
    	@api private
     */

    Heartbeat.prototype._content = function() {
      var args, cb, options, type, _i;
      args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), cb = arguments[_i++];
      type = args[0], options = args[1];
      this._getTime((function(_this) {
        return function(err, ms) {
          var ald15m, ald1m, ald5m, _data, _iden, _key, _ref, _sData, _statements;
          if (err) {
            cb(err);
            return;
          }
          _statements = [];
          _key = _this._getKey(_this.config.name, _this.config.heartbeatKey);
          _iden = lodash.result(_this.config, "identifier");
          if (type === "heartbeat") {
            _this.emit("beforeHeartbeat", _iden);
            _statements.push(["ZADD", _key, ms, _iden]);
            cb(null, _statements);
            return;
          }
          if (type === "metric") {
            _key = _this._getKey(_iden, _this.config.metricsKey);
            _ref = os.loadavg(), ald1m = _ref[0], ald5m = _ref[1], ald15m = _ref[2];
            _data = {
              t: ms,
              g_cpu: parseFloat(ald1m.toFixed(2)),
              g_mem: parseFloat((os.freemem() / os.totalmem() * 100).toFixed(2)),
              g_memtotal: os.totalmem(),
              p_mem: process.memoryUsage(),
              p_id: process.pid,
              p_uptime: process.uptime()
            };
            _this.emit("beforeMetric", _data);
            _sData = JSON.stringify(_data);
            _statements.push(["LPUSH", _key, _sData]);
            _statements.push(["ZADD", _this._getKey(null, _this.config.metricsKey), ms, _key]);
            _statements.push(["LTRIM", _key, 0, _this.config.metricCount - 1]);
            cb(null, _statements);
            return;
          }
          _this._handleError(cb, "EINVALIDTYPE");
        };
      })(this));
    };


    /*
    	 *# _getTime
    	
    	`heartbeat._getTime( cb )`
    	
    	Get the current time in *ms* from local machine or from redis
    	
    	@param { Function } cb Callback function 
    	
    	@api private
     */

    Heartbeat.prototype._getTime = function(cb) {
      if (!this.config.autostart) {
        cb(null, Date.now());
        return;
      }
      this._getRedisTime(cb);
    };


    /*
    	 *# _getRedisTime
    	
    	`heartbeat._getRedisTime( cb )`
    	
    	Get the current redis time in *ms*
    	
    	@param { Function } cb Callback function 
    	
    	@api private
     */

    Heartbeat.prototype._getRedisTime = function(cb) {
      this.redis.time((function(_this) {
        return function(err, time) {
          var ms, ns, s;
          if (err) {
            cb(err);
            return;
          }
          s = time[0], ns = time[1];
          ns = ("000000" + ns).slice(0, 6);
          ms = Math.round(parseInt(s + ns, 10) / 1000);
          cb(null, ms);
        };
      })(this));
    };


    /*
    	 *# ERRORS
    	
    	`apibase.ERRORS()`
    	
    	Error detail mappings
    	
    	@return { Object } Return A Object of error details. Format: `"ERRORCODE":[ statusCode, "Error detail" ]` 
    	
    	@api private
     */

    Heartbeat.prototype.ERRORS = function() {
      return this.extend({}, Heartbeat.__super__.ERRORS.apply(this, arguments), {
        "ENONAME": [500, "No `name` defined. The heartbeat will not be send"],
        "ENOIDENTIFIER": [500, "No `identifier` defined. The heartbeat will not be send"],
        "EINVALIDTYPE": [500, "Invalid type. Only `heartbeat` and `metrics` are allowed"]
      });
    };

    return Heartbeat;

  })(Redisconnector);

  module.exports = Heartbeat;

}).call(this);
