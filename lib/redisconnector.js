(function() {
  var RedisConnector, redis,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  redis = require("redis");

  RedisConnector = (function(_super) {
    __extends(RedisConnector, _super);

    RedisConnector.prototype.defaults = function() {
      return this.extend(RedisConnector.__super__.defaults.apply(this, arguments), {
        host: "localhost",
        port: 6379,
        options: {},
        client: null,
        redisprefix: ""
      });
    };


    /*	
    	 *# constructor
     */

    function RedisConnector() {
      this._getKey = __bind(this._getKey, this);
      this.connect = __bind(this.connect, this);
      this.defaults = __bind(this.defaults, this);
      RedisConnector.__super__.constructor.apply(this, arguments);
      this.connected = false;
      return;
    }


    /*
    	 *# connect
    	
    	`redisconnector.connect()`
    	
    	Connect to redis and add the renerated client th `@redis`
    	
    	@return { RedisClient } Return The Redis Client. Eventually not conneted yet. 
    	
    	@api public
     */

    RedisConnector.prototype.connect = function() {
      var _err, _ref, _ref1;
      if (((_ref = this.config.client) != null ? (_ref1 = _ref.constructor) != null ? _ref1.name : void 0 : void 0) === "RedisClient") {
        this.redis = this.config.client;
      } else {
        try {
          redis = require("redis");
        } catch (_error) {
          _err = _error;
          this.error("you have to load redis via `npm install redis hiredis`");
          return;
        }
        this.redis = redis.createClient(this.config.port || 6379, this.config.host || "127.0.0.1", this.config.options || {});
      }
      this.connected = this.redis.connected || false;
      this.redis.on("connect", (function(_this) {
        return function() {
          _this.connected = true;
          _this.debug("connected");
          _this.emit("connected");
        };
      })(this));
      this.redis.on("error", (function(_this) {
        return function(err) {
          if (err.message.indexOf("ECONNREFUSED")) {
            _this.connected = false;
            _this.emit("disconnect");
          } else {
            _this.error("Redis ERROR", err);
            _this.emit("redis:error", err);
          }
        };
      })(this));
      return this.client;
    };


    /*
    	 *# _getKey
    	
    	`redisconnector._getKey( id, name )`
    	
    	Samll helper to redisprefix and get a redis key. 
    	
    	@param { String } id The key 
    	@param { String } name the class name
    	
    	@return { String } Return The generated key 
    	
    	@api public
     */

    RedisConnector.prototype._getKey = function(id, name) {
      var _key;
      _key = this.config.redisprefix || "";
      if (name != null ? name.length : void 0) {
        if (_key.length) {
          _key += ":";
        }
        _key += name;
      }
      if (id != null ? id.length : void 0) {
        if (_key.length) {
          _key += ":";
        }
        _key += id;
      }
      this.debug("_getKey: id:`" + id + "` name:`" + name + "` = `" + _key + "`");
      return _key;
    };

    return RedisConnector;

  })(require("mpbasic")());

  module.exports = RedisConnector;

}).call(this);
