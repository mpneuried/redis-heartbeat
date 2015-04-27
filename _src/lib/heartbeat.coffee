# # Heartbeat
# ### extends [RedisConnector](./redisconnector.coffee.html)
#
# ### Exports: *Class*
#
# Main Module to init the heartbeat to redis
# 

# ### Events
# 
# * **started**: emitted on start of heartbeat.
# * **beforeHeartbeat**: emitted before heartbeat. With this event youre able to modify the content of the heartbeat identifier in operation.
# * **beforeMetric**: emitted before heartbeat. With this event youre able to modify the content of the metric package.

# **node modules**
os = require( "os" )

# **npm modules**
lodash = require( "lodash" )

# **internal modules**
# [Redisconnector](./redisconnector.coffee.html)
Redisconnector = require( "./redisconnector" ) 

class Heartbeat extends Redisconnector

	# ## defaults
	defaults: =>
		@extend super, 
			# **name** *String* A identifier name
			name: null
			# **identifier** *String|Function* The heartbeat identifier content as string or function
			identifier: null

			# **intervalHeartbeat** *Number* Interval in seconds to write the alive key to redis
			intervalHeartbeat: 5
			# **heartbeatKey** *String* Key prefix for the alive heartbeat
			heartbeatKey: "HB"
			# **intervalMetrics** *Number* Interval in seconds to write server metrics to redis. If set `<= 0` no metrics will be written
			intervalMetrics: 60
			# **metricsKey** *String* Key prefix for the metrics key. If this is set to `null` no mertics will be written to redis
			metricsKey: "HB:METRICS"
			# **metricCount** *Number* Metrics will be saved as redis list. The list will be trimed to this length
			metricCount: 5000
			# **metricExpire** *Number* Time in seconds until unused metrict will automatically removed. If set to `0` the key will never be removed
			metricExpire: 60*60*24*2
			# **useRedisTime** *Boolean* Use redis server time or us the own time
			useRedisTime: true
			# **autostart** *Boolean* Start the heartbeat on init
			autostart: true

	###	
	## constructor 
	###
	constructor: ( options )->
		super

		# wrap start method to only be active until the connection is established
		# This will be the public method
		@start = @_waitUntil( @_start, "connected" )

		@active = false
		@start() if @config.autostart
		@connect()

		return

	###
	## _start
	
	`heartbeat._start()`
	
	Start the heartbeat and metric send

	@return { Boolean } If it has been started. Could be `false` if the heartbeat has been already active
	
	@api private
	###
	_start: =>
		# don't start a second tine
		return false if @active
		
		@active = true
		if not @config.name?.length
			@_handleError( false, "ENONAME" )
			return

		if not lodash.isFunction( @config.identifier ) and not @config.identifier?.length
			@_handleError( false, "ENOIDENTIFIER" )
			return

		# generate send functions
		@_sendHeartbeat = @_send( "heartbeat", @heartbeat )
		if @config.metricsKey and @config.intervalMetrics > 0
			@debug "_start: metrics deactivated"
			@_sendMetrics = @_send( "metric", @metrics )

		# send the data for the fist time
		@_sendHeartbeat()
		@_sendMetrics() if @_sendMetrics?

		@emit "started"
		return true

	###
	## stop
	
	`heartbeat.stop()`
	
	Stop sending a heartbeat and clear all active timeouts
	
	@api public
	###
	stop: =>
		@active = false
		clearTimeout( @_timerHeartbeat ) if @_timerHeartbeat
		clearTimeout( @_timerMetrics ) if @_timerMetrics
		return

	###
	## isActive
	
	`heartbeat.isActive()`
	
	Ask if the heartbeat is currently active
	
	@return { Boolean } Is heartbeat active 
	
	@api public
	###
	isActive: =>
		return @active

	###
	## heartbeat
	
	`heartbeat.heartbeat( id, cb )`
	
	send a heartbeat and init the timeout for the next beat
	
	@api private
	###
	heartbeat: =>
		return if not @active
		clearTimeout( @_timerHeartbeat ) if @_timerHeartbeat
		@_timerHeartbeat = setTimeout( @_sendHeartbeat, @config.intervalHeartbeat * 1000 )
		return

	###
	## heartbeat
	
	`heartbeat.heartbeat( id, cb )`
	
	send a heartbeat and init the timeout for the next beat
	
	@api private
	###
	metrics: =>
		return if not @active
		# silent stop if function not exists or a invalid intervall has been defined
		if not @_sendMetrics? or @config.intervalMetrics <= 0
			@debug "metrics: metrics deactivated"
			return

		clearTimeout( @_timerMetrics ) if @_timerMetrics
		@_timerMetrics = setTimeout( @_sendMetrics, @config.intervalMetrics * 1000 )
		return

	###
	## _send
	
	`heartbeat._send( [cb] )`
	
	Write the heartbeat to redis
	
	@param { String } type The type to send. *( enum: "heartbeat", "metric" )*
	@param { Function } next Function called on finish or error 
	
	@return { Self } itself
	
	@api private
	###
	_send: ( type, next )=>
		@debug "generate send function", type, next
		return =>

			@_content type, ( err, rStmnts )=>
				if err
					@error( "_send: get content", err )
					# start next heartbeat
					next()
					return

				@debug "send `#{type}`", rStmnts
				@redis.multi( rStmnts ).exec ( err, result )=>
					if err
						@error( "_send: write redis", err )
					else
						@debug "_send: write redis", result
					
					# start next heartbeat
					next()
					return
				return
			return
		return

	###
	## _content
	
	`heartbeat._content( cb )`
	
	Generate the heartbeat content

	@param { String } type The type to send. *( enum: "heartbeat", "metric" )*
	@param { Object } [options] Optional options. 
	@param { Function } cb Callback function 
	
	@api private
	###
	_content: ( args..., cb )=>
		[ type, options ] = args

		@_getTime ( err, ms )=>
			if err
				cb( err )
				return

			_statements = []
			_key = @_getKey( @config.name, @config.heartbeatKey )
			_iden = lodash.result( @config, "identifier" )
			if type is "heartbeat"
				@emit "beforeHeartbeat", _iden
				_statements.push [ "ZADD", _key, ms, _iden ]
				cb( null, _statements )
				return

			if type is "metric"
				_key = @_getKey( _iden, @config.metricsKey )

				# read the avarge load
				[ ald1m, ald5m, ald15m ] = os.loadavg()
				_data = 
					t: ms
					g_cpu: parseFloat( ald1m.toFixed(2) )
					g_mem: parseFloat( ( os.freemem() / os.totalmem() * 100).toFixed(2) )
					g_memtotal: os.totalmem()
					p_mem: process.memoryUsage()
					p_id: process.pid
					p_uptime: process.uptime()

				@emit "beforeMetric", _data
				_sData = JSON.stringify( _data )
				_statements.push [ "LPUSH", _key, _sData ]
				_statements.push [ "ZADD", @_getKey( null, @config.metricsKey ), ms, _key ]
				_statements.push [ "LTRIM", _key, 0, @config.metricCount - 1 ]
				_statements.push [ "LTRIM", _key, 0, @config.metricCount - 1 ]
				
				if @config.metricExpire > 0
					_statements.push [ "EXPIRE", _key, @config.metricExpire ]

				cb( null, _statements )
				return

			@_handleError( cb, "EINVALIDTYPE" )
			return
		return

	###
	## _getTime
	
	`heartbeat._getTime( cb )`
	
	Get the current time in *ms* from local machine or from redis
	
	@param { Function } cb Callback function 
	
	@api private
	###
	_getTime: ( cb )=>
		if not @config.autostart
			cb( null, Date.now() )
			return

		@_getRedisTime( cb )
		return

	###
	## _getRedisTime
	
	`heartbeat._getRedisTime( cb )`
	
	Get the current redis time in *ms*
	
	@param { Function } cb Callback function 
	
	@api private
	###
	_getRedisTime: ( cb )=>
		@redis.time ( err, time )=>
			if err
				cb( err )
				return		
			
			# calc miliseconds from redis seconds and nano-seconds
			[ s, ns ] = time
			# pad the nanoseconds
			ns = ( "000000" + ns )[0..5]
			ms = Math.round( (parseInt( s + ns , 10 ) / 1000 ) )

			cb( null, ms ) 
			return
		return


	###
	## ERRORS
	
	`apibase.ERRORS()`
	
	Error detail mappings
	
	@return { Object } Return A Object of error details. Format: `"ERRORCODE":[ statusCode, "Error detail" ]` 
	
	@api private
	###
	ERRORS: =>
		return @extend {}, super, 
			"ENONAME": [ 500, "No `name` defined. The heartbeat will not be send" ]
			"ENOIDENTIFIER": [ 500, "No `identifier` defined. The heartbeat will not be send" ]
			"EINVALIDTYPE": [ 500, "Invalid type. Only `heartbeat` and `metrics` are allowed" ]

#export this class
module.exports = Heartbeat