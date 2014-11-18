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
			# **heartbeat.name** *String* A identifier name
			name: null
			# **heartbeat.identifier** *String|Function* The heartbeat identifier content as string or function
			identifier: null

			# **heartbeat.intervalHeartbeat** *Number* Interval in seconds to write the alive key to redis
			intervalHeartbeat: 5
			# **heartbeat.heartbeatKey** *String* Key prefix for the alive heartbeat
			heartbeatKey: "HB"
			# **heartbeat.intervalMetrics** *Number* Interval in seconds to write server metrics to redis. If set `<= 0` no metrics will be written
			intervalMetrics: 60
			# **heartbeat.metricsKey** *String* Key prefix for the metrics key. If this is set to `null` no mertics will be written to redis
			metricsKey: "HB:METRICS"
			# **heartbeat.metricCount** *Number* Metrics will be saved as redis list. The list will be trimed to this length
			metricCount: 5000
			# **heartbeat.useRedisTime** *Boolean* Use redis server time or us the own time
			useRedisTime: true

	###	
	## constructor 
	###
	constructor: ( options )->
		super

		# wrap start method to only be active until the connection is established
		@start = @_waitUntil( @_start, "connected" )

		@start()
		@connect()

		return

	###
	## _start
	
	`heartbeat._start(  )`
	
	Start the heartbeat and metric send
	
	@api private
	###
	_start: =>

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
		return

	###
	## heartbeat
	
	`heartbeat.heartbeat( id, cb )`
	
	send a heartbeat and init the timeout for the next beat
	
	@api private
	###
	heartbeat: =>
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
	@param { Function } cb Callback function 
	
	@api private
	###
	_content: ( type, cb )=>
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

				_sData = JSON.stringify( _data )
				@emit "beforeMetric", _sData
				_statements.push [ "LPUSH", _key, _sData ]
				_statements.push [ "LTRIM", _key, 0, @config.metricCount - 1 ]
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
		if not @config.useRedisTime
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