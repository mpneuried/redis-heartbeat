# #Heartbeat
# ### extends [RedisConnector](./redisconnector.coffee.html)
#
# ### Exports: *Class*
#
# Main Module to init the heartbeat to redis
#

# ### Events
#
# * **started**: 	ted on start of heartbeat.
# * **beforeHeartbeat**: 	ted before heartbeat. With this event youre able to modify the content of the heartbeat identifier in operation.

# **node modules**
os = require( "os" )

# **npm modules**
_isFunction = require( "lodash/isFunction" )
_result = require( "lodash/result" )

# **internal modules**
# [Redisconnector](./redisconnector.coffee.html)
Redisconnector = require( "./redisconnector" )

class Heartbeat extends Redisconnector

	# ## defaults
	defaults: =>
		@extend super( arguments... ),
			# **name** *String* A identifier name
			name: null
			# **identifier** *String|Function* The heartbeat identifier content as string or function
			identifier: null

			# **intervalHeartbeat** *Number* Interval in seconds to write the alive key to redis
			intervalHeartbeat: 5
			# **heartbeatKey** *String* Key prefix for the alive heartbeat
			heartbeatKey: "HB"
			# **heartbeatExpire** *Number* Time in seconds until unused heartbeat will automatically removed. If set to `0` the key will never be removed
			heartbeatExpire: 60*60*24*2
			# **useRedisTime** *Boolean* Use redis server time or us the own time
			useRedisTime: true
			# **autostart** *Boolean* Start the heartbeat on init
			autostart: true
			# **localtime** *Boolean* Force the module to use the local time instead of a server independent local machine time
			localtime: false


	###
	## constructor
	###
	constructor: ( options )->
		super( arguments... )

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

	Start the heartbeat send

	@return { Boolean } If it has been started. Could be `false` if the heartbeat has been already active

	@api private
	###
	_start: =>
		# don't start a second tine
		return false if @active
		@active = true
		
		if not @config.name?.length
			@emit "error", @_handleError( true, "ENONAME" )
			return

		if not _isFunction( @config.identifier ) and not @config.identifier?.length
			@emit "error", @_handleError( true, "ENOIDENTIFIER" )
			return

		# generate send functions
		if @config.intervalHeartbeat > 0
			@debug "_start: heartbeat"
			@_sendHeartbeat = @_send( "heartbeat", @heartbeat )

		if not @_sendHeartbeat?
			@active = false
			@debug "module disabled"
			return false

		# send the data for the fist time
		@_sendHeartbeat() if @_sendHeartbeat?

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
		return

	###
	## quit

	`heartbeat.quit()`

	Stop sending a heartbeat, clear all active timeouts and close the connection to redis.
	After this this instance cannot be reused.

	@api public
	###
	quit: =>
		@stop()
		@removeAllListeners()
		@redis.quit()
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
		# silent stop if function not exists or a invalid intervall has been defined
		if not @_sendHeartbeat? or @config.intervalHeartbeat <= 0
			@debug "heartbeat: deactivated"
			return
		
		clearTimeout( @_timerHeartbeat ) if @_timerHeartbeat
		@_timerHeartbeat = setTimeout( @_sendHeartbeat, @config.intervalHeartbeat * 1000 )
		return

	###
	## _send

	`heartbeat._send( [cb] )`

	Write the heartbeat to redis

	@param { String } type The type to send. *( enum: "heartbeat" )*
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
				
				if not rStmnts?.length
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

	@param { String } type The type to send. *( enum: "heartbeat" )*
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

			if type is "heartbeat"
				_statements = []
				_key = @_getKey( @config.name, @config.heartbeatKey )
				_iden = _result( @config, "identifier" )
				@emit "beforeHeartbeat", _iden
				_statements.push [ "ZADD", _key, ms, _iden ]
				if @config.heartbeatExpire > 0
					_statements.push [ "EXPIRE", _key, @config.heartbeatExpire ]
				cb( null, _statements )
				return

			_err = @_handleError( true, "EINVALIDTYPE" )
			@emit( "error", _err )
			cb( _err )
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
		if @config.localtime or not @connected
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
		@redis.time ( err, time )->
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
		return @extend {}, super( arguments... ),
			"ENONAME": [ 500, "No `name` defined. The heartbeat will not be send" ]
			"ENOIDENTIFIER": [ 500, "No `identifier` defined. The heartbeat will not be send" ]
			"EINVALIDTYPE": [ 500, "Invalid type. Only `heartbeat` is allowed" ]

#export this class
module.exports = Heartbeat
